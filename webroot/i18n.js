const defaultLanguage = 'en'
const storageKey = 'brene_language'

const languages = [
	{ code: 'en', label: 'English' },
	{ code: 'pt-BR', label: 'Português (Brasil)' },
]

const translations = {
	'pt-BR': {
		Language: 'Idioma',
		Status: 'Status',
		Hiding: 'Ocultação',
		Spoofing: 'Mascaramento',
		Advanced: 'Avançado',
		Info: 'Info',
		General: 'Geral',
		'Recommended Modules': 'Módulos recomendados',
		'Incompatible Modules': 'Módulos incompatíveis',
		'Android Settings': 'Configurações do Android',
		'Suspicious Paths Hiding': 'Ocultação de caminhos suspeitos',
		'Other Hiding': 'Outras ocultações',
		'Custom SuSFS Entries': 'Entradas SuSFS personalizadas',
		'Spoofing Features': 'Recursos de mascaramento',
		'Android Verified Boot Hash Spoofing': 'Mascaramento do hash do Android Verified Boot',
		'Custom ROM': 'ROM personalizada',
		'Advanced / Other Features': 'Avançado / outros recursos',
		'KernelSU Features': 'Recursos do KernelSU',
		'Module Control': 'Controle de módulos',
		'Enabled Features In Kernel': 'Recursos ativados no kernel',
		'BRENE Logs': 'Logs do BRENE',
		'Kernel Version': 'Versão do kernel',
		'..5.u.S Status': 'Status do ..5.u.S',
		'SELinux Status': 'Status do SELinux',
		or: 'ou',
		'Status: Not installed': 'Status: Não instalado',
		'Status: Not installed ✅': 'Status: Não instalado ✅',
		'Status: Installed ✅': 'Status: Instalado ✅',
		'Status: Installed ❌': 'Status: Instalado ❌',
		'Found ❌': 'Encontrado ❌',
		'Not found ✅': 'Não encontrado ✅',
		'Developer Options': 'Opções do desenvolvedor',
		'Enable or disable developer options': 'Ativar ou desativar as opções do desenvolvedor',
		'USB Debugging': 'Depuração USB',
		'Enable or disable USB debugging': 'Ativar ou desativar a depuração USB',
		'Wireless Debugging': 'Depuração sem fio',
		'Enable or disable wireless debugging': 'Ativar ou desativar a depuração sem fio',
		'Important Notes:': 'Notas importantes:',
		'Only effective for umounted process with uid ≥ 10.000': 'Só tem efeito em processos marcados como umounted com uid ≥ 10.000',
		'Non-standard /sdcard': '/sdcard fora do padrão',
		'Standard Paths:': 'Caminhos padrão:',
		'Example:': 'Exemplo:',
		'Example of detections:': 'Exemplos de detecção:',
		'Non-standard /sdcard/Android': '/sdcard/Android fora do padrão',
		'Hide Suspicious Mounts For Non-su Processes': 'Ocultar mounts suspeitos para processos non-su',
		'Prevent zygote from caching the sus mounts in memory, and to keep them hidden from /proc/self/[mounts|mountinfo|mountstat] for non-su processes':
			'Impede que o zygote mantenha mounts suspeitos em memória e os mantém ocultos de /proc/self/[mounts|mountinfo|mountstat] para processos non-su',
		'Umount Suspicious Mounts (2B)': 'Desmontar mounts suspeitos (2B)',
		'Umount Suspicious Mounts (500K, old SuSFS patches)': 'Desmontar mounts suspeitos (500K, patches SuSFS antigos)',
		'Injections Hiding': 'Ocultação de injeções',
		'Added real file path which gets mmapped will be hidden from /proc/self/[maps|smaps|smaps_rollup|map_files|mem|pagemap]':
			'O caminho real do arquivo mapeado via mmap será ocultado de /proc/self/[maps|smaps|smaps_rollup|map_files|mem|pagemap]',
		'- It does NOT support hiding for anon memory.': '- NÃO oferece suporte para ocultar memória anônima.',
		'- It does NOT hide any inline hooks or plt hooks cause by the injected library itself': '- NÃO oculta inline hooks ou hooks PLT causados pela própria biblioteca injetada',
		'- It may not be able to evade detections by apps that implement a good injection detection':
			'- Pode não conseguir evitar detecções feitas por apps com uma boa detecção de injeção',
		'Added path and all its sub-paths will be hidden for umounted app process from several syscalls':
			'O caminho adicionado e todos os seus subcaminhos serão ocultados de vários syscalls para processos de app marcados como umounted',
		'Please be reminded that if the target path has upper mounts then make sure the proper layer is added, otherwise it may not be effective for the target process':
			'Se o caminho de destino tiver mounts superiores, confirme que a camada correta foi adicionada; caso contrário, isso pode não funcionar no processo de destino',
		"For paths that are read-only all the time, add them via 'add_sus_path'": "Para caminhos sempre somente leitura, adicione-os via 'add_sus_path'",
		'The only difference to add_sus_path is that the added sus_path via this cli will be flagged as SUS_PATH again for the app process when it is being spawned by zygote and marked umounted':
			'A única diferença em relação ao add_sus_path é que o sus_path adicionado por esta CLI será marcado novamente como SUS_PATH para o processo do app quando ele for iniciado pelo zygote e marcado como umounted',
		'Also it does not check if the path is existed or not, instead it checks for empty string only, so be careful what to add':
			'Ele também não verifica se o caminho existe; apenas verifica se a string está vazia, então tenha cuidado com o que adicionar',
		"For paths that are frequently modified, we can add them via 'add_sus_path_loop'": "Para caminhos modificados com frequência, podemos adicioná-los via 'add_sus_path_loop'",
		APPLY: 'APLICAR',
		RESET: 'REDEFINIR',
		'AVC Log Spoofing': 'Mascaramento do log AVC',
		"Spoof the sus tcontext 'su' with 'u:r:priv_app:s0:c512,c768' shown in avc log in kernel":
			"Mascarar o tcontext suspeito 'su' com 'u:r:priv_app:s0:c512,c768' mostrado no log AVC do kernel",
		'Enabling this may sometimes make developers hard to identify the cause when they are debugging with some permission or selinux issues, so users are advised to disable this when doing so':
			'Ativar isso pode dificultar a identificação da causa ao depurar permissões ou problemas de SELinux, então é recomendado desativar durante esse tipo de depuração',
		'/proc/cmdline or /proc/bootconfig Spoofing': 'Mascaramento de /proc/cmdline ou /proc/bootconfig',
		'Spoof the output of /proc/cmdline (non-gki) or /proc/bootconfig (gki) from a text file':
			'Mascarar a saída de /proc/cmdline (non-GKI) ou /proc/bootconfig (GKI) a partir de um arquivo de texto',
		"No root process detects it for now, and this spoofing won't help much actually":
			'Nenhum processo root detecta isso por enquanto, e esse mascaramento não ajuda muito na prática',
		'Android System Properties Spoofing': 'Mascaramento de propriedades do sistema Android',
		'Spoof some android system properties': 'Mascarar algumas propriedades do sistema Android',
		'Uname Spoofing': 'Mascaramento de uname',
		'Spoof uname for all processes': 'Mascarar uname para todos os processos',
		"Only 'release' and 'version' are spoofed as others are no longer needed": "Apenas 'release' e 'version' são mascarados, pois os outros não são mais necessários",
		'Custom Uname Spoofing': 'Mascaramento personalizado de uname',
		"Spoof uname for all processes, set string to 'default' to imply the function to use original string":
			"Mascarar uname para todos os processos; defina a string como 'default' para indicar que a função deve usar a string original",
		'Kernel Release': 'Release do kernel',
		'Verified Boot Hash': 'Hash do Verified Boot',
		'Remove Custom ROM Properties': 'Remover propriedades de ROM personalizada',
		'Some LineageOS, CrDroid and Halcyon properties': 'Algumas propriedades do LineageOS, CrDroid e Halcyon',
		'Remove Play Integrity Fix Properties': 'Remover propriedades do Play Integrity Fix',
		'Some Play Integrity Fix properties': 'Algumas propriedades do Play Integrity Fix',
		'Enable or disable BRENE Logs': 'Ativar ou desativar os logs do BRENE',
		'SuSFS Logs': 'Logs do SuSFS',
		'Enable or disable SuSFS log in kernel': 'Ativar ou desativar o log do SuSFS no kernel',
		'SELinux Enforcing': 'SELinux enforcing',
		'Enable or disable SELinux enforcing mode': 'Ativar ou desativar o modo enforcing do SELinux',
		'SU Compat': 'Compatibilidade SU',
		"SU Compatibility Mode - allows authorized apps to gain root via traditional 'su' command":
			"Modo de compatibilidade SU - permite que apps autorizados obtenham root pelo comando tradicional 'su'",
		'WARNING: Old SuSFS patches need this option enabled to work': 'AVISO: patches SuSFS antigos precisam desta opção ativada para funcionar',
		'WARNING:': 'AVISO:',
		'Kernel Umount': 'Kernel Umount',
		'Kernel Umount - controls whether kernel automatically unmounts modules when not needed':
			'Kernel Umount - controla se o kernel desmonta módulos automaticamente quando eles não são necessários',
		'- Old SuSFS patches need this option enabled to work': '- Patches SuSFS antigos precisam desta opção ativada para funcionar',
		'- Umount Suspicious Mounts need this option enabled to work': '- Desmontar mounts suspeitos precisa desta opção ativada para funcionar',
		'Disable Modules': 'Desativar módulos',
		'Enable Modules': 'Ativar módulos',
		'Failed to load': 'Falha ao carregar',
		'Failed to load enabled features': 'Falha ao carregar recursos ativados',
		'Failed to load logs': 'Falha ao carregar logs',
		'Failed to update config': 'Falha ao atualizar configuração',
		'Failed to load config': 'Falha ao carregar configuração',
		'No need to reboot': 'Não precisa reiniciar',
		Success: 'Sucesso',
		unknown: 'desconhecido',
	},
}

const textNodeSources = new WeakMap()
let currentLanguage = defaultLanguage

function normalizeText(value) {
	return value.replace(/\s+/g, ' ').trim()
}

function getInitialLanguage() {
	try {
		const stored = localStorage.getItem(storageKey)
		if (languages.some(({ code }) => code === stored)) return stored
	} catch (e) {}

	const browserLanguage = navigator.language || navigator.userLanguage || defaultLanguage
	const normalizedBrowserLanguage = browserLanguage.toLowerCase()

	return languages.find(({ code }) => normalizedBrowserLanguage === code.toLowerCase() || normalizedBrowserLanguage.startsWith(`${code.toLowerCase()}-`))?.code || defaultLanguage
}

function getTranslation(source) {
	const key = normalizeText(source)
	return translations[currentLanguage]?.[key] || translations[defaultLanguage]?.[key] || key
}

function translateNodeText(node) {
	const source = textNodeSources.get(node) || normalizeText(node.nodeValue)
	if (!source) return

	textNodeSources.set(node, source)

	const leadingWhitespace = node.nodeValue.match(/^\s*/)?.[0] || ''
	const trailingWhitespace = node.nodeValue.match(/\s*$/)?.[0] || ''
	node.nodeValue = `${leadingWhitespace}${getTranslation(source)}${trailingWhitespace}`
}

function shouldTranslateTextNode(node) {
	const parentElement = node.parentElement
	if (!parentElement) return false
	if (!normalizeText(node.nodeValue)) return false

	return !parentElement.closest('script, style, textarea, pre, code, md-filled-text-field, md-outlined-text-field, [data-no-i18n], [data-i18n-text]')
}

function datasetKeyForAttribute(attribute) {
	return `i18nSource${attribute
		.split('-')
		.map((part) => part.charAt(0).toUpperCase() + part.slice(1))
		.join('')}`
}

function translateAttributes(root) {
	const attributeNames = ['label', 'placeholder', 'aria-label']
	const selector = attributeNames.map((attribute) => `[${attribute}]`).join(',')

	root.querySelectorAll(selector).forEach((element) => {
		attributeNames.forEach((attribute) => {
			if (!element.hasAttribute(attribute)) return

			const datasetKey = datasetKeyForAttribute(attribute)
			const source = element.dataset[datasetKey] || element.getAttribute(attribute)

			element.dataset[datasetKey] = source
			const translated = getTranslation(source)
			element.setAttribute(attribute, translated)

			if (attribute in element) {
				element[attribute] = translated
			}
		})
	})
}

function translateTextNodes(root) {
	const walker = document.createTreeWalker(root.body || root, NodeFilter.SHOW_TEXT, {
		acceptNode: (node) => (shouldTranslateTextNode(node) ? NodeFilter.FILTER_ACCEPT : NodeFilter.FILTER_REJECT),
	})

	while (walker.nextNode()) {
		translateNodeText(walker.currentNode)
	}
}

function translateDynamicText(root) {
	root.querySelectorAll('[data-i18n-text]').forEach((element) => {
		element.textContent = getTranslation(element.dataset.i18nText)
	})
}

function applyTranslations(root = document) {
	translateAttributes(root)
	translateDynamicText(root)
	translateTextNodes(root)
	document.documentElement.lang = currentLanguage
}

function setupLanguageSelect(languageSelectId) {
	const select = document.getElementById(languageSelectId)
	if (!select) return

	select.innerHTML = ''
	languages.forEach(({ code, label }) => {
		const option = document.createElement('option')
		option.value = code
		option.textContent = label
		select.append(option)
	})

	select.value = currentLanguage
	select.addEventListener('change', () => {
		setLanguage(select.value)
	})
}

export function initI18n({ languageSelectId = 'language_select' } = {}) {
	currentLanguage = getInitialLanguage()
	setupLanguageSelect(languageSelectId)
	applyTranslations()
}

export function setLanguage(language) {
	currentLanguage = languages.some(({ code }) => code === language) ? language : defaultLanguage

	try {
		localStorage.setItem(storageKey, currentLanguage)
	} catch (e) {}

	applyTranslations()
	window.dispatchEvent(new CustomEvent('brene:languagechange', { detail: { language: currentLanguage } }))
}

export function t(source) {
	return getTranslation(source)
}

export function setText(element, source) {
	if (!element) return

	element.dataset.i18nText = normalizeText(source)
	element.textContent = getTranslation(source)
}
