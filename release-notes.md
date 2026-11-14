Experimental Xe module RPMs for **Bazzite 45 kernel `7.3.3-ogc1.1.fc45.x86_64`**. Install one RPM at a time. All four replace the same `xe.ko` and use the package name `bsb-xe-dsc`.

## Combined build

**[Download all three fixes](https://github.com/ivanaslamov/intel-xe-dsc-fix/releases/download/bazzite-45-7.3.3-ogc1.1-variants/bsb-xe-combined-7.3.3-4.fc45.x86_64.rpm)** (`4.fc45`). Use this build to try the complete fix. It corrects DSC rate control, automatically selects 8-bpp DSC for `BIG:1234`, and marks `BIG:5095` as non-desktop so the compositor can offer it for a DRM lease.

## Standalone builds for testing

Each RPM applies one patch to the stock Xe module.

| Download | Patch included |
| --- | --- |
| [DSC rate control](https://github.com/ivanaslamov/intel-xe-dsc-fix/releases/download/bazzite-45-7.3.3-ogc1.1-variants/bsb-xe-dsc-rate-control-7.3.3-2.fc45.x86_64.rpm) (`2.fc45`) | Corrects DSC arithmetic. For `BIG:1234`, use the [manual 8-bpp override](https://github.com/ivanaslamov/intel-xe-dsc-fix/tree/bazzite-45-7.3.3-ogc1.1-variants#manually-enable-8-bpp-dsc-for-the-headset). |
| [Automatic 8-bpp DSC](https://github.com/ivanaslamov/intel-xe-dsc-fix/releases/download/bazzite-45-7.3.3-ogc1.1-variants/bsb-xe-automatic-8bpp-dsc-7.3.3-5.fc45.x86_64.rpm) (`5.fc45`) | Selects 8-bpp DSC for `BIG:1234` using stock rate-control arithmetic. |
| [Non-desktop detection](https://github.com/ivanaslamov/intel-xe-dsc-fix/releases/download/bazzite-45-7.3.3-ogc1.1-variants/bsb-xe-non-desktop-7.3.3-6.fc45.x86_64.rpm) (`6.fc45`) | Marks `BIG:5095` as non-desktop. DSC behavior follows the stock kernel. |

The rate-control and combined downloads reuse the binaries from the earlier prerelease. The two new standalone builds were compiled and checked against the matching kernel headers. On the Claw, the rate-control fix with a manual 8-bpp override produced a clear 3840×1920, 90 Hz image. Headset validation of the combined download and the two new standalone builds is pending.

## Installation

Check your running kernel with `uname -r`, verify the RPM against `SHA256SUMS`, and follow the [Bazzite installation and rollback instructions](https://github.com/ivanaslamov/intel-xe-dsc-fix/tree/bazzite-45-7.3.3-ogc1.1-variants#stage-and-verify-the-test-deployment). Set `pkg` to the downloaded RPM's absolute path. The modules are unsigned.

The release includes the OGC kernel source archive and a source bundle with the patches, RPM spec, build script, and kernel configuration.
