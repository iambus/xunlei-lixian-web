
url = decodeURIComponent document.location.search.substr(1)
try
	# don't know why, just sometimes happens...
	url = decodeURIComponent url
catch e

Ci = Components.interfaces

getTopLevelWindowContext = ->
	window.QueryInterface(Ci.nsIInterfaceRequestor)
		.getInterface(Ci.nsIWebNavigation)
		.QueryInterface(Ci.nsIDocShellTreeItem)
		.rootTreeItem
		.QueryInterface(Ci.nsIInterfaceRequestor)
		.getInterface(Ci.nsIDOMWindow)

getBrowser = ->
	window.QueryInterface(Ci.nsIInterfaceRequestor).getInterface(Ci.nsIWebNavigation)

if url
	getTopLevelWindowContext().XUNLEI_LIXIAN_WEB?.download_url url

browser = getBrowser()
if browser.canGoBack
	browser.goBack()
else
	window.close()

