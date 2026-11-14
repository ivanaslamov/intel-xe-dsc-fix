%global debug_package %{nil}
%global __os_install_post %{nil}
%{!?patch_release:%global patch_release 4}
%{!?patch_summary:%global patch_summary DSC rate control, automatic 8-bpp DSC, and VR display detection}
Name: bsb-xe-dsc
Version: 7.3.3
Release: %{patch_release}.fc45
Summary: Intel Xe for Bigscreen Beyond with %{patch_summary}
License: MIT AND GPL-2.0-only
BuildArch: x86_64
Requires: kernel-modules(x86-64) = 7.3.3-ogc1.1.fc45

%description
Intel Xe module for the Bazzite OGC kernel 7.3.3-ogc1.1.fc45.x86_64.
This build includes %{patch_summary}.

%install
install -D -m 0644 "%{module_path}" "%{buildroot}/usr/lib/modules/7.3.3-ogc1.1.fc45.x86_64/kernel/drivers/gpu/drm/xe/xe.ko"

%files
/usr/lib/modules/7.3.3-ogc1.1.fc45.x86_64/kernel/drivers/gpu/drm/xe/xe.ko
