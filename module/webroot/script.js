import { exec, toast } from './assets/kernelsu.js'
import './assets/mwc.js'

document.querySelector('div.preload-hidden').classList.remove('preload-hidden')

const MODDIR = '/data/adb/modules/brene'
const PERSISTENT_DIR = '/data/adb/brene'
const configs = [
	{
		id: 'hide_sus_mnts_for_non_su_procs',
		action: (enabled) => setFeature(`susfs hide_sus_mnts_for_non_su_procs ${enabled ? 1 : 0}`),
	},
	{
		id: 'su_compat',
		action: (enabled) => setFeature(`ksud feature set su_compat ${enabled ? 1 : 0} && ksud feature save`),
	},
	{
		id: 'kernel_umount',
		action: (enabled) => setFeature(`ksud feature set kernel_umount ${enabled ? 1 : 0} && ksud feature save`),
	},
	{
		id: 'selinux_hide',
		action: (enabled) => setFeature(`ksud feature set selinux_hide ${enabled ? 1 : 0} && ksud feature save`),
	},
	{
		id: 'developer_options',
		action: (enabled) => setFeature(`settings put global development_settings_enabled ${enabled ? 1 : 0}`),
	},
	{
		id: 'usb_debugging',
		action: (enabled) => setFeature(`settings put global adb_enabled ${enabled ? 1 : 0}`),
	},
	{
		id: 'wireless_debugging',
		action: (enabled) => setFeature(`settings put global adb_wifi_enabled ${enabled ? 1 : 0}`),
	},
	{
		id: 'selinux',
		action: (enabled) => setFeature(`setenforce ${enabled ? 1 : 0}`),
	},
	{
		id: 'saturation',
		action: (enabled) => setFeature(`service call SurfaceFlinger 1022 f ${enabled ? 2.0 : 1.0}`),
	},
	{
		id: 'show_refresh_rate',
		action: (enabled) => setFeature(`service call SurfaceFlinger 1034 i32 ${enabled ? 1 : 0}`),
	},
	{
		id: 'disable_child_process_restrictions',
		action: (enabled) => {
			setFeature(`resetprop -n persist.sys.fflag.override.settings_enable_monitor_phantom_procs ${enabled ? false : true}`)
		},
	},
	{ id: 'pif_props' },
	{ id: 'rom_props' },
	{ id: 'brene_logs' },
	{ id: 'enable_log' },
	{ id: 'spoof_uname' },
	{ id: 'spoof_hosts' },
	{ id: 'hide_addon_d' },
	{ id: 'custom_spoof_uname' },
	{ id: 'hide_suspicious_pty' },
	{ id: 'hide_custom_recovery' },
	{ id: 'hide_lineage_strings' },
	{ id: 'spoof_libstagefright' },
	{ id: 'hide_custom_rom_paths' },
	{ id: 'hide_custom_rom_paths_2' },
	{ id: 'hide_framework_res_apk' },
	{ id: 'enable_avc_log_spoofing' },
	{ id: 'spoof_cmdline_or_bootconfig' },
	{ id: 'fix_data_local_tmp_inconsistencies' },
	{ id: 'spoof_system_properties' },
	{ id: 'spoof_system_properties_repeat' },
	{ id: 'spoof_fingerprint_properties' },
	{ id: 'spoof_utc_properties' },
	{ id: 'spoof_date_properties' },
	{ id: 'spoof_os_security_patch_level_property' },
	{ id: 'spoof_vendor_security_patch_level_property' },

	{ id: 'paths_hiding__non_standard_sdcard' },
	{ id: 'paths_hiding__non_standard_sdcard_android' },
	{ id: 'paths_hiding__data_local_tmp' },
]

// Open URLs
document.querySelectorAll('a[href]').forEach((element) => {
	element.addEventListener('click', (event) => {
		event.preventDefault()
		exec(`am start -a android.intent.action.VIEW -d ${element.href}`)
	})
})

// Load Android Version
exec('resetprop ro.build.version.release && resetprop ro.build.version.sdk').then((result) => {
	const container = document.querySelector('#android-version .card-row__sub')

	if (result.errno !== 0) {
		container.innerText = 'Failed to load'
		return
	}
	const results = result.stdout.replaceAll('\n', ' ')
	const splits = results.split(' ')
	container.innerText = `${splits[0]} (API ${splits[1]}) | SDK ${splits[1]}`
})

// Load SuSFS Variant
exec('susfs show variant').then((result) => {
	const container = document.querySelector('#susfs-variant .card-row__sub')

	if (result.errno !== 0) {
		container.innerText = 'Failed to load'
		return
	}
	container.innerText = result.stdout
})

// Load Kernel Version
exec("cat /proc/version | awk '{print $3}' && uname -r").then((result) => {
	const container = document.querySelector('#kernel-version .card-row__sub')

	if (result.errno !== 0) {
		container.innerText = 'Failed to load'
		return
	}
	container.innerText = `Default: ${result.stdout.replace('\n', '\nSpoofed: ')}`
})

// Load Device Model Status
exec('resetprop ro.product.manufacturer && resetprop ro.product.model && resetprop ro.product.device').then((result) => {
	const container = document.querySelector('#device-model .card-row__sub')

	if (result.errno !== 0) {
		container.innerText = 'Failed to load'
		return
	}

	let model
	const splits = result.stdout.split('\n')

	exec('resetprop ro.product.marketname')
		.then((result) => {
			if (result.errno !== 0) return
			model = result.stdout
		})
		.then(() => {
			model = model || splits[1]
			container.innerText = `${splits[0]} ${model} | ${splits[2]}`
		})
})

// Load Custom ROM Status
exec('[[ -n "$(find /system -iname "*lineage*")" ]] && echo "Yes" || echo "No"').then((result) => {
	const container = document.querySelector('#custom-rom .card-row__sub')

	if (result.errno !== 0) {
		container.innerText = 'Failed to load'
		return
	}
	container.innerText = result.stdout
})

// Load ..5.u.S Status
exec('[[ -e /storage/emulated/0/..5.u.S ]] && echo "Abnormal" || echo "Normal"').then((result) => {
	const container = document.querySelector('#sus-status .card-row__sub')

	if (result.errno !== 0) {
		container.innerText = 'Failed to load'
		return
	}
	container.innerText = result.stdout
})

// Recommended Modules
exec('ksud module list').then((result) => {
	if (result.errno !== 0) return

	const container = document.querySelector('#recommended-modules')
	const modules = JSON.parse(result.stdout)
	const moduleIds = modules.map((mod) => mod.id)
	const cardRows = container.querySelectorAll('.card-row')

	cardRows.forEach((row) => {
		const moduleKey = row.getAttribute('data-module')
		const statusSpan = row.querySelector('.status-text')

		if (moduleIds.includes(moduleKey)) {
			statusSpan.innerText = 'Status: Installed'
			statusSpan.style.color = '#4CAF50'
		}
	})

	exec('[[ -e /data/adb/modules/TA_utl ]]').then((result) => {
		if (result.errno !== 0) return

		const card = document.querySelector('[data-module="tricky_addon"]')
		const statusSpan = card.querySelector('.status-text')
		statusSpan.innerText = 'Status: Installed'
		statusSpan.style.color = '#4CAF50'
	})
})

// Incompatible Modules
exec('ksud module list').then((result) => {
	if (result.errno !== 0) return

	const container = document.querySelector('#incompatible-modules')
	const modules = JSON.parse(result.stdout)
	const moduleIds = modules.map((mod) => mod.id)
	const cardRows = container.querySelectorAll('.card-row')

	cardRows.forEach((row) => {
		const moduleKey = row.getAttribute('data-module')
		const statusSpan = row.querySelector('.status-text')

		if (moduleIds.includes(moduleKey)) {
			statusSpan.innerText = 'Status: Installed'
			statusSpan.style.color = '#ff0000be'
		}
	})
})

// Load enabled features
exec('susfs show enabled_features').then((result) => {
	const container = document.getElementById('kernel-features-container')

	if (result.errno !== 0) {
		container.innerText = 'Failed to load enabled features'
		return
	}
	container.innerText = result.stdout.replaceAll('CONFIG_KSU_SUSFS_', '')
})

// Load Suspicious Mounts
exec(`cat /proc/1/mountinfo | grep -E "^2[0-9]{9,} .*$|KSU" | awk '{print $5}'`).then((result) => {
	const container = document.getElementById('suspicious_mounts')

	if (result.errno !== 0) {
		container.innerText = 'Failed to load'
		return
	}

	if (result.stdout.length > 0) {
		container.innerText = result.stdout
	} else {
		container.innerText = '0'
	}
})

// Load logs
exec(`cat ${PERSISTENT_DIR}/log.txt`).then((result) => {
	const container = document.getElementById('logs')

	if (result.errno !== 0) {
		container.textContent += 'Failed to load logs'
		return
	}
	container.textContent += result.stdout
	container.textContent += '\n'

	exec(`cat ${PERSISTENT_DIR}/logs.txt`).then((result) => {
		if (result.errno !== 0) {
			container.textContent += 'Failed to load logs'
			return
		}
		container.textContent += result.stdout
	})
})

// Load brene version
exec(`grep "^version=" ${MODDIR}/module.prop | cut -d'=' -f2`).then((result) => {
	const element = document.getElementById('brene-version')
	element.innerText = result.errno === 0 ? result.stdout : 'unknown'
})

// Load susfs version
exec('susfs show version').then((result) => {
	const element = document.getElementById('susfs-version')
	element.innerText = result.errno === 0 ? `${result.stdout}+` : 'unknown'
})

// Helper function to update config
function updateConfig(config, value) {
	exec(`sed -i "s/^${config}=.*/${config}=${value}/" ${PERSISTENT_DIR}/config.sh`).then((result) => {
		if (result.errno !== 0) toast('Failed to update config')
	})
}

// TEMP
// Helper function to update config
function updateConfig2(config, value) {
	exec(`sed -i "s/^${config}=.*/${config}='${value}'/" ${PERSISTENT_DIR}/config.sh`).then((result) => {
		if (result.errno !== 0) toast('Failed to update config')
	})
}

// Helper function to set config immedialtely that no need to reboot
function setFeature(cmd) {
	exec(cmd).then((result) => {
		toast(result.errno === 0 ? 'No need to reboot' : result.stderr)
	})
}

// Load config and add toggle event
exec(`cat ${PERSISTENT_DIR}/config.sh`).then((result) => {
	if (result.errno !== 0) {
		toast('Failed to load config')
		return
	}

	const configValues = Object.fromEntries(
		result.stdout
			.split('\n')
			.filter((line) => line.includes('='))
			.map((line) => {
				const [key, ...val] = line.split('=')
				return [
					key.trim(),
					val
						.join('=')
						.trim()
						.replace(/^['"](.*)['"]$/, '$1'),
				]
			}),
	)

	// custom uname
	document.getElementById('custom_uname_release').value = configValues['config_custom_uname_kernel_release']
	document.getElementById('custom_uname_version').value = configValues['config_custom_uname_kernel_version']

	// Verified Boot Hash
	document.getElementById('vbh_text_field').value = configValues['config_spoof_verified_boot_hash']

	// toggle
	configs.forEach((config) => {
		const configId = `config_${config.id}`
		const element = document.getElementById(config.id)
		if (!element) return

		const value = configValues[configId]
		if (value !== undefined) {
			element.selected = parseInt(value) === 1
		}

		element.addEventListener('change', async () => {
			const enabled = element.selected
			const newConfigValue = +enabled
			updateConfig(configId, newConfigValue)
			if (config.action) config.action(enabled)
		})
	})

	// Reset Settings
	const dialog = document.getElementById('dialog')
	const openButton = document.getElementById('reset_settings')
	openButton.addEventListener('click', () => {
		dialog.show()
	})
	dialog.addEventListener('close', () => {
		if (dialog.returnValue === 'confirm') {
			exec(`
				cp -f ${MODDIR}/config.sh ${PERSISTENT_DIR}
			`).then((result) => {
				configs.forEach((config) => {
					const configId = `config_${config.id}`
					const element = document.getElementById(config.id)
					if (!element) return

					const value = configValues[configId]
					if (value !== undefined) {
						element.selected = parseInt(value) === 1
					}
				})

				toast(result.errno === 0 ? 'Success' : result.stderr)
			})
		}
	})
})

// KSU Module Control
;(async () => {
	const enableButton = document.getElementById('enable_ksu_modules')
	const disableButton = document.getElementById('disable_ksu_modules')

	const toggleAllModules = (enable) => {
		exec(`
			for i in /data/adb/modules/*; do
				${enable ? 'rm -f' : 'touch'} "$i/disable"
			done
		`).then((result) => {
			toast(result.errno === 0 ? 'Success' : result.stderr)
		})
	}

	enableButton.addEventListener('click', () => toggleAllModules(true))
	disableButton.addEventListener('click', () => toggleAllModules(false))
})()

// Custom Uname buttons
;(async () => {
	const unameRelease = document.getElementById('custom_uname_release')
	const unameVersion = document.getElementById('custom_uname_version')

	const updateUname = (release, version) => {
		updateConfig2('config_custom_uname_kernel_release', release)
		updateConfig2('config_custom_uname_kernel_version', version)
		setFeature(`susfs set_uname "${release}" "${version}"`)
	}

	// Apply
	document.getElementById(`button_custom_uname_apply`).onclick = () => {
		if (unameRelease.value !== '' && unameVersion.value !== '') {
			updateUname(unameRelease.value, unameVersion.value)
		}
	}

	// Reset
	document.getElementById(`button_custom_uname_reset`).onclick = () => {
		updateUname('default', 'default')
		unameRelease.value = 'default'
		unameVersion.value = 'default'
	}
})()

// Verified Boot Hash
;(async () => {
	const button = document.getElementById('vbh_button')
	const textField = document.getElementById('vbh_text_field')

	button.addEventListener('click', () => {
		updateConfig2('config_spoof_verified_boot_hash', textField.value)

		exec(`resetprop -n ro.boot.vbmeta.digest ${textField.value}`).then((result) => {
			if (result.errno === 0) {
				toast('No need to reboot')
			} else {
				toast('Failed to update prop')
			}
		})
	})

	// textField.addEventListener('focus', () => {
	// 	setTimeout(() => {
	// 		window.scrollTo({
	// 			top: Math.max(document.body.scrollHeight, document.documentElement.scrollHeight),
	// 		})
	// 	}, 500)
	// })
})()

//
;(async () => {
	const mapField = document.getElementById('custom_sus_map_text_field')
	const pathField = document.getElementById('custom_sus_path_text_field')
	const loopField = document.getElementById('custom_sus_path_loop_text_field')
	const applyButton = document.getElementById('unified_apply_button')
	const tabs = document.getElementById('sus_tabs')
	const scrollContainer = document.getElementById('horizontal_scroll_container')

	// Load all contents
	exec(`cat ${PERSISTENT_DIR}/custom_sus_map.txt`).then((result) => {
		mapField.value = result.errno === 0 ? `${result.stdout}` : ''
	})
	exec(`cat ${PERSISTENT_DIR}/custom_sus_path.txt`).then((result) => {
		pathField.value = result.errno === 0 ? `${result.stdout}` : ''
	})
	exec(`cat ${PERSISTENT_DIR}/custom_sus_path_loop.txt`).then((result) => {
		loopField.value = result.errno === 0 ? `${result.stdout}` : ''
	})

	// Tabs and Scroll Sync
	tabs.addEventListener('change', () => {
		const index = tabs.activeTabIndex
		const width = scrollContainer.getBoundingClientRect().width
		scrollContainer.scrollTo({
			left: width * index,
			behavior: 'smooth',
		})
	})

	let scrollTimeout
	scrollContainer.addEventListener('scroll', () => {
		clearTimeout(scrollTimeout)
		scrollTimeout = setTimeout(() => {
			const width = scrollContainer.getBoundingClientRect().width
			const index = Math.round(scrollContainer.scrollLeft / width)
			if (tabs.activeTabIndex !== index) {
				tabs.activeTabIndex = index
			}
		}, 50)
	})

	applyButton.onclick = () => {
		const index = tabs.activeTabIndex
		let file = ''
		let content = ''

		switch (index) {
			case 0:
				file = 'custom_sus_map.txt'
				content = mapField.value
				break
			case 1:
				file = 'custom_sus_path.txt'
				content = pathField.value
				break
			case 2:
				file = 'custom_sus_path_loop.txt'
				content = loopField.value
				break
		}

		if (file) {
			if (content === '') {
				exec(`printf '' > ${PERSISTENT_DIR}/${file}`).then((result) => {
					toast(result.errno === 0 ? 'Success' : result.stderr)
				})
			} else {
				content = content.replaceAll('/sdcard', '/storage/emulated/0')

				exec(`
cat <<'UNIQUE_EOF' > ${PERSISTENT_DIR}/${file}
${content}
UNIQUE_EOF
				`).then((result) => {
					toast(result.errno === 0 ? 'Success' : result.stderr)
				})
			}
		}
	}
})()

// Manual Kernel Umount
;(async () => {
	const mountField = document.getElementById('custom_kernel_umount_text_field')
	const applyButton = document.getElementById('kernel_umount_apply_button')

	// Load all content
	exec(`cat ${PERSISTENT_DIR}/custom_kernel_umount.txt`).then((result) => {
		mountField.value = result.errno === 0 ? `${result.stdout}` : ''
	})

	applyButton.onclick = () => {
		let file = 'custom_kernel_umount.txt'
		let content = mountField.value

		if (file) {
			if (content === '') {
				exec(`printf '' > ${PERSISTENT_DIR}/${file}`).then((result) => {
					toast(result.errno === 0 ? 'Success' : result.stderr)
				})
			} else {
				exec(`
cat <<'UNIQUE_EOF' > ${PERSISTENT_DIR}/${file}
${content}
UNIQUE_EOF
				`).then((result) => {
					toast(result.errno === 0 ? 'Success' : result.stderr)
				})
			}
		}
	}
})()

// tabs.js — tab switching
;(async () => {
	var btns = document.querySelectorAll('.tab-btn')
	var panels = document.querySelectorAll('.tab-panel')

	function activate(id) {
		btns.forEach(function (b) {
			b.classList.toggle('active', b.dataset.tab === id)
		})
		panels.forEach(function (p) {
			p.classList.toggle('active', p.dataset.panel === id)
		})
	}

	btns.forEach(function (btn) {
		btn.addEventListener('click', function () {
			activate(btn.dataset.tab)
			try {
				sessionStorage.setItem('brene_tab', btn.dataset.tab)
			} catch (e) {}
		})
	})

	try {
		var saved = sessionStorage.getItem('brene_tab')
		if (saved) activate(saved)
	} catch (e) {}
})()

// Swipe
;(async () => {
	const tabBar = document.getElementById('tab-bar')
	const bodyContent = document
	const buttons = Array.from(tabBar.querySelectorAll('button.tab-btn'))
	const SWIPE_THRESHOLD = 10
	let currentIndex = buttons.findIndex((btn) => btn.classList.contains('active')) || 0
	let touchStartX = 0
	let touchStartY = 0

	const updateUI = (index) => {
		buttons[index].click()

		buttons[index].scrollIntoView({
			behavior: 'auto',
			block: 'nearest',
			inline: 'center',
		})
	}

	const changeTab = (index) => {
		if (index >= 0 && index < buttons.length) {
			currentIndex = index
			updateUI(index)
		}
	}

	bodyContent.addEventListener(
		'touchstart',
		(e) => {
			touchStartX = e.touches[0].clientX
			touchStartY = e.touches[0].clientY
		},
		{ passive: true },
	)

	bodyContent.addEventListener(
		'touchend',
		(e) => {
			if (e.target.closest('.tab-bar') === null) {
				const touchEndX = e.changedTouches[0].clientX
				const touchEndY = e.changedTouches[0].clientY

				const diffX = touchStartX - touchEndX
				const diffY = touchStartY - touchEndY

				const isHorizontalSwipe = Math.abs(diffX) > SWIPE_THRESHOLD
				const isDominantX = Math.abs(diffX) > Math.abs(diffY) * 3

				if (isHorizontalSwipe && isDominantX) {
					if (diffX > 0) {
						changeTab(currentIndex + 1)
					} else {
						changeTab(currentIndex - 1)
					}
				}
			}
		},
		{ passive: true },
	)

	tabBar.addEventListener('click', (e) => {
		const btn = e.target.closest('.tab-btn')
		if (btn) {
			currentIndex = buttons.indexOf(btn)
		}
	})
})()
