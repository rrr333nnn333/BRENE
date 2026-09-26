#!/bin/bash
# shellcheck disable=SC2154
PATH=/data/adb/ksu/bin:$PATH
MODDIR=${0%/*}
KSU_BIN=/data/adb/ksud
KSU_MODULES_DIR=/data/adb/modules
SUSFS_BIN=/data/adb/ksu/bin/susfs
PERSISTENT_DIR=/data/adb/brene
DEST_BIN_DIR=/data/adb/ksu/bin

## brene_clone_perm <file/or/dir/perm/to/be/changed> <file/or/dir/to/clone/from>
brene_clone_perm() {
	# Always use busybox to maintain consistency
	TO=$1
	FROM=$2

	if [[ -z "${TO}" ]] || [[ -z "${FROM}" ]]; then
		return
	fi

	read -r permission owner group < <(busybox stat -c "%a %U %G" "${FROM}")

	busybox chmod "${permission}" "${TO}"
	busybox chown "${owner}":"${group}" "${TO}"
	busybox chcon --reference="${FROM}" "${TO}"
}

# susfs_list_full_file_access_for_third_party_apps() {
# 	local TARGET_PERMISSION="android.permission.MANAGE_EXTERNAL_STORAGE"
# 	pm list packages -3 | cut -d':' -f2 | while read -r PKGNAME; do
# 		if pm dump-package "${PKGNAME}" | grep -Eq "${TARGET_PERMISSION}"; then
# 			echo "susfs: package '${PKGNAME}' has '${TARGET_PERMISSION}' permission declared." | tee /dev/kmsg
# 		fi
# 	done
# }

resetprop_n() {
	resetprop -n "$1" "$2"
}

if_prop_exits_resetprop_n() {
	local PROP_NAME=$1
	local NEW_VALUE=$2
	local CURRENT_VALUE
	CURRENT_VALUE=$(resetprop "${PROP_NAME}")

	[[ -z "${CURRENT_VALUE}" ]] || [[ "${CURRENT_VALUE}" == "${NEW_VALUE}" ]] || resetprop_n "${PROP_NAME}" "${NEW_VALUE}"
}

# if_contains_resetprop_n() {
# 	local PROP_NAME=$1
#   local CONTAINS_VALUE=$2
#   local NEW_VALUE=$3

#   [[ "$(resetprop ${PROP_NAME})" = *"${CONTAINS_VALUE}"* ]] && resetprop -n "${PROP_NAME}" "${NEW_VALUE}"
# }

spoof_system_properties() {
	if_prop_exits_resetprop_n "ro.secure" "1"
	if_prop_exits_resetprop_n "ro.debuggable" "0"
	if_prop_exits_resetprop_n "ro.adb.secure" "1"
	if_prop_exits_resetprop_n "persist.sys.usb.config" "mtp"
	if_prop_exits_resetprop_n "ro.boot.verifiedbootstate" "green"
	if_prop_exits_resetprop_n "ro.boot.flash.locked" "1"
	if_prop_exits_resetprop_n "ro.boot.veritymode" "enforcing"
	if_prop_exits_resetprop_n "ro.boot.avb_version" "1.3"
	if_prop_exits_resetprop_n "ro.build.type" "user"
	if_prop_exits_resetprop_n "ro.build.tags" "release-keys"
	if_prop_exits_resetprop_n "ro.build.keys" "release-keys"
	if_prop_exits_resetprop_n "ro.crypto.state" "encrypted"
	if_prop_exits_resetprop_n "ro.allow.mock.location" "0"
	if_prop_exits_resetprop_n "ro.boot.warranty_bit" "0"
	if_prop_exits_resetprop_n "ro.warranty_bit" "0"
	if_prop_exits_resetprop_n "ro.force.debuggable" "0"
	if_prop_exits_resetprop_n "ro.secureboot.devicelock" "1"
	if_prop_exits_resetprop_n "ro.secureboot.lockstate" "locked"
	if_prop_exits_resetprop_n "ro.is_ever_orange" "0"
	if_prop_exits_resetprop_n "ro.bootmode" "normal"
	if_prop_exits_resetprop_n "vendor.boot.verifiedbootstate" "green"
	if_prop_exits_resetprop_n "ro.vendor.boot.warranty_bit" "0"
	if_prop_exits_resetprop_n "ro.vendor.warranty_bit" "0"
	if_prop_exits_resetprop_n "init.svc.adbd" "stopped"
	if_prop_exits_resetprop_n "init.svc_debug_pid.adbd" ""
	if_prop_exits_resetprop_n "ro.oem_unlock_supported" "0"

	# Realme
	if_prop_exits_resetprop_n "ro.boot.realme.lockstate" "1"
	if_prop_exits_resetprop_n "ro.boot.realmebootstate" "green"

	resetprop_n "ro.boot.vbmeta.size" "$(blockdev --getsize64 "/dev/block/by-name/vbmeta$(resetprop ro.boot.slot_suffix)")"
	resetprop_n "ro.boot.vbmeta.avb_version" "1.3"
	resetprop_n "ro.boot.vbmeta.hash_alg" "sha256"
	resetprop_n "ro.boot.vbmeta.device_state" "locked"
	resetprop_n "ro.boot.vbmeta.invalidate_on_error" "yes"
	resetprop_n "vendor.boot.vbmeta.device_state" "locked"

	## Delete some prop names for newer pixel device ##
	resetprop -d "ro.boot.verifiedbooterror"
	resetprop -d "ro.boot.verifyerrorpart"
	resetprop -d "vendor.boot.verifyerrorpart"
	resetprop -d "vendor.boot.verifiedbooterror"
	resetprop -d "crashrecovery.rescue_boot_count"

	resetprop -d "service.adb.root"
	resetprop -d "service.adb.tcp.port"

	# https://android.googlesource.com/platform/frameworks/base/+/bab174bf0883cbc5039a2860a1af706a56fe6ca0%5E%21/
	if [[ "$(resetprop ro.build.version.sdk)" -ge "36" ]]; then
		resetprop -d "sys.oem_unlock_allowed"
	else
		if_prop_exits_resetprop_n "sys.oem_unlock_allowed" "0"
	fi

	resetprop -c --force
}

spoof_fingerprint_properties() {
	fingerprint_value=$(resetprop ro.build.fingerprint)
	new_fingerprint_value="${fingerprint_value//userdebug/user}"
	new_fingerprint_value="${new_fingerprint_value//evolution/}"
	new_fingerprint_value="${new_fingerprint_value//crdroid/}"
	new_fingerprint_value="${new_fingerprint_value//lineage/}"
	if_prop_exits_resetprop_n "ro.bootimage.build.fingerprint" "${new_fingerprint_value}"
	if_prop_exits_resetprop_n "ro.build.fingerprint" "${new_fingerprint_value}"
	if_prop_exits_resetprop_n "ro.odm.build.fingerprint" "${new_fingerprint_value}"
	if_prop_exits_resetprop_n "ro.odm_dlkm.build.fingerprint" "${new_fingerprint_value}"
	if_prop_exits_resetprop_n "ro.product.build.fingerprint" "${new_fingerprint_value}"
	if_prop_exits_resetprop_n "ro.system.build.fingerprint" "${new_fingerprint_value}"
	if_prop_exits_resetprop_n "ro.system_dlkm.build.fingerprint" "${new_fingerprint_value}"
	if_prop_exits_resetprop_n "ro.system_ext.build.fingerprint" "${new_fingerprint_value}"
	if_prop_exits_resetprop_n "ro.vendor.build.fingerprint" "${new_fingerprint_value}"
	if_prop_exits_resetprop_n "ro.vendor_dlkm.build.fingerprint" "${new_fingerprint_value}"
}

spoof_utc_properties() {
	new_utc_value=$(resetprop ro.build.date.utc)
	if_prop_exits_resetprop_n "ro.bootimage.build.date.utc" "${new_utc_value}"
	if_prop_exits_resetprop_n "ro.build.date.utc" "${new_utc_value}"
	if_prop_exits_resetprop_n "ro.odm.build.date.utc" "${new_utc_value}"
	if_prop_exits_resetprop_n "ro.odm_dlkm.build.date.utc" "${new_utc_value}"
	if_prop_exits_resetprop_n "ro.product.build.date.utc" "${new_utc_value}"
	if_prop_exits_resetprop_n "ro.system.build.date.utc" "${new_utc_value}"
	if_prop_exits_resetprop_n "ro.system_dlkm.build.date.utc" "${new_utc_value}"
	if_prop_exits_resetprop_n "ro.system_ext.build.date.utc" "${new_utc_value}"
	if_prop_exits_resetprop_n "ro.vendor.build.date.utc" "${new_utc_value}"
	if_prop_exits_resetprop_n "ro.vendor_dlkm.build.date.utc" "${new_utc_value}"
	if_prop_exits_resetprop_n "persist.vendor.build.date.utc" "${new_utc_value}"
}

spoof_date_properties() {
	new_date_value=$(resetprop ro.build.date)
	if_prop_exits_resetprop_n "ro.bootimage.build.date" "${new_date_value}"
	if_prop_exits_resetprop_n "ro.build.date" "${new_date_value}"
	if_prop_exits_resetprop_n "ro.odm.build.date" "${new_date_value}"
	if_prop_exits_resetprop_n "ro.odm_dlkm.build.date" "${new_date_value}"
	if_prop_exits_resetprop_n "ro.product.build.date" "${new_date_value}"
	if_prop_exits_resetprop_n "ro.system.build.date" "${new_date_value}"
	if_prop_exits_resetprop_n "ro.system_dlkm.build.date" "${new_date_value}"
	if_prop_exits_resetprop_n "ro.system_ext.build.date" "${new_date_value}"
	if_prop_exits_resetprop_n "ro.vendor.build.date" "${new_date_value}"
	if_prop_exits_resetprop_n "ro.vendor_dlkm.build.date" "${new_date_value}"
}

spoof_os_security_patch_level_property() {
	if_prop_exits_resetprop_n "ro.build.version.security_patch" "${CURRENT_YEAR}-${CURRENT_MONTH}-01"
}

spoof_vendor_security_patch_level_property() {
	if_prop_exits_resetprop_n "ro.vendor.build.security_patch" "${CURRENT_YEAR}-${CURRENT_MONTH}-05"
}

update_config_date() {
	sed -i "s/^CURRENT_YEAR=.*/CURRENT_YEAR='$(date +%Y)'/" ${PERSISTENT_DIR}/config.sh
	sed -i "s/^CURRENT_MONTH=.*/CURRENT_MONTH='$(date +%m)'/" ${PERSISTENT_DIR}/config.sh
}

brene_sus_path() {
	if ${SUSFS_BIN} add_sus_path "$1" && [[ "${config_brene_logs}" == "1" ]]; then
		echo "[sus_path]: $1" >> "${PERSISTENT_DIR}/logs.txt"
	fi
}
brene_sus_path_loop() {
	if ${SUSFS_BIN} add_sus_path_loop "$1" && [[ "${config_brene_logs}" == "1" ]]; then
		echo "[sus_path_loop]: $1" >> "${PERSISTENT_DIR}/logs.txt"
	fi
}
brene_sus_map() {
	if ${SUSFS_BIN} add_sus_map "$1" && [[ "${config_brene_logs}" == "1" ]]; then
		echo "[sus_map]: $1" >> "${PERSISTENT_DIR}/logs.txt"
	fi
}
brene_set_uname() {
	if ${SUSFS_BIN} set_uname "$1" "$2" && [[ "${config_brene_logs}" == "1" ]]; then
		echo "[set_uname]: $1 $2" >> "${PERSISTENT_DIR}/logs.txt"
	fi
}
brene_kernel_umount() {
	${KSU_BIN} kernel notify-module-mounted
	${KSU_BIN} kernel umount add -f 2 "$1" 2> /dev/null
}
