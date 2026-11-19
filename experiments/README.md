# Native 75 Hz investigation, November 18, 2026

This directory preserves the experimental comparison patch and build script
used to isolate a working setting. **Use the root-level
`beyond-native75-short-slices.patch` and the `native75` RPM for the final fix.**
The diagnostic patch applies on top of the three original patches, replacing
the earlier geometry experiments; do not combine it with the final fix.
It keeps the 90 Hz path unchanged. The default reproduces test2 (eight 636×106
slices). The kernel's existing DSC geometry, sink capability, link bandwidth,
and rate-control calculations remain in use.

On this Claw, user optical checks confirm that 90 Hz is clear with both one pipe
and forced joined B+C pipes/four DSC engines. Native 75 Hz with eight slices is
corrupted at both HBR1 and HBR2. The source PPS and encoder register values were
previously validated against VESA model 1.67. That validates the programmed
parameters, not the encoded stream or the decoder's compatibility with them.

The new comparison tests the kernel's existing `DRM_DSC_1_1_PRE_SCR` table against
Intel's calculated rate-control settings. This is a decoder-compatibility
hypothesis; it does not establish that the calculated settings are invalid.
The two additional geometries meet Intel's 15,000-pixel minimum slice area and
divide the native frame evenly.

Write `xe.beyond_dsc_test` through `/sys/module/xe/parameters/beyond_dsc_test`
only with the headset disabled, then perform a full modeset. The override is
restricted to `BIG:1234` native width; height/RC changes also require 2544 lines.
It resets to zero on reboot and has root-only permissions.

| Case | Horizontal slices | Slice width × height | RC |
| --- | --- | --- | --- |
| 0 | 8 | 636×106 | Calculated; test2 baseline |
| 1 | 8 | 636×106 | Legacy DSC 1.1 |
| 2 | 4 | 1272×106 | Calculated; test1 baseline |
| 3 | 4 | 1272×106 | Legacy DSC 1.1 |
| 4 | 4 | 1272×12 | Calculated |
| 5 | 4 | 1272×12 | Legacy DSC 1.1 |
| 6 | 8 | 636×24 | Calculated |
| 7 | 8 | 636×24 | Legacy DSC 1.1 |

`build-native75-lab.sh` verifies the source archive, builds against the matching
kernel headers, and packages release `8.lab1.fc45`. On the Claw, extracted RPM
tools require `RPMBUILD` and `RPM_TOOLS_DIR`; no system packages need changing.

The staging procedure pinned the previous deployment and verified both the
staged module and initramfs against the RPM before rebooting. Machine-specific
staging scripts and deployment captures remain in the local investigation
archive. See the main README for the reusable installation and rollback steps.

Diagnostic module receipt (not a release asset):
Module build ID: `dddaf8b234d6ce1f8297eb67acf99b67d855264d`.
RPM SHA-256: `aa7dedc1eba939dc5608aab3f2a0cc732c7e66a381cb77b04d85744743bc7a7f`.

The companion `BeyondCheckerboard/tools/dsc_link_lab.py --kernel-lab` executes
fixed named cases, captures software/encoder/PPS/AUX state, and restores the
original overrides and clear 90 Hz mode on exit. Physical headset observations
are required for every result.

## Results

On November 18, case 1 remained colored noise. Case 3 produced stationary noise
without the previous vertical lines. In case 2, the user could recognize the
checkerboard over approximately the top 15% of the display. **Case 4 produced a
clear image across both eyes**, including the bottom. It remained clear after
switching to 90 Hz and back, then reacquiring the lease with dense 8-pixel cells.
90 Hz was also confirmed clear in both eyes. Cases 5–7 were unnecessary after
case 4 succeeded and were not tested.

The resulting `../beyond-native75-short-slices.patch` changes only the native
four-slice mode's height to 12, retaining the calculated RC path. It contains no
experimental module parameter. Release `9.fc45` was compiled separately from
the verified base plus the three existing fixes and this new patch. The final
build passed its own reboot and optical checks: both eyes fully clear at 75 Hz,
and both eyes clear at 90 Hz. The final state is the 75 Hz checkerboard.
Build ID: `6fb5e3add629c9c3dd9eab74757ae08d0c34f9b3`.
RPM SHA-256: `0c0ed4fb1d3e55f5b998734688d248023bff7995241bfc8fd97c5496c5ab5d33`.

The comparison isolates a working geometry and its derived RC parameters. It
does not establish the decoder's undocumented limitation or prove a general
Intel encoder defect. The 106-line and 212-line settings being standards-valid
does not establish compatibility with this particular sink.
