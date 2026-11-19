#!/usr/bin/env bash
set -euo pipefail

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
kver=7.3.3-ogc1.1.fc45.x86_64
archive=${1:?Pass the verified OGC kernel source archive}
headers=${2:-/lib/modules/$kver/build}
rpmbuild=${RPMBUILD:-rpmbuild}
rpm_args=()
if [[ -n "${RPM_TOOLS_DIR:-}" ]]; then
  rpm_args=(--define "_rpmconfigdir $RPM_TOOLS_DIR"
            --define "__arch_install_post $RPM_TOOLS_DIR/check-buildroot")
fi
jobs=${JOBS:-6}
[[ "$jobs" =~ ^[1-9][0-9]*$ ]]
printf '8cadd5a5633be81982c48c9d8c8ca6ede034b322c018b99a66e5c0166aed3ce8  %s\n' "$archive" | sha256sum --check
test "$(cat "$headers/include/config/kernel.release")" = "$kver"
test -s "$headers/Module.symvers"

build=$(mktemp -d /var/tmp/bsb-xe-native75-lab.XXXXXXXX)
printf 'Build directory: %s\n' "$build"
mkdir "$build/kbuild" "$build/assets"
cp -a "$headers/." "$build/kbuild/"
tar -xzf "$archive" --strip-components=1 -C "$build/kbuild" --wildcards '*/drivers/gpu/drm/*'
cd "$build/kbuild"
patches=("$repo/intel-xe-dsc-rc.patch" "$repo/beyond-fixed-dsc.patch"
         "$repo/beyond-non-desktop.patch" "$repo/experiments/beyond-native75-lab.patch")
# Apply separately: the lab patch's context includes the three existing fixes.
for patch in "${patches[@]}"; do
  git apply --check "$patch"
  git apply "$patch"
done
make -j"$jobs" M=drivers/gpu/drm/xe modules
objcopy --strip-debug drivers/gpu/drm/xe/xe.ko "$build/xe.ko"
test "$(modinfo -F vermagic "$build/xe.ko" | cut -d ' ' -f1)" = "$kver"
modinfo -p "$build/xe.ko" | grep '^beyond_dsc_test:'
"$rpmbuild" -bb "${rpm_args[@]}" --define "_topdir $build/rpm" \
  --define "module_path $build/xe.ko" --define 'patch_release 8.lab1' \
  --define 'patch_summary experimental native75 geometry and legacy DSC 1.1 RC comparison' \
  "$repo/packaging/bsb-xe-dsc.spec"
pkg="$build/rpm/RPMS/x86_64/bsb-xe-dsc-7.3.3-8.lab1.fc45.x86_64.rpm"
rpm -K --nosignature "$pkg"
cp "$pkg" "$build/assets/"
readelf -n "$build/xe.ko" > "$build/assets/build-id.txt"
sha256sum "${patches[@]}" > "$build/assets/patch-checksums.txt"
cd "$build/assets"
sha256sum -- *.rpm > SHA256SUMS
printf 'Artifacts: %s\n' "$PWD"
