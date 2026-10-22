# aften-pipe

**Aften: A/52 audio encoder** — the original SourceForge code (git
`89aee3d`, 2011) plus a handful of small **pipe / stdin** fixes, and
old-school static binaries for Windows (XP+) and Linux.

> **Whose work this is.** The encoder, the PCM/WAV reader, the SIMD
> kernels, the API — essentially all 15,000 lines — are the work of
> **Justin Ruggles, Prakash Punnoor, and the other aften contributors**
> (2006–2011, upstream:
> [aften on SourceForge](https://aften.sourceforge.net/)).
> This repository is a faithful copy of their tree with ~100 lines of
> small fixes on top. The authorship of everything that matters — the
> encoder — is untouched and stays where it belongs. The extra patches
> are a drop in the ocean; consider them public domain and uncredited.

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
| `version 0.09pipe1` | version string, Changelog. |

The encoder core, bitstream output, SIMD code and the C/C++/C# API are
**bit-for-bit unchanged**. Encodes from these builds are byte-identical
to the original through pipes, files, and stdout.

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
| `aften-0.09pipe1-win32.exe` | Windows, 32-bit | Windows 7 (needs the free UCRT update KB2999226), 8.1, 10, 11 — 32- and 64-bit |
| `aften-0.09pipe1-win32-xp.exe` | Windows, 32-bit, **`msvcrt.dll` runtime** | Windows XP / 2003 and newer — the true old-school binary |
| `aften-0.09pipe1-linux-x86_64` | Linux, x86_64, static | any distribution (built against glibc 2.28, fully static) |

The `-xp` build links against `msvcrt.dll`, the C runtime that ships
with every Windows NT since 1996; the plain build uses the modern
Universal CRT that ships with Windows 10+. Both are ~230 KB.

## Building

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

Containerized cross builds (podman/docker, reproduce the release assets):

```sh
ci/build-all.sh        # UCRT build from the host, XP + Linux builds in containers
```

CI: `.github/workflows/build.yml` builds all three assets on tag push
and publishes them to the GitHub Release.

## License

GNU LGPL 2.1, same as upstream — see `COPYING`. Attribution for the
code is in the file headers (Justin Ruggles, Prakash Punnoor, et al.).
