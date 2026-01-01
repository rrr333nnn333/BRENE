import {exec, spawn, toast, moduleInfo} from 'kernelsu'
import '@material/web/all.js'

const MODDIR = '/data/adb/modules/brene'
const PERSISTENT_DIR = '/data/adb/brene'
const SUSFS_BIN = '/data/adb/ksu/bin/ksu_susfs'

// Load enabled features
exec('susfs show enabled_features').then(result => {
	if (result.errno !== 0) return

	const element = document.createElement('div')
	element.innerText = result.stdout
	element.className = 'toggle-option'
	document.body.appendChild(element)
})

// Load brene version
exec(`grep "^version=" ${MODDIR}/module.prop | cut -d'=' -f2`).then(result => {
	if (result.errno !== 0) return

	const element = document.querySelector('span#brene-version')
	element.innerText = result.stdout
})

// Load susfs version
exec('susfs show version').then(result => {
	if (result.errno !== 0) return

	const element = document.querySelector('span#susfs-version')
	element.innerText = `${result.stdout}+`
})

//
//
//
;(() => {
	const configID = 'config_enable_log'
	const mdSwitchID = 'switch_enable_log'
	exec(`grep "^${configID}=" ${PERSISTENT_DIR}/config.sh | cut -d'=' -f2`).then(result => {
		if (result.errno !== 0) return

		const element = document.querySelector(`md-switch#${mdSwitchID}`)
		const value = parseInt(result.stdout)
		element.selected = value
		element.addEventListener('click', event => {
			const enabled = event.target.shadowRoot.children[0].classList.contains('unselected')
			const newConfigValue = +enabled
			const newConfig = `${configID}=${newConfigValue}`

			exec(`sed -i "s/^${configID}=.*/${newConfig}/" ${PERSISTENT_DIR}/config.sh`)
		})
	})
})()
//
//
//
;(() => {
	const configID = 'config_enable_avc_log_spoofing'
	const mdSwitchID = 'switch_enable_avc_log_spoofing'
	exec(`grep "^${configID}=" ${PERSISTENT_DIR}/config.sh | cut -d'=' -f2`).then(result => {
		if (result.errno !== 0) return

		const element = document.querySelector(`md-switch#${mdSwitchID}`)
		const value = parseInt(result.stdout)
		element.selected = value
		element.addEventListener('click', event => {
			const enabled = event.target.shadowRoot.children[0].classList.contains('unselected')
			const newConfigValue = +enabled
			const newConfig = `${configID}=${newConfigValue}`

			exec(`sed -i "s/^${configID}=.*/${newConfig}/" ${PERSISTENT_DIR}/config.sh`)
		})
	})
})()
//
//
//
;(() => {
	const configID = 'config_hide_sus_mnts_for_all_procs'
	const mdSwitchID = 'switch_hide_sus_mnts_for_all_procs'
	exec(`grep "^${configID}=" ${PERSISTENT_DIR}/config.sh | cut -d'=' -f2`).then(result => {
		if (result.errno !== 0) return

		const element = document.querySelector(`md-switch#${mdSwitchID}`)
		const value = parseInt(result.stdout)
		element.selected = value
		element.addEventListener('click', event => {
			const enabled = event.target.shadowRoot.children[0].classList.contains('unselected')
			const newConfigValue = +enabled
			const newConfig = `${configID}=${newConfigValue}`

			exec(`sed -i "s/^${configID}=.*/${newConfig}/" ${PERSISTENT_DIR}/config.sh`)

			enabled ? exec(`${SUSFS_BIN} hide_sus_mnts_for_all_procs 1`) : exec(`${SUSFS_BIN} hide_sus_mnts_for_all_procs 0`)

			toast('No need to reboot')
		})
	})
})()
//
//
//
;(() => {
	const configID = 'config_uname_spoofing'
	const mdSwitchID = 'switch_uname_spoofing'
	exec(`grep "^${configID}=" ${PERSISTENT_DIR}/config.sh | cut -d'=' -f2`).then(result => {
		if (result.errno !== 0) return

		const element = document.querySelector(`md-switch#${mdSwitchID}`)
		const value = parseInt(result.stdout)
		element.selected = value
		element.addEventListener('click', event => {
			const enabled = event.target.shadowRoot.children[0].classList.contains('unselected')
			const newConfigValue = +enabled
			const newConfig = `${configID}=${newConfigValue}`

			exec(`sed -i "s/^${configID}=.*/${newConfig}/" ${PERSISTENT_DIR}/config.sh`)
		})
	})
})()
//
//
//
;(() => {
	const configID = 'config_hide_data_local_tmp'
	const mdSwitchID = 'switch_hide_data_local_tmp'
	exec(`grep "^${configID}=" ${PERSISTENT_DIR}/config.sh | cut -d'=' -f2`).then(result => {
		if (result.errno !== 0) return

		const element = document.querySelector(`md-switch#${mdSwitchID}`)
		const value = parseInt(result.stdout)
		element.selected = value
		element.addEventListener('click', event => {
			const enabled = event.target.shadowRoot.children[0].classList.contains('unselected')
			const newConfigValue = +enabled
			const newConfig = `${configID}=${newConfigValue}`

			exec(`sed -i "s/^${configID}=.*/${newConfig}/" ${PERSISTENT_DIR}/config.sh`)
		})
	})
})()
//
//
//
;(() => {
	const configID = 'config_hide_modules_img'
	const mdSwitchID = 'switch_hide_modules_img'
	exec(`grep "^${configID}=" ${PERSISTENT_DIR}/config.sh | cut -d'=' -f2`).then(result => {
		if (result.errno !== 0) return

		const element = document.querySelector(`md-switch#${mdSwitchID}`)
		const value = parseInt(result.stdout)
		element.selected = value
		element.addEventListener('click', event => {
			const enabled = event.target.shadowRoot.children[0].classList.contains('unselected')
			const newConfigValue = +enabled
			const newConfig = `${configID}=${newConfigValue}`

			exec(`sed -i "s/^${configID}=.*/${newConfig}/" ${PERSISTENT_DIR}/config.sh`)
		})
	})
})()
//
//
//
;(() => {
	const configID = 'config_hide_zygisk_modules'
	const mdSwitchID = 'switch_hide_zygisk_modules'
	exec(`grep "^${configID}=" ${PERSISTENT_DIR}/config.sh | cut -d'=' -f2`).then(result => {
		if (result.errno !== 0) return

		const element = document.querySelector(`md-switch#${mdSwitchID}`)
		const value = parseInt(result.stdout)
		element.selected = value
		element.addEventListener('click', event => {
			const enabled = event.target.shadowRoot.children[0].classList.contains('unselected')
			const newConfigValue = +enabled
			const newConfig = `${configID}=${newConfigValue}`

			exec(`sed -i "s/^${configID}=.*/${newConfig}/" ${PERSISTENT_DIR}/config.sh`)
		})
	})
})()
//
//
//
;(() => {
	const configID = 'config_hide_font_modules'
	const mdSwitchID = 'switch_hide_font_modules'
	exec(`grep "^${configID}=" ${PERSISTENT_DIR}/config.sh | cut -d'=' -f2`).then(result => {
		if (result.errno !== 0) return

		const element = document.querySelector(`md-switch#${mdSwitchID}`)
		const value = parseInt(result.stdout)
		element.selected = value
		element.addEventListener('click', event => {
			const enabled = event.target.shadowRoot.children[0].classList.contains('unselected')
			const newConfigValue = +enabled
			const newConfig = `${configID}=${newConfigValue}`

			exec(`sed -i "s/^${configID}=.*/${newConfig}/" ${PERSISTENT_DIR}/config.sh`)
		})
	})
})()
//
//
//
;(() => {
	const configID = 'config_hide_custom_recovery_folders'
	const mdSwitchID = 'switch_hide_custom_recovery_folders'
	exec(`grep "^${configID}=" ${PERSISTENT_DIR}/config.sh | cut -d'=' -f2`).then(result => {
		if (result.errno !== 0) return

		const element = document.querySelector(`md-switch#${mdSwitchID}`)
		const value = parseInt(result.stdout)
		element.selected = value
		element.addEventListener('click', event => {
			const enabled = event.target.shadowRoot.children[0].classList.contains('unselected')
			const newConfigValue = +enabled
			const newConfig = `${configID}=${newConfigValue}`

			exec(`sed -i "s/^${configID}=.*/${newConfig}/" ${PERSISTENT_DIR}/config.sh`)
		})
	})
})()
//
//
//
;(() => {
	const configID = 'config_hide_rooted_app_folders'
	const mdSwitchID = 'switch_hide_rooted_app_folders'
	exec(`grep "^${configID}=" ${PERSISTENT_DIR}/config.sh | cut -d'=' -f2`).then(result => {
		if (result.errno !== 0) return

		const element = document.querySelector(`md-switch#${mdSwitchID}`)
		const value = parseInt(result.stdout)
		element.selected = value
		element.addEventListener('click', event => {
			const enabled = event.target.shadowRoot.children[0].classList.contains('unselected')
			const newConfigValue = +enabled
			const newConfig = `${configID}=${newConfigValue}`

			exec(`sed -i "s/^${configID}=.*/${newConfig}/" ${PERSISTENT_DIR}/config.sh`)
		})
	})
})()
//
//
//
;(() => {
	const configID = 'config_hide_sdcard_android_data'
	const mdSwitchID = 'switch_hide_sdcard_android_data'
	exec(`grep "^${configID}=" ${PERSISTENT_DIR}/config.sh | cut -d'=' -f2`).then(result => {
		if (result.errno !== 0) return

		const element = document.querySelector(`md-switch#${mdSwitchID}`)
		const value = parseInt(result.stdout)
		element.selected = value
		element.addEventListener('click', event => {
			const enabled = event.target.shadowRoot.children[0].classList.contains('unselected')
			const newConfigValue = +enabled
			const newConfig = `${configID}=${newConfigValue}`

			exec(`sed -i "s/^${configID}=.*/${newConfig}/" ${PERSISTENT_DIR}/config.sh`)
		})
	})
})()
