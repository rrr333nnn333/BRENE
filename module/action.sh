#!/bin/bash
# shellcheck disable=SC2154
MODDIR=${0%/*}
KSU_BIN=/data/adb/ksud
KSU_MODULES_DIR=/data/adb/modules
SUSFS_BIN=/data/adb/ksu/bin/susfs
PERSISTENT_DIR=/data/adb/brene
DEST_BIN_DIR=/data/adb/ksu/bin
CUSTOM_ROM_NAMES="lineage|infinity|evolution|crdroid|mistos|axion|pixelos|rising|lunaris|halcyon|havoc|alphadroid|bliss|calyx|derpfest|graphene|lmodroid|lumine|matrixx|clover|yaap|aospa"

# Load utils
[[ -e "${MODDIR}/utils.sh" ]] && source "${MODDIR}/utils.sh"
# Load config
[[ -e "${PERSISTENT_DIR}/config.sh" ]] && source "${PERSISTENT_DIR}/config.sh"

echo "██████╗ ██████╗ ███████╗███╗   ██╗███████╗"
echo "██╔══██╗██╔══██╗██╔════╝████╗  ██║██╔════╝"
echo "██████╔╝██████╔╝█████╗  ██╔██╗ ██║█████╗  "
echo "██╔══██╗██╔══██╗██╔══╝  ██║╚██╗██║██╔══╝  "
echo "██████╔╝██║  ██║███████╗██║ ╚████║███████╗"
echo "╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝╚══════╝"
echo ""

echo "Soon"

# echo "- BRENE Version: $(grep "^version=" "${MODDIR}/module.prop" | cut -d'=' -f2)"
# echo "- SUSFS Version: $(${SUSFS_BIN} show version)"
# echo "- Device Model: $(resetprop ro.product.manufacturer) $(resetprop ro.product.model) $(resetprop ro.product.device)"
# echo "- Android Version: $(resetprop ro.build.version.release) (API $(resetprop ro.build.version.sdk)) | SDK $(resetprop ro.build.version.sdk)"
# echo "- Kernel Version: $(cat /proc/version | awk '{print $3}') | $(uname -r)"
# echo "- Custom ROM: $([[ -n "$(find /system -iname "*lineage*")" ]] && echo "Yes" || echo "No")"
# echo "- SUSFS Variant: $(${SUSFS_BIN} show variant)"
# echo "- ..5.u.S Status: $([[ -e /storage/emulated/0/..5.u.S ]] && echo "Abnormal" || echo "Normal")"
