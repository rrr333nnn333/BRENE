#!/bin/bash
PATH=/data/adb/ksu/bin:$PATH
MODDIR=${0%/*}
KSU_BIN=/data/adb/ksud
KSU_MODULES_DIR=/data/adb/modules
SUSFS_BIN=/data/adb/ksu/bin/susfs
PERSISTENT_DIR=/data/adb/brene
DEST_BIN_DIR=/data/adb/ksu/bin

## susfs_clone_perm <file/or/dir/perm/to/be/changed> <file/or/dir/to/clone/from>
# susfs_clone_perm() {
# 	TO=$1
# 	FROM=$2
# 	if [[ -z "${TO}" -o -z "${FROM}" ]]; then
# 		return
# 	fi
# 	## stat https://github.com/backslashxx/bindhosts/commit/427f18fe0b212ef2754e79c8aaaa72cb59ad253d#diff-8cb0da3b1680ce3a9f3263622042aa6f0250431fa5069513664650a17c48fdabR15
# 	CLONED_PERM_STRING=$(stat -c "%a %U %G" "${FROM}")
# 	set "${CLONED_PERM_STRING}"
# 	chmod "$1" "${TO}"
# 	chown "$2":"$3" "${TO}"
# 	busybox chcon --reference="${FROM}" "${TO}"
# }

susfs_list_full_file_access_for_third_party_apps() {
	local TARGET_PERMISSION="android.permission.MANAGE_EXTERNAL_STORAGE"
	pm list packages -3 | cut -d':' -f2 | while read -r PKGNAME; do
		if pm dump-package "${PKGNAME}" | grep -Eq "${TARGET_PERMISSION}"; then
			echo "susfs: package '${PKGNAME}' has '${TARGET_PERMISSION}' permission declared." | tee /dev/kmsg
		fi
	done
}

resetprop_n() {
	resetprop -n "$1" "$2"
}

if_prop_value_exits_resetprop_n() {
	local PROP_NAME=$1
	local EXPECTED_VALUE=$2
	local CURRENT_VALUE
	CURRENT_VALUE=$(resetprop "${PROP_NAME}")

	[[ -z "${CURRENT_VALUE}" ]] || [[ "${CURRENT_VALUE}" == "${EXPECTED_VALUE}" ]] || resetprop -n "${PROP_NAME}" "${EXPECTED_VALUE}"
}

# if_contains_resetprop_n() {
# 	local PROP_NAME=$1
#   local CONTAINS_VALUE=$2
#   local NEW_VALUE=$3

#   [[ "$(resetprop ${PROP_NAME})" = *"${CONTAINS_VALUE}"* ]] && resetprop -n "${PROP_NAME}" "${NEW_VALUE}"
# }

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

## bootconfig: key = "value" | cmdline: key=value
brene_spoof_field() {
	local file="$1" fmt="$2" key="$3" val="$4" key_re
	key_re=$(printf '%s' "${key}" | sed 's/\./\\./g')

	if [[ "${fmt}" == "bootconfig" ]]; then
		sed -i "s|^\([[:space:]]*\)${key_re}[[:space:]]*=.*|\1${key} = \"${val}\"|" "${file}"
	else
		sed -i "s|${key_re}=[^ ]*|${key}=${val}|g" "${file}"
	fi

	[[ "${config_brene_logs}" == "1" ]] && echo "[boot_spoof]: ${key} -> ${val}" >> "${PERSISTENT_DIR}/logs.txt"
}

brene_spoof_delete() {
	local file="$1" fmt="$2" key="$3" key_re
	key_re=$(printf '%s' "${key}" | sed 's/\./\\./g')

	if [[ "${fmt}" == "bootconfig" ]]; then
		sed -i "\|^[[:space:]]*${key_re}[[:space:]]*=|d" "${file}"
	else
		sed -i "s| *${key_re}=[^ ]*||g" "${file}"
	fi

	[[ "${config_brene_logs}" == "1" ]] && echo "[boot_spoof]: deleted ${key}" >> "${PERSISTENT_DIR}/logs.txt"
}

