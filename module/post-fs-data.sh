#!/bin/bash
# shellcheck disable=SC2154
MODDIR=${0%/*}
KSU_BIN=/data/adb/ksud
KSU_MODULES_DIR=/data/adb/modules
SUSFS_BIN=/data/adb/ksu/bin/susfs
PERSISTENT_DIR=/data/adb/brene
DEST_BIN_DIR=/data/adb/ksu/bin
CUSTOM_ROM_NAMES="lineage|infinity|evolution|crdroid|mistos|axion|pixelos|rising|lunaris|halcyon|havoc|alphadroid|bliss|calyx|derpfest|graphene|lmodroid|lumine|matrixx|clover|yaap|aospa"
SUSFS_VARIANT=$(${SUSFS_BIN} show variant)

# Load utils
[[ -e "${MODDIR}/utils.sh" ]] && source "${MODDIR}/utils.sh"
# Load config
[[ -e "${PERSISTENT_DIR}/config.sh" ]] && source "${PERSISTENT_DIR}/config.sh"

# Restore SUSFS binary
cp -pf "${PERSISTENT_DIR}/susfs" "${DEST_BIN_DIR}"
ln -sf "${DEST_BIN_DIR}/susfs" "${DEST_BIN_DIR}/sus"       # For development
ln -sf "${DEST_BIN_DIR}/susfs" "${DEST_BIN_DIR}/ksu_susfs" # For compatibility

# Clear logs
true > "${PERSISTENT_DIR}/log.txt"
true > "${PERSISTENT_DIR}/logs.txt"

# Spoof /proc/cmdline or /proc/bootconfig
if [[ "${config_spoof_cmdline_or_bootconfig}" == "1" ]]; then
	if [[ "${SUSFS_VARIANT}" == "GKI" ]]; then
		FAKE_BOOTCONFIG="${PERSISTENT_DIR}/fake_bootconfig"

		cat /proc/bootconfig > "${FAKE_BOOTCONFIG}"
		sed -i 's/androidboot.warranty_bit = "1"/androidboot.warranty_bit = "0"/' "${FAKE_BOOTCONFIG}"
		sed -i 's/androidboot.verifiedbootstate = "orange"/androidboot.verifiedbootstate = "green"/' "${FAKE_BOOTCONFIG}"
		${SUSFS_BIN} set_cmdline_or_bootconfig "${FAKE_BOOTCONFIG}"
	fi
fi

#### Enable avc log spoofing to bypass 'su' domain detection via /proc/<pid> enumeration, effective for all processes ####
## disable it when users want to do some debugging with the permission issue or selinux issue ##
#ksu_susfs enable_avc_log_spoofing 0
if [[ "${config_enable_avc_log_spoofing}" == "1" ]]; then
	${SUSFS_BIN} enable_avc_log_spoofing 1
fi

#### Hide all sus mounts for NON-SU processes in this stage just to prevent zygote from caching them in memory ####
if [[ "${config_hide_sus_mnts_for_non_su_procs}" == "1" ]]; then
	${SUSFS_BIN} hide_sus_mnts_for_non_su_procs 1
fi

#### Spoof the uname, effective for all processes ####
# you can get your uname args by running 'uname {-r|-v}' on your stock ROM #
# pass 'default' to tell susfs to use the default value by uname #
# ${SUSFS_BIN} set_uname 'default' 'default'

# Custom Spoof Uname
if [[ "${config_custom_spoof_uname}" == "1" ]]; then
	if [[ "${config_brene_logs}" == "1" ]]; then
		{
			echo ""
			echo "##################"
			echo "Custom Spoof Uname"
			echo "##################"
		} >> "${PERSISTENT_DIR}/logs.txt"
	fi

	brene_set_uname "${config_custom_uname_kernel_release}" "${config_custom_uname_kernel_version}"

# Spoof Uname
elif [[ "${config_spoof_uname}" == "1" ]]; then
	if [[ "${config_brene_logs}" == "1" ]]; then
		{
			echo ""
			echo "###########"
			echo "Spoof Uname"
			echo "###########"
		} >> "${PERSISTENT_DIR}/logs.txt"
	fi

	kernel_version=$(cat /proc/version | awk '{print $3}' | grep -oE '^[0-9]+\.[0-9]+\.[0-9]+')
	uname_kernel_version="#1 SMP PREEMPT $(resetprop ro.build.date | tr -s ' ')"

	if [[ "${SUSFS_VARIANT}" == "GKI" ]]; then
		kmi=$(${KSU_BIN} boot-info current-kmi | cut -d'-' -f1)
		uname_kernel_release="${kernel_version}-${kmi}-$(shuf -i 1-9 -n 1)-g$(shuf -i 10000000-99999999 -n 1)-ab$(shuf -i 10000000-99999999 -n 1)" # e.g., "6.1.145-android14-9-g00000000-ab00000000"

		brene_set_uname "${uname_kernel_release}" "${uname_kernel_version}"
	else
		uname_kernel_release="${kernel_version}-g$(shuf -i 10000000-99999999 -n 1)" # e.g., "4.9.145-g00000000"

		brene_set_uname "${uname_kernel_release}" "${uname_kernel_version}"
	fi
fi

if [[ "${config_enable_log}" == "1" ]]; then
	${SUSFS_BIN} enable_log 1
elif [[ "${config_enable_log}" == "0" ]]; then
	${SUSFS_BIN} enable_log 0
fi

## System Property Spoofing
# Spoof System Properties
if [[ "${config_spoof_system_properties}" == "1" ]]; then
	spoof_system_properties
fi
# Spoof OS Security Patch Level Property
if [[ "${config_spoof_os_security_patch_level_property}" == "1" ]]; then
	spoof_os_security_patch_level_property
fi
# Spoof Vendor Security Patch Level Property
if [[ "${config_spoof_vendor_security_patch_level_property}" == "1" ]]; then
	spoof_vendor_security_patch_level_property
fi

if [[ "${config_brene_logs}" == "1" ]]; then
	echo "✅ post-fs-data.sh" >> "${PERSISTENT_DIR}/log.txt"
fi
