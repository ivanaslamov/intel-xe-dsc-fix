%global debug_package %{nil}
%global __os_install_post %{nil}
Name: bsb-xe-dsc
Version: 7.3.3
Release: 3.fc45
Summary: Intel Xe DSC rate-control fixes for the Bigscreen Beyond
License: MIT AND GPL-2.0-only
BuildArch: x86_64
Requires: kernel-modules(x86-64) = 7.3.3-ogc1.1.fc45

%description
Intel Xe module with two Display Stream Compression rate-control corrections
and automatic 8-bpp DSC for the Bigscreen Beyond EDID BIG:1234. Built for the
Bazzite OGC kernel 7.3.3-ogc1.1.fc45.x86_64.

%install
install -D -m 0644 "%{module_path}" "%{buildroot}/usr/lib/modules/7.3.3-ogc1.1.fc45.x86_64/kernel/drivers/gpu/drm/xe/xe.ko"

%files
/usr/lib/modules/7.3.3-ogc1.1.fc45.x86_64/kernel/drivers/gpu/drm/xe/xe.ko
