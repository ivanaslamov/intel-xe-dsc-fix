# Intel Xe DSC fix for Bigscreen Beyond 2

This patch corrects two Display Stream Compression (DSC) rate-control calculations in `intel_vdsc.c`, which Intel Xe and i915 share.

- **RGB quantization parameter table.** Count both half-bit steps per integer bit so 8 compressed bits per pixel selects column 4, the 8-bpp column.
- **Bits-per-group offset.** Use a positive interval width and signed rounding to the nearest integer so interpolation reaches the correct endpoints.

On Bazzite 45 (`7.3.3-ogc1.1.fc45.x86_64`), an MSI Claw 8 AI+ with the patched Xe module still showed colored static on the Bigscreen Beyond 2e while the headset link ran with DSC disabled. With the same module loaded, [forcing DSC and capping the link at 8 bpp](#enable-8-bpp-dsc-for-the-headset) produced a clear image in both eyes at 3840×1920, 90 Hz. The driver reported 8.0000 compressed bpp, 8 bits per color component, and four DSC slices.

An earlier Linux 6.16.4-based build (`6.16.4-119.bsb2.fc42.x86_64`) also produced a clear image. That test build used a headset-specific 8-bpp mode-selection quirk and an Intel DSS clock-gating backport. Both arithmetic changes were tested together. [Intel Xe bug report #9247](https://gitlab.freedesktop.org/drm/xe/kernel/-/work_items/9247)

## Apply the patch to kernel source

From the root of a kernel source tree, point `git apply` at the patch in this repository. The patch applies to OGC tag `v7.3.3-ogc1` at commit `a66e9e735fa99a7844fe18b0af0651737589f61a`. [OGC source](https://github.com/OpenGamingCollective/linux/tree/a66e9e735fa99a7844fe18b0af0651737589f61a)

```bash
git apply --check /path/to/intel-xe-dsc-fix/intel-xe-dsc-rc.patch &&
  git apply /path/to/intel-xe-dsc-fix/intel-xe-dsc-rc.patch
```

## Build an Xe-only test RPM on Bazzite 45

Run these commands in Bash from the root of this repository on a machine booted into `7.3.3-ogc1.1.fc45.x86_64`. You need the matching `kernel-devel` package, the kernel's build toolchain, and `curl`, `git`, `tar`, `make`, `binutils`, and `rpmbuild`. The module is built against the running kernel's configuration and exported symbols. [Kernel build documentation](https://docs.kernel.org/kbuild/modules.html)

```bash
set -euo pipefail
repo=$PWD
kver=7.3.3-ogc1.1.fc45.x86_64
test "$(uname -r)" = "$kver"
test -r "/lib/modules/$kver/build/Module.symvers"
command -v rpmbuild

build=$(mktemp -d)
mkdir -p "$build/kbuild" "$build/rpmbuild"
cp -a "/lib/modules/$kver/build/." "$build/kbuild/"

commit=a66e9e735fa99a7844fe18b0af0651737589f61a
curl -fL --retry 2 -o "$build/ogc-linux.tar.gz" \
  "https://codeload.github.com/OpenGamingCollective/linux/tar.gz/$commit"
tar -xzf "$build/ogc-linux.tar.gz" --strip-components=1 \
  -C "$build/kbuild" --wildcards '*/drivers/gpu/drm/*'

cd "$build/kbuild"
git apply --check "$repo/intel-xe-dsc-rc.patch"
git apply "$repo/intel-xe-dsc-rc.patch"
make -j"$(nproc)" M=drivers/gpu/drm/xe modules
objcopy --strip-debug drivers/gpu/drm/xe/xe.ko "$build/xe.ko"

stock=$(modinfo -n xe)
test "$(readlink -f "$stock")" = "/usr/lib/modules/$kver/kernel/drivers/gpu/drm/xe/xe.ko"
for field in vermagic depends; do
  test "$(modinfo -F "$field" "$build/xe.ko")" = "$(modinfo -F "$field" "$stock")"
done
diff -u <(modinfo -F alias "$stock" | sort) <(modinfo -F alias "$build/xe.ko" | sort)

rpmbuild -bb --define "_topdir $build/rpmbuild" \
  --define "module_path $build/xe.ko" "$repo/packaging/bsb-xe-dsc.spec"
pkg="$build/rpmbuild/RPMS/x86_64/bsb-xe-dsc-7.3.3-2.fc45.x86_64.rpm"
rpm -K --nosignature "$pkg"
printf 'Test RPM: %s\n' "$pkg"
```

## Stage and verify the test deployment

Check `rpm-ostree status` before staging. These steps require `jq` and assume the stock deployment is booted, there is no other pending deployment, and local initramfs regeneration is disabled. The build produces an unsigned module. Use a trusted module signature if the system enforces signatures. The RPM is tied to the exact kernel package version. [rpm-ostree file overrides and initramfs](https://coreos.github.io/rpm-ostree/administrator-handbook/#override-rpm-files)

Keep using the Bash session from the build section so `$pkg`, `$kver` and `$build` are available. Save your work before rebooting.

```bash
sudo ostree admin pin booted
sudo rpm-ostree install --force-replacefiles "$pkg"
sudo rpm-ostree initramfs --enable --arg=--add-drivers --arg=xe --arg=--nostrip

staged=$(rpm-ostree status --json | jq -er \
  '.deployments[] | select(.staged) | "/sysroot/ostree/deploy/\(.osname)/deploy/\(.checksum).\(.serial)"')
xe="usr/lib/modules/$kver/kernel/drivers/gpu/drm/xe/xe.ko"
image="$staged/usr/lib/modules/$kver/initramfs.img"

sudo cmp "$build/xe.ko" "$staged/$xe"
sudo lsinitrd -f "$xe" "$image" | cmp "$build/xe.ko" -
```

Reboot with `sudo reboot` once both comparisons pass. On the tested Bazzite build, you can compare the loaded module's build ID with the one on disk. The two IDs should match.

```bash
od -An -tx1 -j16 -N20 /sys/module/xe/notes/.note.gnu.build-id | tr -d ' \n'
printf '\n'
readelf -n "$(modinfo -n xe)" | grep 'Build ID:'
```

## Enable 8-bpp DSC for the headset

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

The patch follows the MIT license of `intel_vdsc.c`. The [license file](LICENSE) preserves the upstream Intel copyright notice. The Xe module built from the kernel tree is subject to that tree's applicable licenses. [Linux kernel licensing rules](https://docs.kernel.org/process/license-rules.html)
