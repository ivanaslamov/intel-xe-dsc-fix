# Native 75 Hz investigation, November 18, 2026

The current fix is `../beyond-native75-short-slices.patch`: **four 1272×48
slices at native 5088×2544, 75 Hz**, with the existing 8-bpp DSC and calculated
rate-control fixes. It has no diagnostic parameter or 12-line option.
The old diagnostic patch and build script have been retired from this branch.
Their original source remains in [Git history](https://github.com/ivanaslamov/intel-xe-dsc-fix/tree/09d47a3fc222af783ad1e10e534a6f10217cbf46/experiments).

## Earlier investigation

90 Hz remained clear with both the normal pipe configuration and forced joined
B+C pipes/four DSC engines. Native 75 Hz with eight 636×106 slices was corrupted
at both HBR1 and HBR2. Switching to legacy DSC 1.1 rate-control tables did not
resolve it. Four 1272×106 slices showed recognizable checkerboard only near the
top of the image; the remainder was corrupted.

Four 1272×12 slices were the first working native configuration. Both eyes
were clear with normal and dense checkerboards, and the separate release 9
build passed its own reboot and 75/90 Hz optical checks. That build is
superseded by the fixed 48-line build; it is recorded here as an observation,
not an installation option.

## 48-line comparison

A local A/B module based on release 9 changed only slice height between 12 and
48, letting the driver derive the dependent rate-control values. It retained
four horizontal slices, width 1272, 8 compressed bpp, RGB, the same active pipe
and DSC engines, and the same DisplayPort link configuration.

At 48 lines, both enabled DSC engines and the source PPS packet buffer reported
1272×48 slices, with 53 slice rows per frame. AUX snapshots matched the 12-line
baseline. The user confirmed a clear, stable image across both eyes, including
the bottom, with normal 212-pixel and dense 8-pixel checkerboards. The 90 Hz
regression check also passed.

The changed derived values were:

| DSC field | Earlier 12-line setting | Selected 48-line setting |
| --- | --- | --- |
| Slice rows per frame | 212 | 53 |
| Initial decoder delay | 892 | 1051 |
| Scale increment interval | 401 | 1433 |
| First-line BPG offset | 12 | 15 |
| Non-first-line BPG offset | 2235 | 654 |
| Slice BPG offset | 921 | 231 |

The permanent `11.fc45` build applies the four release patches to the matching
OGC source and kernel-devel tree, fixes height at 48, and contains no experimental
module parameters. Build provenance is recorded in the release's `BUILD-INFO.json`.
Machine-specific staging scripts and raw captures remain outside this public repo.

## Limits of the result

The comparison identifies working geometries and their derived parameters. It
does not establish the decoder's undocumented limitation or prove a general
Intel encoder defect. The 106-line and 212-line settings being standards-valid
does not establish compatibility with this particular sink. The successful
48-line checkerboard tests do not measure compression quality or prolonged VR
stability. A 53-line slice height was not tested. Source PPS registers are not
a sink-side capture of the received stream.
