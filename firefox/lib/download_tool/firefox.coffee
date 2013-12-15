
_ = require('sdk/l10n').get

{Cc, Ci, Cu} = require("chrome")

Cu.import('resource://gre/modules/Services.jsm')

web_browser_persist = Cc["@mozilla.org/embedding/browser/nsWebBrowserPersist;1"].createInstance(Ci.nsIWebBrowserPersist)

window_utils = require('sdk/window/utils')

download_file = (url) ->
	channel = Services.io.newChannelFromURI Services.io.newURI(url, null, null)
	uri_loader = Cc["@mozilla.org/uriloader;1"].createInstance(Ci.nsIURILoader)
	uri_loader.openURI channel, true, window_utils.getWindowDocShell window_utils.getMostRecentBrowserWindow()

download_single_task = (task) ->
	download_file task.download_url

select_folder = (callback) ->
	file_picker = Cc["@mozilla.org/filepicker;1"].createInstance(Ci.nsIFilePicker)
	file_picker.init(window_utils.getMostRecentBrowserWindow(), null, Ci.nsIFilePicker.modeGetFolder)
	file_picker.open
		done: (v) ->
			if v == 0
				callback file_picker.file

download_multiple_tasks = (tasks) ->
	dta = require('download_tools').dta
	if not dta?
		require('notify') _('download_tool_firefox_error_multiple_file_no_dta')
		return
	select_folder (folder) ->
		dta.download_tasks_to_dir tasks, folder.path

download_tasks = (tasks) ->
	if tasks.length == 0
		return
	else if tasks.length == 1
		download_single_task tasks[0]
	else
		download_multiple_tasks tasks


module.exports =
	download_tasks: download_tasks

