Three experimental x86_64 Xe module RPMs for Bazzite 45 kernel **`7.3.3-ogc1.1.fc45.x86_64`**. Choose one RPM.

| RPM release | Changes | Source |
| --- | --- | --- |
| `2.fc45` | DSC rate-control arithmetic fixes. Use the manual 8-bpp DSC override for `BIG:1234`. | [6e2e137](https://github.com/ivanaslamov/intel-xe-dsc-fix/tree/6e2e13774aadb2b0650d942de8e85a1d117f622e) |
| `3.fc45` | Adds automatic 8-bpp DSC selection for `BIG:1234`. | [63a4961](https://github.com/ivanaslamov/intel-xe-dsc-fix/tree/63a4961d8ce4c6562203c79e109553d1498f40d6) |
| `4.fc45` | Adds `non-desktop` detection for `BIG:5095` so the VR app can request a DRM lease. Includes the earlier DSC changes. | [a661c9c](https://github.com/ivanaslamov/intel-xe-dsc-fix/tree/a661c9c9bd87c7ebd493c02c86dc3500fe18455f) |

All three release assets were rebuilt and checked against the matching kernel headers and verified to contain the intended module. The arithmetic fixes and manual override produced a clear 3840×1920, 90 Hz image on an MSI Claw 8 AI+. These rebuilds were checked at build time.

Use the [Bazzite installation and rollback instructions](https://github.com/ivanaslamov/intel-xe-dsc-fix/blob/a661c9c9bd87c7ebd493c02c86dc3500fe18455f/README.md#stage-and-verify-the-test-deployment). Set `pkg` to the downloaded RPM's absolute path. The modules are unsigned. Check the running kernel with `uname -r` and verify the download against `SHA256SUMS`.

The source assets include the [OGC kernel source](https://github.com/OpenGamingCollective/linux/tree/a66e9e735fa99a7844fe18b0af0651737589f61a), the three sets of patches and RPM specs, the kernel configuration, and build instructions.
