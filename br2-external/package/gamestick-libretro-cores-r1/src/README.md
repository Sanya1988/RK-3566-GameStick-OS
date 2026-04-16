# Gamestick Libretro Cores R1

This bundle contains the first-pass aarch64 libretro cores built for the
working RK3566 RetroArch baseline.

Included cores:
- gambatte_libretro.so
- fceumm_libretro.so
- gpsp_libretro.so
- nestopia_libretro.so
- snes9x_libretro.so
- gearsystem_libretro.so
- pcsx_rearmed_libretro.so
- picodrive_libretro.so

Info files:
- gambatte_libretro.info
- fceumm_libretro.info
- gpsp_libretro.info
- nestopia_libretro.info
- snes9x_libretro.info
- gearsystem_libretro.info
- pcsx_rearmed_libretro.info
- picodrive_libretro.info

Upstream source repos used for the binaries in this bundle:
- https://github.com/libretro/gambatte-libretro
- https://github.com/libretro/libretro-fceumm
- https://github.com/libretro/gpsp
- https://github.com/libretro/nestopia
- https://github.com/libretro/snes9x
- https://github.com/drhelius/Gearsystem
- https://github.com/libretro/pcsx_rearmed
- https://github.com/libretro/picodrive
- https://github.com/libretro/libretro-core-info

Build notes:
- Built with the Buildroot aarch64 external toolchain from this workspace.
- gpsp requires serial build on arm64 because its Makefile has a parallel build race.
- picodrive required a full source tree with submodules; the plain tarball was insufficient.
