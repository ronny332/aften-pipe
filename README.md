# aften-pipe

**Aften: A/52 audio encoder** — the original SourceForge code (git
`89aee3d`, 2011) plus a handful of small **pipe / stdin** fixes, and
old-school static binaries for Windows (XP+) and Linux.

> **Whose work this is.** The encoder, the PCM/WAV reader, the SIMD
> kernels, the API — essentially all 15,000 lines — are the work of
> **Justin Ruggles, Prakash Punnoor, and the other aften contributors**
> (2006–2011). Canonical upstream:
> [aften.sourceforge.net](https://aften.sourceforge.net/) (git
> `89aee3d`), which is the tree this fork was built from.
> The author's own GitHub mirror,
> [github.com/justinruggles/aften](https://github.com/justinruggles/aften),
> was discovered **after** this build was made — it carries the
> identical 886-commit history, imported 2020 and dormant since; no
> pull request is intended, and this repo asks for nothing. It exists
> for joy and for the people who are happily still using this little
> tool.
> This repository is a faithful copy of the upstream tree with ~100
> lines of small fixes on top. The authorship of everything that
> matters — the encoder — is untouched and stays where it belongs. The
> extra patches are a drop in the ocean; consider them public domain
> and uncredited.

> **Why a fork, why "for fun"?** Upstream has been quiet since 2011.
> The SourceForge tree is frozen and a pull request would, in all
> likelihood, never be looked at — so this is not a contribution to a
> project, it is a service to an *audience*: the people who, like me,
> are happily still using this little tool fifteen years later. Purely
> for fun. No maintainer, no roadmap, no support promises.

## What changed (all of it)

| Commit | Change |
|---|---|
| `wav: handle streamed input with placeholder data size` | `pcm/wav.c`: streaming muxers (FFmpeg, …) write `0xFFFFFFFF` as placeholder data size on pipes; the 2011 code sign-extended that into a garbage 16 EB sample count. Streamed WAV input now works without `-readtoeof 1`. |
| `opts: auto-detect piped stdin` | `aften/opts.c`: if no input filename is given and stdin is not a terminal, stdin is used. `ffmpeg … \| aften out.ac3` and `aften out.ac3 < in.wav` work. |
| `aften: fix short-stream padding copy, do not fclose stdin/stdout` | `aften/aften.c`: a `memmove` copied bytes instead of samples (visible with `-pad 0` on short streams); `stdin`/`stdout` are no longer `fclose()`d (MSVC debug CRT abort). |
| `helptext: document pipe/stdin/stdout usage` | `aften/helptext.h`: pipe input/output has existed in aften **since 2006**, it was just never mentioned in the help text. |
| `cmake: detect machine type on 64-bit Windows` | `CMakeModules/DetectCompiler.cmake`: the 2011 check demanded that `CMAKE_SYSTEM_PROCESSOR` contain `x86`, and 64-bit Windows reports `AMD64`, so every native MSVC build stopped with *"Could not detect machine type"*. Windows x64 and 32-bit now configure (bitness taken from the pointer size, which is the only thing that can tell them apart), unknown CPUs build portable C instead of aborting the configure, and the host `uname` is no longer trusted when cross-compiling. Verified with VS 2026 BuildTools (MSVC 19.51): x64 and Win32 both build and encode. |
| `version 0.09pipe2` | version string, Changelog. |

The encoder core, bitstream output, SIMD code and the C/C++/C# API are
**bit-for-bit unchanged**. Encodes from these builds are byte-identical
to the original through pipes, files, and stdout.

> **One nuance about "byte-identical".** It holds *within* a toolchain.
> Measured on a 5-second stereo 48 kHz encode (375 frames, 240 384 bytes):
> MSVC x64, MSVC Win32, `-threads 1…16` and `-nosimd` all produce the same
> bytes; the gcc builds (Linux, mingw) agree with each other. MSVC and gcc
> differ by 3 bytes, all inside frames 364-365, because the DC/bandwidth/LFE
> filter coefficients are computed at runtime with `cos`/`sqrt` from
> `libm`, and the two libraries round in the last ULP. Decoded, the two
> streams are within 2 LSB of 16-bit (≈ −96 dB), on 0.03 % of the samples.
> So comparing MD5s across compilers is meaningless; comparing them across
> pipes and files with the same binary is exactly the right test.

## Usage

The original aften syntax is untouched. The pipe parts:

```sh
# encode from a pipe (FFmpeg decoding anything aften can't read)
ffmpeg -i input.mp4 -f wav - | aften - out.ac3

# with the new auto-detection, the dash is optional:
ffmpeg -i input.mp4 -f wav - | aften out.ac3
aften out.ac3 < input.wav

# write the AC-3 stream to stdout
ffmpeg -i input.wav -f wav - | aften - - > out.ac3
aften input.wav - > out.ac3

# raw PCM pipes
ffmpeg -i in.mkv -f s16le -acodec pcm_s16le - | \
    aften -raw_fmt s16_le -raw_ch 2 -raw_sr 48000 - out.ac3
```

Windows notes: stdin/stdout are switched to binary mode automatically
(`_setmode`); in `cmd.exe` the pipes above work as-is.

## Downloads

Release assets (all fully static, no redistributables, no installer):

| File | Platform | Runs on |
|---|---|---|
| `aften-0.09pipe2-win32.exe` | Windows, 32-bit | Windows 7 (needs the free UCRT update KB2999226), 8.1, 10, 11 — 32- and 64-bit |
| `aften-0.09pipe2-win32-xp.exe` | Windows, 32-bit, **`msvcrt.dll` runtime** | Windows XP / 2003 and newer — the true old-school binary |
| `aften-0.09pipe2-msvc-x64.exe` | Windows, 64-bit, MSVC, **CRT linked in** (`/MT`, 331 KB) | Windows 10 / 11 x64; on Win 7 / 8.1 the UCRT update is expected to be needed, untested |
| `aften-0.09pipe2-msvc-i386.exe` | Windows, 32-bit, MSVC, **CRT linked in** (`/MT`, 276 KB) | 32- and 64-bit Windows; no VC++ redistributable |
| `aften-0.09pipe2-linux-x86_64` | Linux, x86_64, static | any distribution (built against glibc 2.28, fully static) |

The `-xp` build links against `msvcrt.dll`, the C runtime that ships
with every Windows NT since 1996; the plain build uses the modern
Universal CRT that ships with Windows 10+. Both are ~230 KB.

The two `-msvc-` builds come from Microsoft's own compiler
(`build_windows.cmd`). They import no `VCRUNTIME140.dll` and no
`api-ms-win-crt-*` — the CRT is linked in, like every other asset here.
x64 and i386 produce byte-identical streams (verified), and both sit 3
bytes / 2 LSB away from the mingw builds, as described under *What
changed*.

## Building

Three ways in; the first line of each is the one to copy.

| platform | build step | result |
|---|---|---|
| POSIX (Linux, *BSD, macOS) | `cmake --build build -j` | `build/aften` |
| Windows, Visual C++ | `cmake --build build --config Release` | `build\Release\aften.exe` |
| cross `aften.exe` from Linux | `cmake --build build-win --target aften_exe -j` | `build-win/aften.exe` |

Laziest path: `./build_linux.sh` on POSIX, and double-click
`build_windows.cmd` on Windows. Both run the commands below with the
flags that suit the platform, so you can read the details at your
leisure.

> **The Windows trap.** The Visual Studio generator is *multi-config*:
> `-DCMAKE_BUILD_TYPE=Release` is accepted, cached, and **ignored**, and
> `cmake --build build` then builds the first entry of
> `CMAKE_CONFIGURATION_TYPES` — which is **Debug**: `/Od`, intrinsics not
> inlined, every `assert()` in `libaften/` live, several times slower.
> Nothing warns you, because this is a 2011-era CMake file. Add
> `--config Release`, or pin the list once at configure time with
> `-DCMAKE_CONFIGURATION_TYPES=Release` (MSBuild takes the first entry
> when no `--config` is given). The arithmetic is the same in Debug —
> x64 uses SSE2 either way — plus the assertions, which abort, so Debug
> can die on input that Release silently encodes. Single-config
> generators (Makefiles, Ninja — everything on Linux) honour
> `CMAKE_BUILD_TYPE` and have no such footgun; `--config` is ignored
> there.

Native (any POSIX):

```sh
cmake -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_POLICY_VERSION_MINIMUM=3.5
cmake --build build -j        # -> build/aften, plus wavinfo, wavrms, wavfilter
```

Cross-compile `aften.exe` from Linux (needs `gcc-mingw-w64-i686`,
Arch: `mingw-w64-gcc`):

```sh
cmake -B build-win -DCMAKE_TOOLCHAIN_FILE=mingw32.cmake \
      -DCMAKE_BUILD_TYPE=Release -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
      -DCMAKE_C_FLAGS="-std=gnu99 -fcommon"
cmake --build build-win --target aften_exe -j
```

The flags: the tree predates CMake 3 (`POLICY_VERSION_MINIMUM`), gcc ≥
10 needs `-fcommon` for the old tentative definitions, and `-std=gnu99`
pins the compiler to the C dialect of the era. The source is kept in
its original C99-flavored style on purpose.

Native Windows build (Visual Studio 2017+ or Build Tools, C++ workload):

```bat
cmake -S . -B ..\aften-build -G "Visual Studio 18 2026" -A x64 -DCMAKE_BUILD_TYPE=Release -DCMAKE_POLICY_VERSION_MINIMUM=3.5
cmake --build ..\aften-build --config Release    (-> ..\aften-build\Release\aften.exe)
```

- Use `-A Win32` for a 32-bit build. MMX is off in x64 (MSVC has no
  `__m64` there), SSE/SSE2/SSE3 are on; both bitnesses produce the same
  stream. The 32-bit build is the only one that compiles the Intel-syntax
  inline-asm CPU detection — MSVC x64 uses the `__cpuid` intrinsic.
- `-DCMAKE_CONFIGURATION_TYPES=Release` makes a plain
  `cmake --build build -j` build Release on Windows, for the cases where
  you cannot add `--config`: a wrapper script, an IDE task, CI.
- `build_windows.cmd` in the repo root (double-click, or run it from
  `cmd.exe`) is the lazy path: x64 and Win32 in one go, `/MT` so the
  assets need no VC++ redistributable, versioned names in `bin\`.
  Flags: `-64` / `-32` for one bitness, `-clean`, `-h`. It is plain
  batch, no PowerShell anywhere, and it looks for the real `cmake.exe`
  when your cmake on PATH is a launcher shim (scoop's shims cannot
  spawn processes over ssh, in services, or in CI agents).
- The VS *generator* finds the toolset through the registry, so no
  *Developer Prompt* / `vcvars64.bat` environment is needed; a plain
  `cmd.exe` works, and so does an ssh session.
- Older trees: run the configure from `cmd.exe`, not from Git-Bash/MSYS2,
  whose `uname -m` answers `MSYS_NT-10.0-…` (an OS name, not a CPU) —
  the 2011 machine check then silently configured **without SIMD**. This
  tree falls back to the CPU CMake reports, so it copes with both.
- In **PowerShell**, quote options that carry a dot: `"-DCMAKE_POLICY_VERSION_MINIMUM=3.5"`.
  Unquoted, PowerShell splits that argument into `3` and `.5`, and CMake
  answers `Invalid CMAKE_POLICY_VERSION_MINIMUM value "3"`. `cmd.exe`,
  which the example above uses, is not affected.
- With the released `0.09pipe1` sources (before the machine-type fix),
  add `set PROCESSOR_ARCHITECTURE=x86` before the configure line, and
  64-bit MSVC will configure.

Containerized cross builds (podman/docker, reproduce the release assets):

```sh
ci/build-all.sh        # UCRT build from the host, XP + Linux builds in containers
```

CI: `.github/workflows/build.yml` builds all the assets on tag push
(win32 UCRT, win32 msvcrt/XP, MSVC x64 + i386, Linux static) and
publishes them to the GitHub Release.

## License

GNU LGPL 2.1, same as upstream — see `COPYING`. Attribution for the
code is in the file headers (Justin Ruggles, Prakash Punnoor, et al.).
