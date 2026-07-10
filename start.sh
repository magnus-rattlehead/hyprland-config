#!/bin/sh
cd ~
export AQ_DRM_DEVICES=/dev/dri/card0
export WLR_DRM_DEVICES=/dev/dri/card0
export __EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/50_mesa.json
export VK_DRIVER_FILES=/usr/share/vulkan/icd.d/intel_icd.x86_64.json
dbus-run-session start-hyprland
