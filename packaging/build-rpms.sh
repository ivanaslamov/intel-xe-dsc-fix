#!/usr/bin/env bash
set -euo pipefail

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
kver=7.3.3-ogc1.1.fc45.x86_64
archive=${1:?Pass the OGC kernel source archive path}
headers=${2:-/lib/modules/$kver/build}
rpmbuild=${RPMBUILD:-rpmbuild}

printf '8cadd5a5633be81982c48c9d8c8ca6ede034b322c018b99a66e5c0166aed3ce8  %s\n' "$archive" |
  sha256sum --check
test "$(cat "$headers/include/config/kernel.release")" = "$kver"
test -s "$headers/Module.symvers"

build=$(mktemp -d)
printf 'Build directory: %s\n' "$build"
mkdir "$build/base" "$build/assets"
cp -a "$headers/." "$build/base/"
tar -xzf "$archive" --strip-components=1 -C "$build/base" --wildcards '*/drivers/gpu/drm/*'

for variant in dsc-rate-control automatic-8bpp-dsc non-desktop combined; do
  case "$variant" in
    dsc-rate-control)
      release=2
      summary='DSC rate-control corrections'
      patches=(intel-xe-dsc-rc.patch)
      ;;
    automatic-8bpp-dsc)
      release=5
      summary='automatic 8-bpp DSC for BIG:1234'
      patches=(beyond-fixed-dsc.patch)
      ;;
    non-desktop)
      release=6
      summary='non-desktop display detection for BIG:5095'
      patches=(beyond-non-desktop.patch)
      ;;
    combined)
      release=4
      summary='DSC rate control, automatic 8-bpp DSC, and VR display detection'
      patches=(intel-xe-dsc-rc.patch beyond-fixed-dsc.patch beyond-non-desktop.patch)
      ;;
  esac

  printf 'Building %s (%s.fc45)\n' "$variant" "$release"
  kbuild="$build/$variant"
  cp -a --reflink=auto "$build/base" "$kbuild"
  (
    cd "$kbuild"
    patch_paths=("${patches[@]/#/$repo/}")
    git apply --check "${patch_paths[@]}"
    git apply "${patch_paths[@]}"
    make -j"$(nproc)" M=drivers/gpu/drm/xe modules
  )

  module="$kbuild/xe.ko"
  objcopy --strip-debug "$kbuild/drivers/gpu/drm/xe/xe.ko" "$module"
  vermagic=$(modinfo -F vermagic "$module")
  test "${vermagic%% *}" = "$kver"

  "$rpmbuild" -bb --define "_topdir $build/rpm-$variant" \
    --define "module_path $module" --define "patch_release $release" \
    --define "patch_summary $summary" "$repo/packaging/bsb-xe-dsc.spec"
  pkg="$build/rpm-$variant/RPMS/x86_64/bsb-xe-dsc-7.3.3-$release.fc45.x86_64.rpm"
  rpm -K --nosignature "$pkg"
  install -m 0644 "$pkg" "$build/assets/bsb-xe-$variant-7.3.3-$release.fc45.x86_64.rpm"
done

cd "$build/assets"
sha256sum -- *.rpm > SHA256SUMS
printf 'RPMs and checksums are in %s\n' "$PWD"
