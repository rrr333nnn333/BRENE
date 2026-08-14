/**
 * Tiny i18n runtime for the BRENE WebUI
 *
 * Markup is translated through data attributes:
 *   data-i18n             -> text content
 *   data-i18n-label       -> "label" attribute (material text fields)
 *   data-i18n-placeholder -> "placeholder" attribute
 *   data-i18n-aria-label  -> "aria-label" attribute
 *
 * Text built at runtime cannot use those attributes, so it is registered with
 * bindDynamicText() and rendered again whenever the language changes.
 */

import { en } from './en.js'
import { zhCN } from './zh-CN.js'

/**
 * Selectable languages, listed by the header select in this order
 * To add one: drop a dictionary file next to this file and append an entry here
 * "name" is shown as-is in the dropdown, so it is written in the language itself
 * "tags" are matched against the WebView languages, exact or as a "tag-" prefix
 */
export const LOCALES = [
	{ code: 'en', name: 'English', tags: ['en'], dictionary: en },
	{ code: 'zh-CN', name: '简体中文', tags: ['zh'], dictionary: zhCN },
]

const DEFAULT_LOCALE = 'en'
const STORAGE_KEY = 'brene_locale'
const TRANSLATABLE = '[data-i18n], [data-i18n-label], [data-i18n-placeholder], [data-i18n-aria-label]'

const listeners = new Set()
const dynamicNodes = new Map()

let currentLocale = DEFAULT_LOCALE

/**
 * Read a dot separated key out of a dictionary
 * @param {Object} dictionary - Dictionary to walk
 * @param {string} key - Path such as 'status.deviceModel'
 * @returns {string|undefined} The string when the whole path resolves
 */
function resolve(dictionary, key) {
	const value = key.split('.').reduce((node, part) => (node == null ? undefined : node[part]), dictionary)
	return typeof value === 'string' ? value : undefined
}

/**
 * Translate a key for the active language, falling back to English then to the key itself
 * @param {string} key - Path such as 'toast.success'
 * @param {Object} [params] - Values replacing the {placeholder} tokens of the string
 * @returns {string} The translated string
 */
export function t(key, params) {
	const locale = LOCALES.find((entry) => entry.code === currentLocale)
	const value = resolve(locale?.dictionary, key) ?? resolve(en, key) ?? key

	if (!params) return value
	return value.replace(/\{(\w+)\}/g, (token, name) => (name in params ? params[name] : token))
}

/**
 * Currently active language
 * @returns {string} A locale code listed in LOCALES
 */
export function getLocale() {
	return currentLocale
}

/**
 * Translate a single element according to its data-i18n* attributes
 * @param {Element} element - Element to translate
 * @returns {void}
 */
function translateElement(element) {
	const { i18n, i18nLabel, i18nPlaceholder, i18nAriaLabel } = element.dataset

	if (i18n) element.textContent = t(i18n)
	if (i18nLabel) element.setAttribute('label', t(i18nLabel))
	if (i18nPlaceholder) element.setAttribute('placeholder', t(i18nPlaceholder))
	if (i18nAriaLabel) element.setAttribute('aria-label', t(i18nAriaLabel))
}

/**
 * Translate every tagged element inside root, root itself included
 * @param {Element|Document} [root=document] - Subtree to translate
 * @returns {void}
 */
export function applyTranslations(root = document) {
	if (root.matches?.(TRANSLATABLE)) translateElement(root)
	root.querySelectorAll(TRANSLATABLE).forEach(translateElement)
}

/**
 * Show text built at runtime and keep it in sync with the active language
 * @param {Element} element - Element receiving the text
 * @param {() => string} render - Builds the text with whatever language is active when it runs
 * @returns {void}
 */
export function bindDynamicText(element, render) {
	dynamicNodes.set(element, render)
	element.innerText = render()
}

/**
 * Register a callback fired after the language changed and the DOM was re-translated
 * @param {(locale: string) => void} listener - Callback receiving the new locale code
 * @returns {void}
 */
export function onLocaleChange(listener) {
	listeners.add(listener)
}

/**
 * Switch the active language, persist the choice and refresh everything on screen
 * @param {string} code - Locale code listed in LOCALES
 * @returns {void}
 */
export function setLocale(code) {
	if (code === currentLocale || !LOCALES.some((locale) => locale.code === code)) return

	currentLocale = code
	try {
		localStorage.setItem(STORAGE_KEY, code)
	} catch (e) {}

	document.documentElement.lang = code
	applyTranslations()
	dynamicNodes.forEach((render, element) => {
		element.innerText = render()
	})
	listeners.forEach((listener) => listener(code))
}

/**
 * Pick the language to start with: stored choice, then the WebView language, then English
 * @returns {string} A locale code listed in LOCALES
 */
function detectLocale() {
	let stored = null
	try {
		stored = localStorage.getItem(STORAGE_KEY)
	} catch (e) {}
	if (LOCALES.some((locale) => locale.code === stored)) return stored

	const tags = navigator.languages?.length ? navigator.languages : [navigator.language]
	for (const tag of tags) {
		const normalized = String(tag || '').toLowerCase()
		const match = LOCALES.find((locale) => locale.tags.some((prefix) => normalized === prefix || normalized.startsWith(`${prefix}-`)))
		if (match) return match.code
	}

	return DEFAULT_LOCALE
}

/**
 * Resolve the starting language, fill the header language select and translate the document
 * @param {Element} [select] - The md-outlined-select the language options are rendered into
 * @returns {void}
 */
export function initI18n(select) {
	currentLocale = detectLocale()
	document.documentElement.lang = currentLocale

	if (select) {
		select.replaceChildren(
			...LOCALES.map((locale) => {
				const option = document.createElement('md-select-option')
				option.value = locale.code
				option.selected = locale.code === currentLocale

				// Language names stay written in their own language, so they are never translated
				const headline = document.createElement('div')
				headline.slot = 'headline'
				headline.textContent = locale.name
				option.appendChild(headline)

				return option
			}),
		)

		select.addEventListener('change', () => setLocale(select.value))
		onLocaleChange((code) => {
			if (select.value !== code) select.value = code
		})
	}

	applyTranslations()
}
