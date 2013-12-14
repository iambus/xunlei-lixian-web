
url = decodeURIComponent document.location.search.substr(1)

getTopLevelWindowContext = ->
	Ci = Components.interfaces
	window.QueryInterface(Ci.nsIInterfaceRequestor)
		.getInterface(Ci.nsIWebNavigation)
		.QueryInterface(Ci.nsIDocShellTreeItem)
		.rootTreeItem
		.QueryInterface(Ci.nsIInterfaceRequestor)
		.getInterface(Ci.nsIDOMWindow)

if url
	getTopLevelWindowContext().XUNLEI_LIXIAN_WEB?.download_url url

window.close()

