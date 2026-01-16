import {exec, toast} from './assets/kernelsu.js'
import './assets/mwc.js'

document.querySelector('div.preload-hidden').classList.remove('preload-hidden')

const MODDIR = '/data/adb/modules/brene'
const PERSISTENT_DIR = '/data/adb/brene'
const SUSFS_BIN = '/data/adb/ksu/bin/ksu_susfs'
const KSU_BIN = '/data/adb/ksu/bin/ksud'
const configs = [
	{id: 'enable_log'},
	{id: 'enable_avc_log_spoofing'},
	{
		id: 'hide_sus_mnts_for_all_procs',
		action: enabled => setFeature(`${SUSFS_BIN} hide_sus_mnts_for_all_procs ${enabled ? 1 : 0}`)
	},
	{id: 'uname_spoofing'},
	{id: 'hide_data_local_tmp'},
	// { id: 'hide_modules_img' },
	{id: 'hide_zygisk_modules'},
	{id: 'hide_font_modules'},
	{id: 'hide_custom_recovery_folders'},
	{id: 'hide_rooted_app_folders'},
	{id: 'hide_sdcard_android_data'},
	{
		id: 'kernel_umount',
		action: enabled => setFeature(`${KSU_BIN} feature set kernel_umount ${enabled ? 1 : 0} && ${KSU_BIN} feature save`)
	},
	{id: 'custom_uname_spoofing'}
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
	const element = document.getElementById('brene-version')
	element.innerText = result.errno === 0 ? result.stdout : 'unknown'
})

// Load susfs version
exec('susfs show version').then(result => {
	const element = document.getElementById('susfs-version')
	element.innerText = result.errno === 0 ? `${result.stdout}+` : 'unknown'
})

// Helper function to update config
function updateConfig(config, value) {
	exec(`sed -i "s/^${config}=.*/${config}=${value}/" ${PERSISTENT_DIR}/config.sh`).then(result => {
		if (result.errno !== 0) toast('Failed to update config')
	})
}

// Helper funtino to set config immedialtely that no need to reboot
function setFeature(cmd) {
	exec(cmd).then(result => {
		toast(result.errno === 0 ? 'No need to reboot' : result.stderr)
	})
}

// Load config and add toggle event
exec(`cat ${PERSISTENT_DIR}/config.sh`).then(result => {
	if (result.errno !== 0) {
		toast('Failed to load config')
		return
	}

	const configValues = Object.fromEntries(
		result.stdout
			.split('\n')
			.filter(line => line.includes('='))
			.map(line => {
				const [key, ...val] = line.split('=')
				return [
					key.trim(),
					val
						.join('=')
						.trim()
						.replace(/^['"](.*)['"]$/, '$1')
				]
			})
	)

	// uname
	document.getElementById('custom_uname_release').value = configValues['config_custom_uname_kernel_release']
	document.getElementById('custom_uname_version').value = configValues['config_custom_uname_kernel_version']

	// toggle
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
			updateConfig(configId, newConfigValue)
			if (config.action) config.action(enabled)
		})
	})
})

// KSU Modules toggles
;(() => {
	const enableSwitch = document.getElementById('enable_ksu_modules')
	const disableSwitch = document.getElementById('disable_ksu_modules')

	const toggleAllModules = enable => {
		exec(`
			for i in /data/adb/modules/*; do
				${enable ? 'rm -f' : 'touch'} "$i/disable"
			done
		`).then(result => {
			toast(result.errno === 0 ? 'Success' : result.stderr)
		})
	}

	enableSwitch.addEventListener('click', () => toggleAllModules(true))
	disableSwitch.addEventListener('click', () => toggleAllModules(false))
})()

// Custom Uname buttons
;(() => {
	const unameRelease = document.getElementById('custom_uname_release')
	const unameVersion = document.getElementById('custom_uname_version')
	const updateUname = (release, version) => {
		updateConfig('config_custom_uname_kernel_release', release)
		updateConfig('config_custom_uname_kernel_version', version.trim() === '' ? 'default' : version)
		setFeature(`${SUSFS_BIN} set_uname "${release}" "${version}"`)
		unameRelease.value = release
		unameVersion.value = version.trim() === '' ? 'default' : version
	}

	document.getElementById(`button_custom_uname_reset`).onclick = () => updateUname('default', 'default')
	document.getElementById(`button_custom_uname_apply`).onclick = () => {
		if (unameRelease.value !== '') updateUname(unameRelease.value, unameVersion.value)
	}
})()
