
{Cc, Ci} = require("chrome")
window_mediator = Cc["@mozilla.org/appshell/window-mediator;1"].getService(Ci.nsIWindowMediator)

get_xul_dom_window_by_href = (href) ->
	e = window_mediator.getXULWindowEnumerator(null)
	while e.hasMoreElements()
		w = e.getNext().QueryInterface(Ci.nsIXULWindow).docShell.QueryInterface(Ci.nsIInterfaceRequestor).getInterface(Ci.nsIDOMWindow)
		console.log w.location.href
	e = window_mediator.getXULWindowEnumerator(null)
	while e.hasMoreElements()
		w = e.getNext().QueryInterface(Ci.nsIXULWindow).docShell.QueryInterface(Ci.nsIInterfaceRequestor).getInterface(Ci.nsIDOMWindow)
		if w.location.href == href
			return w
	return

#main_xul_dom_window = get_xul_dom_window_by_href 'chrome://browser/content/browser.xul'
#main_xul_dom_window = window_mediator.getMostRecentWindow 'navigator:browser'
main_xul_dom_window = require('sdk/window/utils').getMostRecentBrowserWindow()

module.exports =
	get_xul_dom_window_by_href: get_xul_dom_window_by_href
	main: main_xul_dom_window
	globals: main_xul_dom_window ? {}
