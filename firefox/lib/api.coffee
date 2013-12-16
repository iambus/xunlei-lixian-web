
every_window = (callback) ->
	for w in require('sdk/window/utils').windows()
		if w.document.documentElement.getAttribute('windowtype') == 'navigator:browser' and w.location.href == 'chrome://browser/content/browser.xul'
			callback w

	require('sdk/system/events').on 'toplevel-window-ready', (event) ->
		w = event.subject
		if w.document.documentElement.getAttribute('windowtype') == 'navigator:browser' and w.location.href == 'chrome://browser/content/browser.xul'
			callback w
	, true # XXX: should I release it manually?

API_KEY = 'XUNLEI_LIXIAN_WEB'

module.exports = (api) ->
	every_window (w) ->
		w[API_KEY] = api
