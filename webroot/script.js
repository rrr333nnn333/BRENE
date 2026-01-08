import { exec, toast, spawn } from './assets/kernelsu.js'
import './assets/mwc.js'

document.querySelector('div.preload-hidden').classList.remove('preload-hidden')

const MODDIR = '/data/adb/modules/brene'
const PERSISTENT_DIR = '/data/adb/brene'
const SUSFS_BIN = '/data/adb/ksu/bin/ksu_susfs'
const KSU_BIN = '/data/adb/ksu/bin/ksud'
const configs = [
	{ id: 'enable_log' },
	{ id: 'enable_avc_log_spoofing' },
	{
		id: 'hide_sus_mnts_for_all_procs',
		action: (enabled) => {
			exec(`${SUSFS_BIN} hide_sus_mnts_for_all_procs ${enabled ? 1 : 0}`)
			toast('No need to reboot')
		}
	},
	{ id: 'uname_spoofing' },
	{ id: 'hide_data_local_tmp' },
	// { id: 'hide_modules_img' },
	{ id: 'hide_zygisk_modules' },
	{ id: 'hide_font_modules' },
	{ id: 'hide_custom_recovery_folders' },
	{ id: 'hide_rooted_app_folders' },
	{ id: 'hide_sdcard_android_data' },
	{
		id: 'kernel_umount',
		action: (enabled) => {
			exec(`${KSU_BIN} feature set 1 ${enabled ? 1 : 0}`)
			toast('No need to reboot')
		}
	},
	{ id: 'custom_uname_spoofing' },
]

// Load enabled features
exec('susfs show enabled_features').then(result => {
	const container = document.getElementById('kernel-features-container')

	if (result.errno !== 0) {
		container.innerText = 'Failed to load enabled features'
		return
	}
	container.innerText = result.stdout.replaceAll('CONFIG_KSU_', '')
})

// Load brene version
exec(`grep "^version=" ${MODDIR}/module.prop | cut -d'=' -f2`).then(result => {
	if (result.errno !== 0) return

	const element = document.getElementById('brene-version')
	element.innerText = result.stdout
})

// Load susfs version
exec('susfs show version').then(result => {
	if (result.errno !== 0) return

	const element = document.getElementById('susfs-version')
	element.innerText = `${result.stdout}+`
})

// Load config and add toggle event
exec(`cat ${PERSISTENT_DIR}/config.sh`).then(result => {
	if (result.errno !== 0) {
		toast('Failed to load config')
		return
	}

	const configValues = Object.fromEntries(
		result.stdout.split('\n')
			.filter(line => line.includes('='))
			.map(line => {
				const [key, ...val] = line.split('=')
				return [key.trim(), val.join('=').trim().replace(/^['"](.*)['"]$/, '$1')]
			})
	)

	configs.forEach(config => {
		const configId = `config_${config.id}`
		const element = document.getElementById(config.id)
		if (!element) return

		const value = configValues[configId]
		if (value !== undefined) {
			element.selected = parseInt(value) === 1
		}

		element.addEventListener('change', () => {
			const enabled = element.selected
			const newConfigValue = +enabled
			exec(`sed -i "s/^${configId}=.*/${configId}=${newConfigValue}/" ${PERSISTENT_DIR}/config.sh`)
			if (config.action) config.action(enabled)
		})
	})
})

// KSU Modules toggles
; (() => {
	const enableSwitch = document.getElementById('enable_ksu_modules')
	const disableSwitch = document.getElementById('disable_ksu_modules')

	const toggleAllModules = (enable) => {
		spawn('for', [
			'i',
			'in',
			'$(ls /data/adb/modules);',
			'do',
			enable ? 'rm -f' : 'touch',
			'"/data/adb/modules/${i}/disable";',
			'done'
		])
	}

	enableSwitch.addEventListener('click', () => toggleAllModules(true))
	disableSwitch.addEventListener('click', () => toggleAllModules(false))
})()

// Custom Uname buttons
; (() => {
	const resetButton = document.getElementById(`button_custom_uname_reset`)
	resetButton.onclick = () => {
		const configID1 = 'config_custom_uname_kernel_release'
		const configID2 = 'config_custom_uname_kernel_version'
		const newConfig1 = `${configID1}='default'`
		const newConfig2 = `${configID2}='default'`

		exec(`sed -i "s/^${configID1}=.*/${newConfig1}/" ${PERSISTENT_DIR}/config.sh`)
		exec(`sed -i "s/^${configID2}=.*/${newConfig2}/" ${PERSISTENT_DIR}/config.sh`)

		exec(`${SUSFS_BIN} set_uname 'default' 'default'`)
	}

	const applyButton = document.getElementById(`button_custom_uname_apply`)
	applyButton.onclick = () => {
		const configID1 = 'config_custom_uname_kernel_release'
		const configID2 = 'config_custom_uname_kernel_version'
		const newConfigValue1 = document.getElementById('text_field_custom_uname_release').value
		const newConfigValue2 = document.getElementById('text_field_custom_uname_version').value
		const newConfig1 = `${configID1}='${newConfigValue1}'`
		const newConfig2 = `${configID2}='${newConfigValue2}'`

		if (newConfigValue1 !== '') exec(`sed -i "s/^${configID1}=.*/${newConfig1}/" ${PERSISTENT_DIR}/config.sh`)
		if (newConfigValue2 !== '') exec(`sed -i "s/^${configID2}=.*/${newConfig2}/" ${PERSISTENT_DIR}/config.sh`)

		exec(`${SUSFS_BIN} set_uname "${newConfigValue1}" "${newConfigValue2}"`)
	}
})()
