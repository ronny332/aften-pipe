# Native Windows builds with Microsoft Visual C++ (x64 and 32-bit).
# Needs any Visual Studio 2017+ / Build Tools with the "Desktop development
# with C++" workload; CMake finds the toolset through the registry, so this
# runs from a plain shell (no vcvars environment needed).
# Result: bin\aften-<ver>-msvc-x64.exe  and  bin\aften-<ver>-msvc-i386.exe
param([string]$Version = "", [string]$CMake = "")

# Native tools write warnings to stderr, and PowerShell turns those into
# terminating errors under "Stop"; check $LASTEXITCODE by hand instead.
$ErrorActionPreference = "Continue"
Set-Location (Split-Path -Parent $PSScriptRoot)

# Package managers install a launcher shim (scoop) that cannot spawn processes
# in a non-interactive session (ssh, service, CI agent), so make sure the cmake
# on PATH really runs before using it.
function Test-CMake([string]$exe) {
    if (-not $exe) { return $null }
    $out = (& $exe --version 2>&1 | Out-String)
    if ($out -match "cmake version") { return $exe }
    return $null
}

if (-not $CMake) {
    $cmd = Get-Command cmake -ErrorAction SilentlyContinue
    $CMake = Test-CMake $(if ($cmd) { $cmd.Source })
    if (-not $CMake) {
        $cand = @("$env:SCOOP\apps\cmake\*\bin\cmake.exe",
                  "$env:USERPROFILE\scoop\apps\cmake\*\bin\cmake.exe",
                  "${env:ProgramFiles}\CMake\bin\cmake.exe",
                  "${env:ProgramFiles(x86)}\CMake\bin\cmake.exe")
        foreach ($c in $cand) {
            $p = Resolve-Path $c -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($p) { $CMake = Test-CMake $p.Path; if ($CMake) { break } }
        }
    }
}
if (-not $CMake) { throw "cmake not found; pass -CMake <path to cmake.exe>" }
"CMake: $CMake"

if (-not $Version) {
    $Version = (Select-String -Path libaften\a52.h -Pattern 'AFTEN_VERSION "([^"]*)"' |
                 ForEach-Object { $_.Matches[0].Groups[1].Value })
}
if (-not $Version) { throw "could not read AFTEN_VERSION from libaften\a52.h" }

New-Item -ItemType Directory -Force bin | Out-Null

foreach ($arch in "x64", "Win32") {
    $dir = "build-msvc-$arch"
    if (Test-Path $dir) { Remove-Item -Recurse -Force $dir }
    # /MT so the asset needs no VC++ redistributable, like every other build
    # here; NDEBUG is repeated because overriding the Release flags replaces
    # the default set, which carried it (the project adds its own /Ot /Oy /Oi
    # /Ox on top)
    # note the quotes: PowerShell splits an unquoted "...=3.5" argument into
    # "3" and ".5" before cmake ever sees it
    & $CMake -S . -B $dir -A $arch -DCMAKE_BUILD_TYPE=Release `
                    "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" `
                    "-DCMAKE_C_FLAGS_RELEASE=/MT /DNDEBUG"
    if ($LASTEXITCODE) { throw "configure failed ($arch)" }
    & $CMake --build $dir --config Release -j
    if ($LASTEXITCODE) { throw "build failed ($arch)" }
    $exe = Join-Path $dir "Release\aften.exe"
    if (-not (Test-Path $exe)) { throw "no aften.exe produced ($arch)" }
    $tag = if ($arch -eq "x64") { "x64" } else { "i386" }
    Copy-Item $exe "bin\aften-$Version-msvc-$tag.exe" -Force
}

Get-ChildItem "bin\aften-$Version-msvc-*.exe" |
    ForEach-Object { "{0}  {1:N0} bytes" -f $_.Name, $_.Length }
