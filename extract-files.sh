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
        patchelf --add-needed "libprotobuf-cpp-lite-v29.so" "${2}"
            ;;
        # Patch blobs to resolve movedlog symbol
        vendor/lib/libnvcamlog.so | vendor/lib/libnvmm_camera_v3.so | vendor/lib/libnvcamerahdr_v3.so | vendor/lib/egl/libEGL_tegra.so | vendor/lib/libglcore.so | vendor/lib/libnvgr.so | vendor/lib/libnvmm_utils.so | vendor/lib/libnvomxadaptor.so | vendor/lib/libnvomx.so | vendor/lib/libmplmpu.so)
        patchelf --add-needed "libutilscallstack.so" "${2}"
            ;;
        # Patch libglcore blob to resolve moved symbol
        vendor/lib/libglcore.so)
        patchelf --add-needed "libutilscallstack.so" "${2}"
            ;;
        # Patch nvomxadaptor blob to resolve moved symbol
        vendor/lib/libnvomxadaptor.so)
        patchelf --add-needed "libmedia_omx.so" "${2}"
            ;;
        # Patch DRM blob to resolve moved symbol
        vendor/lib/mediadrm/libwvdrmengine.so)
        patchelf --replace-needed "libprotobuf-cpp-lite.so" "libprotobuf-cpp-lite-v29.so" "${2}"
            ;;
        # Patch blobs to resolve intrinsics
        vendor/lib/egl/libEGL_tegra.so | vendor/lib/libcuda.so | vendor/lib/libglcore.so | vendor/lib/libnvglsi.so | vendor/lib/libnvrmapi_tegra.so | lib/libmplmpu.so )
        sed -i  s/libm.so/libw.so/g "${2}"
            ;;
    esac
}

# Initialize the helper
setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" false "${CLEAN_VENDOR}"

extract "${MY_DIR}/proprietary-files.txt" "${SRC}" "${KANG}" --section "${SECTION}"
extract "${MY_DIR}/proprietary-files_yellowstone.txt" "${SRC}" "${KANG}" --section "${SECTION}"

function patch_t124_intrinsics() {
  sed -i 's/__aeabi_ul2d/s_aeabi_ul2d/'         ~/lineage-18/vendor/google/yellowstone/proprietary/vendor/lib/egl/libEGL_tegra.so
  sed -i 's/__aeabi_ul2f/s_aeabi_ul2f/'         ~/lineage-18/vendor/google/yellowstone/proprietary/vendor/lib/egl/libEGL_tegra.so
  sed -i 's/__aeabi_uldivmod/s_aeabi_uldivmod/' ~/lineage-18/vendor/google/yellowstone/proprietary/vendor/lib/egl/libEGL_tegra.so

  sed -i 's/__aeabi_d2lz/s_aeabi_d2lz/'         ~/lineage-18/vendor/google/yellowstone/proprietary/vendor/lib/libcuda.so
  sed -i 's/__aeabi_d2ulz/s_aeabi_d2ulz/'       ~/lineage-18/vendor/google/yellowstone/proprietary/vendor/lib/libcuda.so
  sed -i 's/__aeabi_f2lz/s_aeabi_f2lz/'         ~/lineage-18/vendor/google/yellowstone/proprietary/vendor/lib/libcuda.so
  sed -i 's/__aeabi_f2ulz/s_aeabi_f2ulz/'       ~/lineage-18/vendor/google/yellowstone/proprietary/vendor/lib/libcuda.so
  sed -i 's/__aeabi_l2d/s_aeabi_l2d/'           ~/lineage-18/vendor/google/yellowstone/proprietary/vendor/lib/libcuda.so
  sed -i 's/__aeabi_ul2d/s_aeabi_ul2d/'         ~/lineage-18/vendor/google/yellowstone/proprietary/vendor/lib/libcuda.so
  sed -i 's/__aeabi_ul2f/s_aeabi_ul2f/'         ~/lineage-18/vendor/google/yellowstone/proprietary/vendor/lib/libcuda.so
  sed -i 's/__aeabi_ldivmod/s_aeabi_ldivmod/'   ~/lineage-18/vendor/google/yellowstone/proprietary/vendor/lib/libcuda.so
  sed -i 's/__aeabi_uldivmod/s_aeabi_uldivmod/' ~/lineage-18/vendor/google/yellowstone/proprietary/vendor/lib/libcuda.so

  sed -i 's/__aeabi_d2lz/s_aeabi_d2lz/'         ~/lineage-18/vendor/google/yellowstone/proprietary/vendor/lib/libglcore.so
  sed -i 's/__aeabi_d2ulz/s_aeabi_d2ulz/'       ~/lineage-18/vendor/google/yellowstone/proprietary/vendor/lib/libglcore.so
  sed -i 's/__aeabi_f2lz/s_aeabi_f2lz/'         ~/lineage-18/vendor/google/yellowstone/proprietary/vendor/lib/libglcore.so
  sed -i 's/__aeabi_f2ulz/s_aeabi_f2ulz/'       ~/lineage-18/vendor/google/yellowstone/proprietary/vendor/lib/libglcore.so
  sed -i 's/__aeabi_l2d/s_aeabi_l2d/'           ~/lineage-18/vendor/google/yellowstone/proprietary/vendor/lib/libglcore.so
  sed -i 's/__aeabi_ul2d/s_aeabi_ul2d/'         ~/lineage-18/vendor/google/yellowstone/proprietary/vendor/lib/libglcore.so
  sed -i 's/__aeabi_l2f/s_aeabi_l2f/'           ~/lineage-18/vendor/google/yellowstone/proprietary/vendor/lib/libglcore.so
  sed -i 's/__aeabi_ul2f/s_aeabi_ul2f/'         ~/lineage-18/vendor/google/yellowstone/proprietary/vendor/lib/libglcore.so
  sed -i 's/__aeabi_ldivmod/s_aeabi_ldivmod/'   ~/lineage-18/vendor/google/yellowstone/proprietary/vendor/lib/libglcore.so
  sed -i 's/__aeabi_uldivmod/s_aeabi_uldivmod/' ~/lineage-18/vendor/google/yellowstone/proprietary/vendor/lib/libglcore.so

  sed -i 's/__aeabi_uldivmod/s_aeabi_uldivmod/' ~/lineage-18/vendor/google/yellowstone/proprietary/vendor/lib/libnvglsi.so

  sed -i 's/__aeabi_uldivmod/s_aeabi_uldivmod/' ~/lineage-18/vendor/google/yellowstone/proprietary/vendor/lib/libnvrmapi_tegra.so

  sed -i 's/__aeabi_d2f/s_aeabi_d2f/'       ~/lineage-18/vendor/google/yellowstone/proprietary/lib/libmplmpu.so
  sed -i 's/__aeabi_d2iz/s_aeabi_d2iz/'     ~/lineage-18/vendor/google/yellowstone/proprietary/lib/libmplmpu.so
  sed -i 's/__aeabi_d2lz/s_aeabi_d2lz/'     ~/lineage-18/vendor/google/yellowstone/proprietary/lib/libmplmpu.so
  sed -i 's/__aeabi_dadd/s_aeabi_dadd/'     ~/lineage-18/vendor/google/yellowstone/proprietary/lib/libmplmpu.so
  sed -i 's/__aeabi_dcmpeq/s_aeabi_dcmpeq/' ~/lineage-18/vendor/google/yellowstone/proprietary/lib/libmplmpu.so
  sed -i 's/__aeabi_dcmpge/s_aeabi_dcmpge/' ~/lineage-18/vendor/google/yellowstone/proprietary/lib/libmplmpu.so
  sed -i 's/__aeabi_dcmpgt/s_aeabi_dcmpgt/' ~/lineage-18/vendor/google/yellowstone/proprietary/lib/libmplmpu.so
  sed -i 's/__aeabi_dcmple/s_aeabi_dcmple/' ~/lineage-18/vendor/google/yellowstone/proprietary/lib/libmplmpu.so
  sed -i 's/__aeabi_dcmplt/s_aeabi_dcmplt/' ~/lineage-18/vendor/google/yellowstone/proprietary/lib/libmplmpu.so
  sed -i 's/__aeabi_ddiv/s_aeabi_ddiv/'     ~/lineage-18/vendor/google/yellowstone/proprietary/lib/libmplmpu.so
  sed -i 's/__aeabi_dmul/s_aeabi_dmul/'     ~/lineage-18/vendor/google/yellowstone/proprietary/lib/libmplmpu.so
  sed -i 's/__aeabi_dsub/s_aeabi_dsub/'     ~/lineage-18/vendor/google/yellowstone/proprietary/lib/libmplmpu.so
  sed -i 's/__aeabi_f2d/s_aeabi_f2d/'       ~/lineage-18/vendor/google/yellowstone/proprietary/lib/libmplmpu.so
  sed -i 's/__aeabi_f2iz/s_aeabi_f2iz/'     ~/lineage-18/vendor/google/yellowstone/proprietary/lib/libmplmpu.so
  sed -i 's/__aeabi_f2lz/s_aeabi_f2lz/'     ~/lineage-18/vendor/google/yellowstone/proprietary/lib/libmplmpu.so
  sed -i 's/__aeabi_fadd/s_aeabi_fadd/'     ~/lineage-18/vendor/google/yellowstone/proprietary/lib/libmplmpu.so
  sed -i 's/__aeabi_fcmpeq/s_aeabi_fcmpeq/' ~/lineage-18/vendor/google/yellowstone/proprietary/lib/libmplmpu.so
  sed -i 's/__aeabi_fcmpge/s_aeabi_fcmpge/' ~/lineage-18/vendor/google/yellowstone/proprietary/lib/libmplmpu.so
  sed -i 's/__aeabi_fcmpgt/s_aeabi_fcmpgt/' ~/lineage-18/vendor/google/yellowstone/proprietary/lib/libmplmpu.so
  sed -i 's/__aeabi_fcmple/s_aeabi_fcmple/' ~/lineage-18/vendor/google/yellowstone/proprietary/lib/libmplmpu.so
  sed -i 's/__aeabi_fcmplt/s_aeabi_fcmplt/' ~/lineage-18/vendor/google/yellowstone/proprietary/lib/libmplmpu.so
  sed -i 's/__aeabi_fdiv/s_aeabi_fdiv/'     ~/lineage-18/vendor/google/yellowstone/proprietary/lib/libmplmpu.so
  sed -i 's/__aeabi_fmul/s_aeabi_fmul/'     ~/lineage-18/vendor/google/yellowstone/proprietary/lib/libmplmpu.so
  sed -i 's/__aeabi_fsub/s_aeabi_fsub/'     ~/lineage-18/vendor/google/yellowstone/proprietary/lib/libmplmpu.so
  sed -i 's/__aeabi_i2d/s_aeabi_i2d/'       ~/lineage-18/vendor/google/yellowstone/proprietary/lib/libmplmpu.so
  sed -i 's/__aeabi_i2f/s_aeabi_i2f/'       ~/lineage-18/vendor/google/yellowstone/proprietary/lib/libmplmpu.so
  sed -i 's/__aeabi_idiv/s_aeabi_idiv/'     ~/lineage-18/vendor/google/yellowstone/proprietary/lib/libmplmpu.so
  sed -i 's/__aeabi_l2d/s_aeabi_l2d/'       ~/lineage-18/vendor/google/yellowstone/proprietary/lib/libmplmpu.so
  sed -i 's/__aeabi_l2f/s_aeabi_l2f/'       ~/lineage-18/vendor/google/yellowstone/proprietary/lib/libmplmpu.so
  sed -i 's/__aeabi_ui2f/s_aeabi_ui2f/'     ~/lineage-18/vendor/google/yellowstone/proprietary/lib/libmplmpu.so

}

patch_t124_intrinsics;

"${MY_DIR}/setup-makefiles.sh"
