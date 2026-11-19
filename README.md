# Intel Xe DSC fix for Bigscreen Beyond 2

This project provides patches for the Intel display code shared by Xe and i915. The rate-control patch corrects two Display Stream Compression (DSC) calculations in `intel_vdsc.c`.

- **RGB quantization parameter table.** Count both half-bit steps per integer bit so 8 compressed bits per pixel selects column 4, the 8-bpp column.
- **Bits-per-group offset.** Use a positive interval width and signed rounding to the nearest integer so interpolation reaches the correct endpoints.

On Bazzite 45 (`7.3.3-ogc1.1.fc45.x86_64`), an MSI Claw 8 AI+ with the arithmetic fixes still showed colored static on the Bigscreen Beyond 2e while the headset link ran with DSC disabled. With the same module loaded, [forcing DSC and capping the link at 8 bpp](#manually-enable-8-bpp-dsc-for-the-headset) produced a clear image in both eyes at 3840×1920, 90 Hz. The driver reported 8.0000 compressed bpp, 8 bits per color component, and four DSC slices.

The automatic DSC patch adds that mode selection to `intel_dp.c`. It matches the Beyond's `BIG:1234` EDID on a single-stream DisplayPort connection and selects 8-bpp DSC during the modeset, subject to the normal link checks.

The native 75 Hz patch, [`beyond-native75-short-slices.patch`](beyond-native75-short-slices.patch), selects 12-line DSC slices for the Beyond's 5088×2544 four-slice mode. Together with the existing fixes, it produces a clear image in both eyes at native 75 Hz while preserving the working 90 Hz mode.

The non-desktop patch marks the Beyond's `BIG:5095` EDID as `non-desktop` when the Intel DisplayPort driver detects it at boot or on reconnect. KDE can then offer the connector for a DRM lease to a VR app such as Lobby. [KDE DRM lease code](https://github.com/KDE/kwin/blob/master/src/wayland/drmlease_v1.cpp#L79-L87)

An earlier Linux 6.16.4-based build (`6.16.4-119.bsb2.fc42.x86_64`) also produced a clear image. That test build used a headset-specific 8-bpp mode-selection quirk and an Intel DSS clock-gating backport. Both arithmetic changes were tested together. [Intel Xe bug report #9247](https://gitlab.freedesktop.org/drm/xe/kernel/-/work_items/9247)

## Native 75 Hz fix found on November 18, 2026

[`beyond-native75-short-slices.patch`](beyond-native75-short-slices.patch) selects
**four 1272×12 DSC slices** for the `BIG:1234` headset's 5088×2544 mode. The user
confirmed a clear image across both eyes, including the bottom, at 75 Hz on the
MSI Claw 8 AI+. A dense 8-pixel checkerboard also remained clear after switching
to 90 Hz and back. The 90 Hz mode remained clear. The separate final `9.fc45`
build was then installed and verified after reboot:
75 Hz was fully clear in both eyes with no diagnostic overrides, and 90 Hz
remained clear. The headset was left displaying the 75 Hz checkerboard.

The patch changes only slice height for this EDID, native resolution, and
four-slice configuration. Standard Intel rate-control calculations, including
the existing arithmetic corrections, derive the dependent values. Each slice
contains 15,264 pixels, exceeding Intel's 15,000-pixel minimum, and 12 divides
2544 exactly. The final patch has no runtime experiment controls.

The older 106- and 212-line native slices produced corruption. Changing to the
legacy DSC 1.1 RC table alone did not fix it; neither did HBR2 or joined pipes.
The precise underlying encoder/decoder incompatibility remains unidentified.
This is a hardware-tested compatibility quirk for this headset and kernel,
not evidence that all Intel DSC outputs require shorter slices.

Apply this patch **after the three original patches**, without the old
`beyond-native75-test.patch` / eight-slice experiment patches. The `native75`
build variant packages those four patches as `bsb-xe-dsc 7.3.3-9.fc45`:

```sh
JOBS=6 bash packaging/build-rpms.sh /path/to/ogc-linux-7.3.3-ogc1.tar.gz \
  /lib/modules/7.3.3-ogc1.1.fc45.x86_64/build native75
```

The native75 release packages the exact RPM verified on the Claw, alongside
the four unchanged RPMs from the previous release for comparison. See the
[release notes](releases/bazzite-45-7.3.3-ogc1.1-native75.md) and
[GitHub releases](https://github.com/ivanaslamov/intel-xe-dsc-fix/releases)
for availability. Use the staged-module/initramfs verification and rollback
procedure below. The experiment matrix and exact build receipt are in
[`experiments/README.md`](experiments/README.md).

## Choose a Bazzite RPM

Choose **native75** (`9.fc45`) for the tested 75 Hz and 90 Hz fix on Bazzite 45 kernel `7.3.3-ogc1.1.fc45.x86_64`. It contains all four patches. The older **combined** RPM (`4.fc45`) contains the three original patches and does not include the native 75 Hz fix. Each standalone RPM applies one patch to the stock Xe module, which lets you test that change independently. All five RPMs replace the same `xe.ko` and use the package name `bsb-xe-dsc`. Install one at a time. Choose by patch name. [Release downloads](https://github.com/ivanaslamov/intel-xe-dsc-fix/releases)

| Standalone RPM | Patch | What it changes |
| --- | --- | --- |
| DSC rate control (`2.fc45`) | [`intel-xe-dsc-rc.patch`](intel-xe-dsc-rc.patch) | Corrects DSC rate-control arithmetic. For `BIG:1234`, use the [manual 8-bpp DSC override](#manually-enable-8-bpp-dsc-for-the-headset). |
| Automatic 8-bpp DSC (`5.fc45`) | [`beyond-fixed-dsc.patch`](beyond-fixed-dsc.patch) | Selects 8-bpp DSC for `BIG:1234` using the stock kernel's rate-control arithmetic. |
| Non-desktop detection (`6.fc45`) | [`beyond-non-desktop.patch`](beyond-non-desktop.patch) | Enables headset detection for DRM leasing on `BIG:5095` using the stock kernel's DSC behavior. |

## Apply the patches to kernel source

From the root of a kernel source tree, point `git apply` at the patches in this repository. Apply one patch to test an individual change, or use all four below for the native 75 Hz build. The patches apply to OGC tag `v7.3.3-ogc1` at commit `a66e9e735fa99a7844fe18b0af0651737589f61a`. [OGC source](https://github.com/OpenGamingCollective/linux/tree/a66e9e735fa99a7844fe18b0af0651737589f61a)

```bash
repo=/path/to/intel-xe-dsc-fix
patches=(
  "$repo/intel-xe-dsc-rc.patch"
  "$repo/beyond-fixed-dsc.patch"
  "$repo/beyond-non-desktop.patch"
  "$repo/beyond-native75-short-slices.patch"
)
for patch in "${patches[@]}"; do
  git apply --check "$patch" && git apply "$patch" || break
done
```

## Build the Xe-only RPMs on Bazzite 45

Run these commands from the root of this repository on x86_64 Fedora or Bazzite. Use the matching `kernel-devel-7.3.3-ogc1.1.fc45.x86_64` build tree, GCC 16.2.1, binutils 2.47, Git, Make, `modinfo`, and `rpm-build`. The script verifies the source archive and builds each variant from a fresh copy of the same kernel source and headers. [OGC kernel packages](https://github.com/OpenGamingCollective/kernel-packages/pkgs/container/kernel-packages-fedora)

```bash
bash packaging/build-rpms.sh /absolute/path/to/ogc-linux-7.3.3-ogc1.tar.gz
```

By default this builds the four original variants plus `native75` (`9.fc45`),
which includes all four patches. To build only the verified 75 Hz variant:

```sh
JOBS=6 bash packaging/build-rpms.sh /absolute/path/to/ogc-linux-7.3.3-ogc1.tar.gz \
  /lib/modules/7.3.3-ogc1.1.fc45.x86_64/build native75
```

Use `bsb-xe-native75-7.3.3-9.fc45.x86_64.rpm` from the printed output directory
for the 75 Hz fix. The original `combined` (`4.fc45`) variant contains only the
three older patches.

Download the OGC source archive from the release, or fetch the same source from the OGC commit above. Pass the matching kernel-devel build directory as a second argument if it lives outside `/lib/modules/7.3.3-ogc1.1.fc45.x86_64/build`. The script prints the output directory. Build paths and timestamps can affect build IDs and checksums.

## Stage and verify the test deployment

Check `rpm-ostree status` before staging. These steps require Bash, `jq`, `rpm2cpio`, and `cpio`, and assume there is no other pending deployment. The RPM is tied to the exact kernel package version. The module is unsigned. Use a trusted module signature if your system enforces signatures. [rpm-ostree file overrides and initramfs](https://coreos.github.io/rpm-ostree/administrator-handbook/#override-rpm-files)

Set `pkg` to the absolute path of your chosen RPM. This example uses the native75 download. Verify the file against `SHA256SUMS` from the release or your build output. Use the same Bash session for the remaining commands.

```bash
kver=7.3.3-ogc1.1.fc45.x86_64
test "$(uname -r)" = "$kver"
pkg="$HOME/Downloads/bsb-xe-native75-7.3.3-9.fc45.x86_64.rpm"
sha256sum "$pkg"
```

For a first install from stock with local initramfs regeneration disabled, run the following.

```bash
sudo ostree admin pin booted
sudo rpm-ostree install --force-replacefiles "$pkg"
sudo rpm-ostree initramfs --enable --arg=--add-drivers --arg=xe --arg=--nostrip
```

If a `bsb-xe-dsc` RPM is already layered, keep the pinned stock deployment and switch builds in one transaction. Keep the existing local initramfs settings from the earlier install.

```bash
sudo rpm-ostree install --uninstall=bsb-xe-dsc --force-replacefiles "$pkg"
```

Verify the staged module and boot image before rebooting for either a first install or an upgrade.

```bash
set -o pipefail
staged=$(rpm-ostree status --json | jq -er \
  '.deployments[] | select(.staged) | "/sysroot/ostree/deploy/\(.osname)/deploy/\(.checksum).\(.serial)"')
xe="usr/lib/modules/$kver/kernel/drivers/gpu/drm/xe/xe.ko"
image="$staged/usr/lib/modules/$kver/initramfs.img"
module=$(mktemp)

if rpm2cpio "$pkg" | cpio -i --quiet --to-stdout "./$xe" > "$module" &&
  test -s "$module" &&
  sudo cmp "$module" "$staged/$xe" &&
  sudo lsinitrd -f "$xe" "$image" | cmp "$module" -; then
  printf 'The staged module and initramfs match the RPM.\n'
else
  printf 'Verification failed. Discard the pending deployment before rebooting.\n' >&2
fi
rm "$module"
```

Reboot with `sudo reboot` once verification passes. On the tested Bazzite build, you can compare the loaded module's build ID with the one on disk. The two IDs should match.

```bash
od -An -tx1 -j16 -N20 /sys/module/xe/notes/.note.gnu.build-id | tr -d ' \n'
printf '\n'
readelf -n "$(modinfo -n xe)" | grep 'Build ID:'
```

## Check headset detection and automatic DSC

After rebooting into the native75 RPM, connect the headset and start the VR app. You can also use the relevant check below with the older combined or standalone RPMs. For `BIG:5095`, verify that Lobby can acquire a DRM lease. If `drm_info` is available, check that the headset's DisplayPort connector has `non-desktop=1`.

For `BIG:1234`, start a 90 Hz scene, check both eyes, and read the Intel display state.

```bash
sudo cat /sys/kernel/debug/dri/0000:00:02.0/i915_display_info
```

Look for `compressed-bpp:8.0000` in the active 3840×1920, 90 Hz display pipeline whose encoder lists the headset's DisplayPort connector. The Claw's internal `eDP-1` panel can also report 8-bpp DSC. The connector check in the next section identifies the headset's port.

With the native75 RPM, also test 5088×2544 at 75 Hz. Confirm a clear image
throughout both eyes and four 1272×12 DSC slices at 8 compressed bpp. Switch
back to 90 Hz to check that mode as well. A successful modeset or a correct
framebuffer capture alone cannot establish that the headset decodes the image
correctly; the optical check is necessary.

<a id="enable-8-bpp-dsc-for-the-headset"></a>

## Manually enable 8-bpp DSC for the headset

Use these steps with the standalone DSC rate-control RPM or to diagnose a link configuration problem.

Connect and power the headset. The tested Beyond 2e has EDID vendor `BIG`, product `0x1234` (`09 27 34 12` in the command below). The following command lists its connected DisplayPort connector. Use the name it prints in the next block. [Intel link-bpp control](https://github.com/OpenGamingCollective/linux/blob/v7.3.3-ogc1/drivers/gpu/drm/i915/display/intel_link_bw.c)

```bash
for path in /sys/class/drm/card*-DP-*; do
  [ -r "$path/status" ] && [ "$(cat "$path/status")" = connected ] || continue
  [ "$(od -An -tx1 -j8 -N4 "$path/edid" | tr -d ' \n')" = 09273412 ] || continue
  printf '%s\n' "${path##*/}"
done
```

Set the link cap and force DSC on that connector. Replace `card0-DP-1` if the command printed a different connector. This uses the two Intel debugfs controls available on the tested kernel.

```bash
device=card0-DP-1
card=${device%%-*}
port=${device#*-}
debug="/sys/kernel/debug/dri/${card#card}"
connector="$debug/$port"

test "$(cat "/sys/class/drm/$device/status")" = connected &&
  test "$(od -An -tx1 -j8 -N4 "/sys/class/drm/$device/edid" | tr -d ' \n')" = 09273412 &&
  printf '8\n' | sudo tee "$connector/intel_force_link_bpp" &&
  printf '1\n' | sudo tee "$connector/i915_dsc_fec_support"
```

Fully close and relaunch SteamVR or the VR session to apply the settings on the next modeset. With the headset displaying the 90 Hz scene, check both eyes and read the active display state.

```bash
sudo cat "$connector/i915_dsc_fec_support"
sudo cat "$debug/i915_display_info"
```

Look for `DSC_Enabled: yes` and `compressed-bpp:8.0000` in the display pipeline for the selected DisplayPort connector at 3840×1920, 90 Hz. The Claw's internal `eDP-1` panel can also report 8-bpp DSC, so match the connector in the display dump.

The override resets on reboot. Reapply it before starting VR. To clear it during the current boot, run the following and restart the VR session.

```bash
printf '0\n' | sudo tee "$connector/i915_dsc_fec_support"
printf '0\n' | sudo tee "$connector/intel_force_link_bpp"
```

## Roll back the Xe module

If either pre-reboot comparison fails, use `sudo rpm-ostree cleanup -p` to discard this pending test deployment. If the test fails after reboot, select the pinned stock deployment in GRUB. To remove the layer while booted into the test deployment, run `sudo rpm-ostree uninstall bsb-xe-dsc` and `sudo rpm-ostree initramfs --disable`, then reboot into the resulting deployment. [Bazzite rollback guide](https://docs.bazzite.gg/Installing_and_Managing_Software/Updates_Rollbacks_and_Rebasing/rolling_back_system_updates/)

## License

The patches follow the MIT licenses of `intel_vdsc.c` and `intel_dp.c`. The [license file](LICENSE) preserves the upstream Intel copyright notices. The Xe module built from the kernel tree is subject to that tree's applicable licenses. [Linux kernel licensing rules](https://docs.kernel.org/process/license-rules.html)
