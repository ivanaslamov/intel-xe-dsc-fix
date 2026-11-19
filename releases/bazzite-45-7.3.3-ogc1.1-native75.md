# Bazzite 45 Xe RPMs — native 75 Hz fix

The new **native75 (`9.fc45`)** RPM fixes the corrupted native 5088×2544,
75 Hz image observed on the Bigscreen Beyond 2 with an MSI Claw 8 AI+.
It includes the three earlier fixes plus a headset-specific DSC slice-height
quirk. Both eyes were confirmed clear at 75 Hz and 90 Hz after installing
this exact RPM and rebooting, with no diagnostic overrides.

These experimental x86_64 RPMs require **Bazzite 45 kernel
`7.3.3-ogc1.1.fc45.x86_64`**. All five use the package name `bsb-xe-dsc` and
replace the same `xe.ko`; install one at a time.

## Choose an RPM

| RPM asset | Contents |
| --- | --- |
| **`bsb-xe-native75-7.3.3-9.fc45.x86_64.rpm`** | **Recommended for this headset:** all four patches, including the native 75 Hz fix. |
| `bsb-xe-combined-7.3.3-4.fc45.x86_64.rpm` | Three original fixes; lacks the native 75 Hz fix. |
| `bsb-xe-dsc-rate-control-7.3.3-2.fc45.x86_64.rpm` | DSC arithmetic only; requires the manual 8-bpp override for `BIG:1234`. |
| `bsb-xe-automatic-8bpp-dsc-7.3.3-5.fc45.x86_64.rpm` | Automatic 8-bpp DSC selection only, with stock rate-control arithmetic. |
| `bsb-xe-non-desktop-7.3.3-6.fc45.x86_64.rpm` | Non-desktop detection for `BIG:5095` only, with stock DSC behavior. |

The four older RPMs are unchanged binaries from the previous release, retained
for comparison. The native75 fix targets `BIG:1234`; this release does not
establish native 75 Hz compatibility for `BIG:5095` or other headsets.

## What changed and what was tested

The new patch selects four **1272×12** DSC slices for the Beyond's
5088×2544 four-slice configuration on single-stream DisplayPort. It retains
Intel's calculated rate control with the earlier arithmetic corrections.
It changes slice height, not the horizontal slice width. Each slice contains
15,264 pixels, and 12 divides the 2544-line frame evenly.

Earlier 106- and 212-line slices produced corruption. Changing rate-control
tables or using a higher DisplayPort link rate did not resolve it. The
diagnostic 12-line configuration passed full-screen checks in both eyes,
90-to-75 Hz mode switches, and a dense 8-pixel checkerboard. The separate final
RPM passed its own post-reboot 75 Hz check and 90 Hz regression check.
The underlying encoder/decoder incompatibility remains unidentified.

The final RPM has no diagnostic module parameter. The test matrix and build
receipt are in the [investigation notes](https://github.com/ivanaslamov/intel-xe-dsc-fix/blob/bazzite-45-7.3.3-ogc1.1-native75/experiments/README.md).

## Installation and verification

Check `uname -r`, verify the download against `SHA256SUMS`, and follow the
[installation, initramfs verification, and rollback instructions](https://github.com/ivanaslamov/intel-xe-dsc-fix/tree/bazzite-45-7.3.3-ogc1.1-native75#stage-and-verify-the-test-deployment).
The modules are unsigned. Set `pkg` to the native75 RPM's absolute path;
when replacing an existing `bsb-xe-dsc` layer, use the documented single
transaction and verify both staged module copies before rebooting.

Native75 RPM SHA-256:

```text
0c0ed4fb1d3e55f5b998734688d248023bff7995241bfc8fd97c5496c5ab5d33
```

Native75 module build ID: `6fb5e3add629c9c3dd9eab74757ae08d0c34f9b3`.

## Source and build information

The assets include all five RPMs, `SHA256SUMS`, the OGC kernel source archive,
and `xe-rpm-build-source.tar.gz` containing the patches, RPM spec, build script,
test notes, and the kernel configuration used for the native75 module.
`BUILD-INFO.json` records source revisions and native75 artifact hashes.

Kernel source: OGC commit
`a66e9e735fa99a7844fe18b0af0651737589f61a` (`v7.3.3-ogc1`).
Build the new variant with the matching kernel-devel headers:

```sh
JOBS=6 bash packaging/build-rpms.sh /path/to/ogc-linux-7.3.3-ogc1.tar.gz \
  /lib/modules/7.3.3-ogc1.1.fc45.x86_64/build native75
```

Build paths and timestamps can change binary hashes and build IDs. The release
ships the original hardware-tested native75 binary.
