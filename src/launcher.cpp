// nrwide_launcher.exe - starts nightreign.exe directly (no Easy Anti-Cheat, offline), injects nrwide.dll
// before the game's first instruction runs, then resumes it.
// Works with ELDEN RING NIGHTREIGN. Not affiliated with FromSoftware or Bandai Namco.
#include <windows.h>
#include <tlhelp32.h>
#include <shellapi.h>
#include <string>

static const wchar_t* kTitle = L"nrwide launcher";
static std::wstring g_logPath;

static void LogLine(const std::wstring& msg)
{
    if (g_logPath.empty()) return;
    HANDLE f = CreateFileW(g_logPath.c_str(), FILE_APPEND_DATA, FILE_SHARE_READ, nullptr, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
    if (f == INVALID_HANDLE_VALUE) return;
    int n = WideCharToMultiByte(CP_UTF8, 0, msg.c_str(), -1, nullptr, 0, nullptr, nullptr);
    std::string s(n > 0 ? n - 1 : 0, '\0');
    if (n > 1) WideCharToMultiByte(CP_UTF8, 0, msg.c_str(), -1, s.data(), n, nullptr, nullptr);
    s += "\r\n";
    DWORD w; WriteFile(f, s.data(), (DWORD)s.size(), &w, nullptr); CloseHandle(f);
}

static void Fail(const std::wstring& msg)
{
    LogLine(L"ERROR: " + msg);
    MessageBoxW(nullptr, msg.c_str(), kTitle, MB_ICONERROR);
    ExitProcess(1);
}

static bool FileExists(const std::wstring& p)
{
    DWORD a = GetFileAttributesW(p.c_str());
    return a != INVALID_FILE_ATTRIBUTES && !(a & FILE_ATTRIBUTE_DIRECTORY);
}

static bool GameRunning()
{
    HANDLE snap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if (snap == INVALID_HANDLE_VALUE) return false;
    PROCESSENTRY32W pe = { sizeof(pe) };
    bool found = false;
    for (BOOL ok = Process32FirstW(snap, &pe); ok; ok = Process32NextW(snap, &pe))
        if (!_wcsicmp(pe.szExeFile, L"nightreign.exe") || !_wcsicmp(pe.szExeFile, L"start_protected_game.exe")) { found = true; break; }
    CloseHandle(snap);
    return found;
}

// Loads `dll` into `proc` via a remote LoadLibraryW thread. Returns an error message, or "" on success.
static std::wstring Inject(HANDLE proc, const std::wstring& dll)
{
    size_t bytes = (dll.size() + 1) * sizeof(wchar_t);
    void* remote = VirtualAllocEx(proc, nullptr, bytes, MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE);
    if (!remote || !WriteProcessMemory(proc, remote, dll.c_str(), bytes, nullptr))
        return L"Could not write into the game process.";
    auto loadLib = (LPTHREAD_START_ROUTINE)GetProcAddress(GetModuleHandleW(L"kernel32.dll"), "LoadLibraryW");
    HANDLE t = CreateRemoteThread(proc, nullptr, 0, loadLib, remote, 0, nullptr);
    if (!t) return L"CreateRemoteThread failed (error " + std::to_wstring(GetLastError()) + L")";
    if (WaitForSingleObject(t, 30000) != WAIT_OBJECT_0) { CloseHandle(t); return L"Timed out loading nrwide.dll."; }
    DWORD code = 0; GetExitCodeThread(t, &code); CloseHandle(t);
    VirtualFreeEx(proc, remote, 0, MEM_RELEASE);
    if (!code) return L"nrwide.dll failed to load into the game.\n(Windows Smart App Control or antivirus can block unsigned DLLs.)";
    return L"";
}

// Finds a running nightreign.exe whose full path is `exe` (never matches by name alone).
static DWORD FindGame(const std::wstring& exe)
{
    HANDLE snap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if (snap == INVALID_HANDLE_VALUE) return 0;
    PROCESSENTRY32W pe = { sizeof(pe) };
    DWORD found = 0;
    for (BOOL ok = Process32FirstW(snap, &pe); ok && !found; ok = Process32NextW(snap, &pe)) {
        if (_wcsicmp(pe.szExeFile, L"nightreign.exe")) continue;
        HANDLE h = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, pe.th32ProcessID);
        if (!h) continue;
        wchar_t path[MAX_PATH]; DWORD n = MAX_PATH;
        if (QueryFullProcessImageNameW(h, 0, path, &n) && !_wcsicmp(path, exe.c_str())) found = pe.th32ProcessID;
        CloseHandle(h);
    }
    CloseHandle(snap);
    return found;
}

static bool HasModule(DWORD pid, const wchar_t* name)
{
    HANDLE snap = CreateToolhelp32Snapshot(TH32CS_SNAPMODULE, pid);
    if (snap == INVALID_HANDLE_VALUE) return false; // process still initialising
    MODULEENTRY32W me = { sizeof(me) };
    bool found = false;
    for (BOOL ok = Module32FirstW(snap, &me); ok && !found; ok = Module32NextW(snap, &me))
        if (!_wcsicmp(me.szModule, name)) found = true;
    CloseHandle(snap);
    return found;
}

int WINAPI wWinMain(HINSTANCE, HINSTANCE, LPWSTR, int)
{
    wchar_t self[MAX_PATH]; GetModuleFileNameW(nullptr, self, MAX_PATH);
    std::wstring dir(self); dir = dir.substr(0, dir.find_last_of(L'\\'));
    std::wstring ini = dir + L"\\nrwide.ini";
    std::wstring dll = dir + L"\\nrwide.dll";
    g_logPath = dir + L"\\nrwide_launcher.log";
    DeleteFileW(g_logPath.c_str());

    wchar_t gameDir[MAX_PATH] = {};
    GetPrivateProfileStringW(L"launcher", L"game_dir",
        L"C:\\Program Files (x86)\\Steam\\steamapps\\common\\ELDEN RING NIGHTREIGN\\Game", gameDir, MAX_PATH, ini.c_str());
    std::wstring gdir(gameDir);
    while (!gdir.empty() && (gdir.back() == L'\\' || gdir.back() == L'/')) gdir.pop_back();
    std::wstring exe = gdir + L"\\nightreign.exe";

    if (!FileExists(dll)) Fail(L"nrwide.dll not found next to the launcher:\n" + dll);
    if (!FileExists(exe)) Fail(L"nightreign.exe not found. Set game_dir in nrwide.ini:\n" + exe);
    if (GameRunning()) Fail(L"The game is already running. Close it first.");

    // steam_appid.txt lets nightreign.exe start without being relaunched through Steam (and EAC).
    std::wstring appid = gdir + L"\\steam_appid.txt";
    if (!FileExists(appid)) {
        HANDLE f = CreateFileW(appid.c_str(), GENERIC_WRITE, 0, nullptr, CREATE_NEW, FILE_ATTRIBUTE_NORMAL, nullptr);
        if (f == INVALID_HANDLE_VALUE) Fail(L"Could not create " + appid + L"\nTry running the launcher as administrator once.");
        DWORD w; WriteFile(f, "2622380", 7, &w, nullptr); CloseHandle(f);
    }

    wchar_t modeBuf[32] = {}, scExe[MAX_PATH] = {}, waitMod[MAX_PATH] = {};
    GetPrivateProfileStringW(L"launcher", L"mode", L"direct", modeBuf, 32, ini.c_str());
    GetPrivateProfileStringW(L"launcher", L"seamless_launcher", L"nrsc_launcher.exe", scExe, MAX_PATH, ini.c_str());
    GetPrivateProfileStringW(L"launcher", L"seamless_module", L"nrsc.dll", waitMod, MAX_PATH, ini.c_str());
    // "--mode direct|seamless" on the command line overrides the ini (used by the desktop shortcuts).
    int argc = 0;
    if (LPWSTR* argv = CommandLineToArgvW(GetCommandLineW(), &argc)) {
        for (int i = 1; i + 1 < argc; ++i)
            if (!_wcsicmp(argv[i], L"--mode")) wcsncpy_s(modeBuf, argv[i + 1], _TRUNCATE);
        LocalFree(argv);
    }
    const bool seamless = !_wcsicmp(modeBuf, L"seamless");
    LogLine(std::wstring(L"mode: ") + (seamless ? L"seamless" : L"direct"));

    if (!seamless) {
        // Direct: start the game suspended, inject before its first instruction, resume.
        STARTUPINFOW si = { sizeof(si) };
        PROCESS_INFORMATION pi = {};
        std::wstring cmd = L"\"" + exe + L"\"";
        if (!CreateProcessW(exe.c_str(), cmd.data(), nullptr, nullptr, FALSE, CREATE_SUSPENDED, nullptr, gdir.c_str(), &si, &pi))
            Fail(L"CreateProcess failed (error " + std::to_wstring(GetLastError()) + L")");
        std::wstring err = Inject(pi.hProcess, dll);
        if (!err.empty()) { TerminateProcess(pi.hProcess, 1); Fail(err); }
        LogLine(L"direct: injected " + dll + L" into pid " + std::to_wstring(pi.dwProcessId) + L", resuming");
        ResumeThread(pi.hThread);
        CloseHandle(pi.hThread);
        CloseHandle(pi.hProcess);
        return 0;
    }

    // Seamless: Seamless Co-op's own launcher starts the game and loads its DLL first.
    // We wait for that DLL to appear in the game, then inject nrwide.dll (still well before the swapchain exists).
    std::wstring sc = gdir + L"\\" + scExe;
    if (!FileExists(sc)) Fail(L"Seamless Co-op launcher not found:\n" + sc + L"\n\nInstall Seamless Co-op into the game's Game folder, or set mode=direct in nrwide.ini.");
    STARTUPINFOW si = { sizeof(si) };
    PROCESS_INFORMATION pi = {};
    std::wstring cmd = L"\"" + sc + L"\"";
    if (!CreateProcessW(sc.c_str(), cmd.data(), nullptr, nullptr, FALSE, 0, nullptr, gdir.c_str(), &si, &pi))
        Fail(L"Could not start " + sc + L" (error " + std::to_wstring(GetLastError()) + L")");
    CloseHandle(pi.hThread); CloseHandle(pi.hProcess);
    LogLine(L"seamless: started " + sc);

    DWORD pid = 0;
    for (DWORD t0 = GetTickCount(); !pid && GetTickCount() - t0 < 60000; ) {
        pid = FindGame(exe);
        if (!pid) Sleep(5);
    }
    if (!pid) Fail(L"nightreign.exe did not start within 60 s of the Seamless Co-op launcher.");
    HANDLE proc = OpenProcess(PROCESS_CREATE_THREAD | PROCESS_QUERY_INFORMATION | PROCESS_VM_OPERATION | PROCESS_VM_WRITE | PROCESS_VM_READ | SYNCHRONIZE, FALSE, pid);
    if (!proc) Fail(L"Could not open the game process (error " + std::to_wstring(GetLastError()) + L")");
    LogLine(L"seamless: found game pid " + std::to_wstring(pid));

    bool haveMod = false;
    for (DWORD t0 = GetTickCount(); GetTickCount() - t0 < 15000; Sleep(5)) {
        if (WaitForSingleObject(proc, 0) == WAIT_OBJECT_0) Fail(L"The game closed during startup.");
        if (HasModule(pid, waitMod)) { haveMod = true; break; }
    }
    LogLine(haveMod ? std::wstring(L"seamless: ") + waitMod + L" is loaded"
                    : std::wstring(L"seamless: ") + waitMod + L" not seen after 15 s, injecting anyway");

    std::wstring err = Inject(proc, dll);
    CloseHandle(proc);
    if (!err.empty()) Fail(err);
    LogLine(L"seamless: injected " + dll);
    return 0;
}
