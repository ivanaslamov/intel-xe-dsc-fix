# Bigscreen Beyond 2e on the MSI Claw 8 AI+

This repository contains the four patches needed to connect a Bigscreen Beyond 2e (BSB2e) to an MSI Claw 8 AI+ running Linux with the Intel Xe graphics driver.

## Patches

1. [`intel-xe-dsc-rc.patch`](intel-xe-dsc-rc.patch) fixes two Display Stream Compression (DSC) rate-control calculations for the RGB quantization table index and the bits-per-group offset.
2. [`beyond-fixed-dsc.patch`](beyond-fixed-dsc.patch) enables DSC at 8 compressed bits per pixel when the driver detects the headset’s `BIG:1234` display ID on DisplayPort.
3. [`beyond-non-desktop.patch`](beyond-non-desktop.patch) marks the `BIG:5095` display ID as non-desktop so KDE can lease the headset’s connector to a VR app.
4. [`beyond-native75-short-slices.patch`](beyond-native75-short-slices.patch) uses 48-line DSC slices to fix image corruption on `BIG:1234` at 5088×2544, 75 Hz.

## Install on Bazzite 45

1. Run `uname -r` on the Claw. The prebuilt RPM requires exactly `7.3.3-ogc1.1.fc45.x86_64`.
2. Download `bsb-xe-native75-7.3.3-11.fc45.x86_64.rpm` and `SHA256SUMS` from the [release](https://github.com/ivanaslamov/intel-xe-dsc-fix/releases/tag/bazzite-45-7.3.3-ogc1.1-native75-48). This RPM includes all four patches.
3. Verify the checksum, then follow the [install and verification commands](https://github.com/ivanaslamov/intel-xe-dsc-fix/blob/bazzite-45-7.3.3-ogc1.1-native75-48/README.md#stage-and-verify-the-test-deployment) to stage the RPM and check the boot image before rebooting.
4. Connect the headset and start your VR app. The tested modes are 3840×1920 at 90 Hz and 5088×2544 at 75 Hz.
