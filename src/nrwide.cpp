// nrwide.dll - ultrawide + high-FPS patch, injected by nrwide_launcher.exe.
// Works with ELDEN RING NIGHTREIGN (offline / EAC off only). Not affiliated with FromSoftware or Bandai Namco.
//
// Patches (byte patterns, verified unique on nightreign.exe 1.3.3.0):
//   1. ultrawide : aspect-ratio clamp in the swapchain/viewport setup. The second "je" that skips the
//                  16:9 correction becomes "jmp", so the full 21:9 (or 32:9) image is shown, no black bars.
//   2. fps       : frame-time target "mov dword [rbx+20], 0x3C888889" (1/60 s) -> 1/limit s.
//   3. hz        : fullscreen mode forced to 60 Hz ("mov [rbp-11],3C; mov [rbp-D],1") -> refresh 0, flag 0.
#include <windows.h>
#include <cstdio>
#include <cstdarg>
#include <cstdint>
#include <cstring>
#include <string>
#include <vector>

static wchar_t g_dir[MAX_PATH];
static FILE* g_log = nullptr;

static void Log(const char* fmt, ...)
{
    if (!g_log) return;
    SYSTEMTIME t; GetLocalTime(&t);
    fprintf(g_log, "[%02d:%02d:%02d.%03d] ", t.wHour, t.wMinute, t.wSecond, t.wMilliseconds);
    va_list a; va_start(a, fmt); vfprintf(g_log, fmt, a); va_end(a);
    fputc('\n', g_log); fflush(g_log);
}

// ---------- pattern scan over executable sections of the main module ----------
struct Pattern { std::vector<int> bytes; }; // -1 = wildcard

static Pattern Parse(const char* s)
{
    Pattern p;
    while (*s) {
        while (*s == ' ') ++s;
        if (!*s) break;
        if (*s == '?') { p.bytes.push_back(-1); while (*s == '?') ++s; }
        else { p.bytes.push_back((int)strtoul(std::string(s, 2).c_str(), nullptr, 16)); s += 2; }
    }
    return p;
}

static std::vector<uint8_t*> Scan(const char* pat, size_t maxHits = 8)
{
    std::vector<uint8_t*> hits;
    Pattern p = Parse(pat);
    auto base = (uint8_t*)GetModuleHandleW(nullptr);
    auto dos = (IMAGE_DOS_HEADER*)base;
    auto nt = (IMAGE_NT_HEADERS*)(base + dos->e_lfanew);
    auto sec = IMAGE_FIRST_SECTION(nt);
    const size_t n = p.bytes.size();
    for (int i = 0; i < nt->FileHeader.NumberOfSections; ++i, ++sec) {
        if (!(sec->Characteristics & IMAGE_SCN_MEM_EXECUTE)) continue;
        uint8_t* s = base + sec->VirtualAddress;
        size_t len = sec->Misc.VirtualSize;
        if (len < n) continue;
        const int first = p.bytes[0];
        for (size_t o = 0; o + n <= len; ++o) {
            if (first >= 0 && s[o] != first) continue;
            size_t k = 1;
            for (; k < n; ++k) if (p.bytes[k] >= 0 && s[o + k] != p.bytes[k]) break;
            if (k == n) { hits.push_back(s + o); if (hits.size() >= maxHits) return hits; }
        }
    }
    return hits;
}

static uintptr_t Rva(void* p) { return (uintptr_t)p - (uintptr_t)GetModuleHandleW(nullptr); }

static bool Write(uint8_t* at, const void* src, size_t n)
{
    DWORD old;
    if (!VirtualProtect(at, n, PAGE_EXECUTE_READWRITE, &old)) return false;
    memcpy(at, src, n);
    VirtualProtect(at, n, old, &old);
    FlushInstructionCache(GetCurrentProcess(), at, n);
    return true;
}

// ---------- patches ----------
struct Patch {
    const char* name;
    uint8_t* addr = nullptr;   // where the new bytes go
    std::vector<uint8_t> orig; // bytes expected before patching
    std::vector<uint8_t> repl; // bytes after patching
    bool applied = false;
};
static std::vector<Patch> g_patches;

// Finds a unique pattern hit, then checks the bytes at hit+off match `expect` before queueing the patch.
static void Queue(const char* name, const char* pat, size_t off,
                  std::vector<uint8_t> expect, std::vector<uint8_t> repl)
{
    auto hits = Scan(pat, 2);
    if (hits.size() != 1) {
        Log("%-9s pattern %s (%zu hits) - skipped. Game update? Patch not applied.",
            name, hits.empty() ? "NOT FOUND" : "AMBIGUOUS", hits.size());
        return;
    }
    uint8_t* at = hits[0] + off;
    if (memcmp(at, expect.data(), expect.size()) != 0) {
        if (memcmp(at, repl.data(), repl.size()) == 0) { Log("%-9s already patched at +%llX", name, (unsigned long long)Rva(at)); return; }
        Log("%-9s unexpected bytes at +%llX - skipped", name, (unsigned long long)Rva(at));
        return;
    }
    Patch p; p.name = name; p.addr = at; p.orig = expect; p.repl = repl;
    g_patches.push_back(p);
}

static void ApplyAll()
{
    for (auto& p : g_patches) {
        p.applied = Write(p.addr, p.repl.data(), p.repl.size());
        Log("%-9s %s at nightreign.exe+%llX", p.name, p.applied ? "applied" : "WRITE FAILED", (unsigned long long)Rva(p.addr));
    }
}

// Re-checks patched bytes for a while after boot and re-applies if something restored them.
static DWORD WINAPI Watchdog(LPVOID)
{
    for (int i = 0; i < 120; ++i) {
        Sleep(1000);
        for (auto& p : g_patches) {
            if (!p.applied) continue;
            if (memcmp(p.addr, p.repl.data(), p.repl.size()) != 0) {
                Log("%-9s was reverted - re-applying", p.name);
                Write(p.addr, p.repl.data(), p.repl.size());
            }
        }
    }
    Log("watchdog done");
    return 0;
}

static int IniInt(const wchar_t* ini, const wchar_t* key, int def)
{
    return (int)GetPrivateProfileIntW(L"nrwide", key, def, ini);
}

// ---------- FOV ----------
// The camera FOV getter (returns float at [[rcx]+14], degrees) is redirected to a stub that adds g_fov.offset.
// F7 / F8 change the offset in steps; it is saved to the ini and restored on the next launch.
struct alignas(16) FovVars { float offset; float lastBase; };
static FovVars g_fov = {0.0f, 0.0f};
static std::wstring g_ini;
static int g_fovStep = 5, g_fovMin = -30, g_fovMax = 60, g_keyUp = VK_F7, g_keyDown = VK_F8;

static uint8_t* BuildFovStub()
{
    auto stub = (uint8_t*)VirtualAlloc(nullptr, 64, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE);
    if (!stub) return nullptr;
    uint64_t vars = (uint64_t)&g_fov;
    uint8_t code[] = {
        0x48, 0x8B, 0x01,                   // mov rax,[rcx]
        0x48, 0x85, 0xC0,                   // test rax,rax
        0x74, 0x19,                         // je zero
        0xF3, 0x0F, 0x10, 0x40, 0x14,       // movss xmm0,[rax+14]      (game's FOV)
        0x48, 0xB8, 0,0,0,0,0,0,0,0,        // mov rax,&g_fov
        0xF3, 0x0F, 0x11, 0x40, 0x04,       // movss [rax+4],xmm0       (remember base for the log)
        0xF3, 0x0F, 0x58, 0x00,             // addss xmm0,[rax]         (+ offset)
        0xC3,                               // ret
        0x0F, 0x57, 0xC0,                   // zero: xorps xmm0,xmm0
        0xC3,                               // ret
    };
    memcpy(code + 15, &vars, 8);
    memcpy(stub, code, sizeof(code));
    FlushInstructionCache(GetCurrentProcess(), stub, sizeof(code));
    return stub;
}

static void SaveFov()
{
    wchar_t v[16]; swprintf_s(v, L"%d", (int)g_fov.offset);
    WritePrivateProfileStringW(L"nrwide", L"fov_offset", v, g_ini.c_str());
}

static bool GameFocused()
{
    DWORD pid = 0;
    if (HWND w = GetForegroundWindow()) GetWindowThreadProcessId(w, &pid);
    return pid == GetCurrentProcessId();
}

static DWORD WINAPI FovKeys(LPVOID)
{
    bool upWas = false, downWas = false;
    for (;;) {
        Sleep(15);
        bool focused = GameFocused();
        bool up = focused && (GetAsyncKeyState(g_keyUp) & 0x8000);
        bool down = focused && (GetAsyncKeyState(g_keyDown) & 0x8000);
        int dir = (up && !upWas) ? 1 : (down && !downWas) ? -1 : 0;
        upWas = up; downWas = down;
        if (!dir) continue;
        int next = (int)g_fov.offset + dir * g_fovStep;
        if (next < g_fovMin || next > g_fovMax) continue;
        g_fov.offset = (float)next;
        SaveFov();
        Log("fov offset %+d (game %.1f -> %.1f)", next, g_fov.lastBase, g_fov.lastBase + g_fov.offset);
    }
}

static bool g_fovOn = false;

static void QueueFov()
{
    g_fovStep = IniInt(g_ini.c_str(), L"fov_step", 5);
    g_fovMin = IniInt(g_ini.c_str(), L"fov_min", -30);
    g_fovMax = IniInt(g_ini.c_str(), L"fov_max", 60);
    g_keyUp = IniInt(g_ini.c_str(), L"fov_up_key", VK_F7);
    g_keyDown = IniInt(g_ini.c_str(), L"fov_down_key", VK_F8);
    int off = IniInt(g_ini.c_str(), L"fov_offset", 0);
    if (off < g_fovMin) off = g_fovMin;
    if (off > g_fovMax) off = g_fovMax;
    g_fov.offset = (float)off;

    uint8_t* stub = BuildFovStub();
    if (!stub) { Log("fov       stub allocation failed - skipped"); return; }
    std::vector<uint8_t> jmp = {0xFF, 0x25, 0, 0, 0, 0}; // jmp qword ptr [rip+0] ; <stub>
    jmp.resize(14); uint64_t s = (uint64_t)stub; memcpy(jmp.data() + 6, &s, 8);
    size_t before = g_patches.size();
    // jmp <thunk> ; getter: mov rax,[rcx]; test rax,rax; je +6; movss xmm0,[rax+14]; ret; xorps xmm0,xmm0; ret
    Queue("fov", "E9 ?? ?? ?? ?? 48 8B 01 48 85 C0 74 06 F3 0F 10 40 14 C3 0F 57 C0 C3", 5,
          {0x48, 0x8B, 0x01, 0x48, 0x85, 0xC0, 0x74, 0x06, 0xF3, 0x0F, 0x10, 0x40, 0x14, 0xC3}, jmp);
    g_fovOn = g_patches.size() > before;
    if (g_fovOn) Log("fov offset %+d loaded (F%d = wider, F%d = narrower, step %d)", off,
                     g_keyUp - VK_F1 + 1, g_keyDown - VK_F1 + 1, g_fovStep);
}

static void Init()
{
    std::wstring ini = std::wstring(g_dir) + L"\\nrwide.ini";
    g_ini = ini;
    std::wstring log = std::wstring(g_dir) + L"\\nrwide.log";
    g_log = _wfopen(log.c_str(), L"w");
    Log("nrwide 1.1 loaded into nightreign.exe (base %p)", GetModuleHandleW(nullptr));

    int ultrawide = IniInt(ini.c_str(), L"ultrawide", 1);
    int fpsUnlock = IniInt(ini.c_str(), L"fps_unlock", 1);
    int fpsLimit  = IniInt(ini.c_str(), L"fps_limit", 0);
    int hzUnlock  = IniInt(ini.c_str(), L"remove_60hz_lock", 1);

    if (ultrawide) {
        // mov eax,[rcx+r12+4B0]; test eax,eax; je A; mov r8d,[rcx+r12+4B4]; test r8d,r8d; je B (<- jmp)
        Queue("ultrawide", "42 8B 84 21 ?? ?? 00 00 85 C0 74 ?? 46 8B 84 21 ?? ?? 00 00 45 85 C0 74",
              0x17, {0x74}, {0xEB});
    }

    if (fpsUnlock) {
        if (fpsLimit <= 0) {
            DEVMODEW dm = {}; dm.dmSize = sizeof(dm);
            if (EnumDisplaySettingsW(nullptr, ENUM_CURRENT_SETTINGS, &dm) && dm.dmDisplayFrequency > 1)
                fpsLimit = (int)dm.dmDisplayFrequency;
            else
                fpsLimit = 144;
            Log("fps_limit=0 -> using monitor refresh rate %d", fpsLimit);
        }
        if (fpsLimit < 30) fpsLimit = 30;
        if (fpsLimit > 1000) fpsLimit = 1000;
        float ft = 1.0f / (float)fpsLimit;
        std::vector<uint8_t> v(4); memcpy(v.data(), &ft, 4);
        Log("fps target %d (frame time %.6f s)", fpsLimit, ft);
        // mov dword ptr [rbx+20], 3C888889 (1/60f)
        Queue("fps", "C7 43 20 89 88 88 3C", 3, {0x89, 0x88, 0x88, 0x3C}, v);
    }

    if (hzUnlock) {
        // mov dword ptr [rbp-11],3C ; mov dword ptr [rbp-D],1
        const char* hz = "C7 45 ?? 3C 00 00 00 C7 45 ?? 01 00 00 00";
        Queue("hz",      hz, 3,  {0x3C, 0, 0, 0}, {0, 0, 0, 0}); // forced refresh 60 -> 0 (keep current)
        Queue("hz-flag", hz, 10, {0x01, 0, 0, 0}, {0, 0, 0, 0}); // "refresh changed" flag -> 0
    }

    if (IniInt(ini.c_str(), L"fov", 1)) QueueFov();

    ApplyAll();
}

BOOL WINAPI DllMain(HINSTANCE h, DWORD reason, LPVOID)
{
    if (reason == DLL_PROCESS_ATTACH) {
        DisableThreadLibraryCalls(h);
        GetModuleFileNameW(h, g_dir, MAX_PATH);
        if (wchar_t* s = wcsrchr(g_dir, L'\\')) *s = 0;
        // Only act inside the game process.
        wchar_t exe[MAX_PATH]; GetModuleFileNameW(nullptr, exe, MAX_PATH);
        const wchar_t* name = wcsrchr(exe, L'\\'); name = name ? name + 1 : exe;
        if (_wcsicmp(name, L"nightreign.exe") != 0) return TRUE;
        // Runs inside the launcher's LoadLibrary call while the game's main thread is still suspended,
        // so every patch lands before the game builds its first swapchain.
        Init();
        if (HANDLE t = CreateThread(nullptr, 0, Watchdog, nullptr, 0, nullptr)) CloseHandle(t);
        bool fovApplied = false;
        for (auto& p : g_patches) if (!strcmp(p.name, "fov") && p.applied) fovApplied = true;
        if (fovApplied)
            if (HANDLE t = CreateThread(nullptr, 0, FovKeys, nullptr, 0, nullptr)) CloseHandle(t);
    }
    return TRUE;
}
