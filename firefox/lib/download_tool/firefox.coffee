

{Cc, Ci, Cu} = require("chrome")

Cu.import('resource://gre/modules/Services.jsm')

web_browser_persist = Cc["@mozilla.org/embedding/browser/nsWebBrowserPersist;1"].createInstance(Ci.nsIWebBrowserPersist)

window_utils = require('sdk/window/utils')

download_file = (url) ->
	channel = Services.io.newChannelFromURI Services.io.newURI(url, null, null)
	uri_loader = Cc["@mozilla.org/uriloader;1"].createInstance(Ci.nsIURILoader)
	uri_loader.openURI channel, true, window_utils.getWindowDocShell window_utils.getMostRecentBrowserWindow()

download_tasks = (tasks) ->
	if tasks.length == 0
		return
	else if tasks.length == 1
		download_file tasks[0].download_url
	else
		require("sdk/notifications").notify
			text: "系统自带的下载工具只能下载单个文件"


module.exports =
	download_tasks: download_tasks

