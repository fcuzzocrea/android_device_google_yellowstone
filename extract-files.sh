#!/bin/bash
#
# Copyright (C) 2016 The CyanogenMod Project
# Copyright (C) 2017-2020 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

DEVICE=yellowstone
VENDOR=google

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

ANDROID_ROOT="${MY_DIR}/../../.."

HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

KANG=
SECTION=

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        -n | --no-cleanup )
                CLEAN_VENDOR=false
                ;;
        -k | --kang )
                KANG="--kang"
                ;;
        -s | --section )
                SECTION="${2}"; shift
                CLEAN_VENDOR=false
                ;;
        * )
                SRC="${1}"
                ;;
    esac
    shift
done

if [ -z "${SRC}" ]; then
    SRC="adb"
fi

function blob_fixup() {
    case "${1}" in
        # Patch Tango blobs to resolve moved symbol
        lib/libtango_navigation_service.so | lib/libtango_service_library.so | libtango_ux_internal_support_library.so)
        "${PATCHELF}" --add-needed "libprotobuf-cpp-lite-v29.so" "${2}"
            ;;
        # Patch blobs to resolve movedlog symbol
        vendor/lib/libnvcamlog.so | vendor/lib/libnvmm_camera_v3.so | vendor/lib/libnvcamerahdr_v3.so | vendor/lib/egl/libEGL_tegra.so | vendor/lib/libglcore.so | vendor/lib/libnvgr.so | vendor/lib/libnvmm_utils.so | vendor/lib/libnvomxadaptor.so | vendor/lib/libnvomx.so | vendor/lib/libmplmpu.so)
        "${PATCHELF}" --add-needed "libutilscallstack.so" "${2}"
            ;;
        # Patch libglcore blob to resolve moved symbol
        vendor/lib/libglcore.so)
        "${PATCHELF}" --add-needed "libutilscallstack.so" "${2}"
            ;;
        # Patch nvomxadaptor blob to resolve moved symbol
        vendor/lib/libnvomxadaptor.so)
        "${PATCHELF}" --add-needed "libmedia_omx.so" "${2}"
            ;;
        # Patch DRM blob to resolve moved symbol
        vendor/lib/mediadrm/libwvdrmengine.so)
        "${PATCHELF}" --replace-needed "libprotobuf-cpp-lite.so" "libprotobuf-cpp-lite-v29.so" "${2}"
            ;;
    esac
}

# Initialize the helper
setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" false "${CLEAN_VENDOR}"

extract "${MY_DIR}/proprietary-files.txt" "${SRC}" "${KANG}" --section "${SECTION}"
extract "${MY_DIR}/proprietary-files_yellowstone.txt" "${SRC}" "${KANG}" --section "${SECTION}"

"${MY_DIR}/setup-makefiles.sh"
