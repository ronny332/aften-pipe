# Normalize a machine name (uname -m, %PROCESSOR_ARCHITECTURE%, ...) into a CPU
# family: "x86", "ppc", or "" when the name is not known.
MACRO(MACHINE_TEST NAME VAR)
  STRING(TOUPPER "${${NAME}}" _mt)
  IF(_mt MATCHES "(^|[-_/. ])(X86_64|AMD64|X64|X86|I[3-6]86)([-_/. ]|$)")
    SET(${VAR} "x86")
  ELSEIF(_mt MATCHES "(^|[-_/. ])(POWER MACINTOSH|PPC|POWERPC|POWER[0-9])")
    SET(${VAR} "ppc")
  ELSE(_mt MATCHES "(^|[-_/. ])(X86_64|AMD64|X64|X86|I[3-6]86)([-_/. ]|$)")
    SET(${VAR} "")
  ENDIF(_mt MATCHES "(^|[-_/. ])(X86_64|AMD64|X64|X86|I[3-6]86)([-_/. ]|$)")
ENDMACRO(MACHINE_TEST)

# Sets CMAKE_SYSTEM_MACHINE to the spellings the SIMD blocks in CMakeLists.txt
# match on: "i.86", "x86_64", "ppc", or "generic" for anything else.
MACRO(DETECT_MACHINE)
  SET(CMAKE_SYSTEM_MACHINE "")

  # uname names the machine CMake runs on, which is the wrong answer when
  # cross-compiling; CMAKE_SYSTEM_PROCESSOR names the target there
  SET(_aft_name "")
  IF(CMAKE_UNAME AND NOT CMAKE_CROSSCOMPILING)
    EXECUTE_PROCESS(COMMAND ${CMAKE_UNAME} -m
                    OUTPUT_VARIABLE _aft_name
                    OUTPUT_STRIP_TRAILING_WHITESPACE)
  ENDIF(CMAKE_UNAME AND NOT CMAKE_CROSSCOMPILING)

  IF(NOT _aft_name)
    # Windows has no uname, so CMake reports %PROCESSOR_ARCHITECTURE% here:
    # "AMD64" on 64-bit, "x86" on 32-bit, "ARM64" on Windows on ARM.  A Windows
    # CMake run from an MSYS shell also lands here: its uname names the OS
    # ("MSYS_NT-10.0-..."), not the CPU.
    SET(_aft_name "${CMAKE_SYSTEM_PROCESSOR}")
  ENDIF(NOT _aft_name)

  MACHINE_TEST(_aft_name _aft_family)

  IF(NOT _aft_family AND NOT "${CMAKE_SYSTEM_PROCESSOR}" STREQUAL "${_aft_name}")
    # uname in MSYS2/WSL shells names the OS ("MSYS_NT-10.0-..."), not the CPU,
    # so fall back to the processor CMake reports for the target
    SET(_aft_name "${CMAKE_SYSTEM_PROCESSOR}")
    MACHINE_TEST(_aft_name _aft_family)
  ENDIF(NOT _aft_family AND NOT "${CMAKE_SYSTEM_PROCESSOR}" STREQUAL "${_aft_name}")

  IF(_aft_family STREQUAL "x86")
    # the name alone does not tell 32-bit from 64-bit: "AMD64" is reported even
    # for a 32-bit build, because a WOW64 shell reports the host CPU
    IF(CMAKE_SIZEOF_VOID_P MATCHES "^8$")
      SET(CMAKE_SYSTEM_MACHINE "x86_64")
    ELSE(CMAKE_SIZEOF_VOID_P MATCHES "^8$")
      SET(CMAKE_SYSTEM_MACHINE "i386")
    ENDIF(CMAKE_SIZEOF_VOID_P MATCHES "^8$")
  ELSEIF(_aft_family STREQUAL "ppc")
    SET(CMAKE_SYSTEM_MACHINE "ppc")
  ELSE(_aft_family STREQUAL "x86")
    # nothing below needs a machine type; the encoder is plain C everywhere
    MESSAGE(STATUS "Unrecognized machine type \"${_aft_name}\", building portable C")
    SET(CMAKE_SYSTEM_MACHINE "generic")
  ENDIF(_aft_family STREQUAL "x86")

  MESSAGE(STATUS "Machine type: ${CMAKE_SYSTEM_MACHINE}")
ENDMACRO(DETECT_MACHINE)

MACRO(DETECT_COMPILER)
IF(NOT CMAKE_COMPILER_IS_GNUCC)
  CHECK_C_SOURCE_COMPILES(
"#ifndef __INTEL_COMPILER
#error no icc
#endif
int main(){}
" CMAKE_COMPILER_IS_ICC)
ENDIF(NOT CMAKE_COMPILER_IS_GNUCC)
ENDMACRO(DETECT_COMPILER)

MACRO(MACRO_TEST ARG VAR)
CHECK_C_SOURCE_COMPILES(
"#ifndef ${ARG}
#error ${ARG} macro not defined
#endif
int main(){}
" ${VAR})
ENDMACRO(MACRO_TEST)

#check whether we are 32/64 bits cross-compiling
MACRO(CHECK_64BITS)
IF(CMAKE_COMPILER_IS_GNUCC)
  MACRO_TEST(__LP64__  HAVE_64BITS)
  IF(HAVE_64BITS AND CMAKE_SYSTEM_MACHINE MATCHES "i.86")
    SET(CMAKE_SYSTEM_MACHINE "x86_64")
  ENDIF(HAVE_64BITS AND CMAKE_SYSTEM_MACHINE MATCHES "i.86")

  IF(NOT HAVE_64BITS AND CMAKE_SYSTEM_MACHINE MATCHES "x86_64")
    SET(CMAKE_SYSTEM_MACHINE "i686")
  ENDIF(NOT HAVE_64BITS AND CMAKE_SYSTEM_MACHINE MATCHES "x86_64")
ENDIF(CMAKE_COMPILER_IS_GNUCC)
ENDMACRO(CHECK_64BITS)
