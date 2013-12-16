
_ = require('sdk/l10n').get

{Cc, Ci, Cu} = require("chrome")

Cu.import('resource://gre/modules/Services.jsm')

window_utils = require('sdk/window/utils')
{storage} = require("sdk/simple-storage")

NS_XUL = 'http://www.mozilla.org/keymaster/gatekeeper/there.is.only.xul'

###############
# single file #
###############

download_file = (url) ->
	channel = Services.io.newChannelFromURI Services.io.newURI(url, null, null)
	uri_loader = Cc["@mozilla.org/uriloader;1"].createInstance(Ci.nsIURILoader)
	uri_loader.openURI channel, true, window_utils.getWindowDocShell window_utils.getMostRecentBrowserWindow()

download_single_task = (task) ->
	download_file task.download_url

################
# single files #
################

get_output_folder_list = ->
	folders = storage.output_directories
	if folders?
		return folders
	download_manager = Cc["@mozilla.org/download-manager;1"].getService(Ci.nsIDownloadManager)
	# TODO: use browser.download.lastDir
	return [download_manager.userDownloadsDirectory?.path ? download_manager.defaultDownloadsDirectory.path]

save_output_folder = (dir) ->
	dirs = storage.output_directories ? []
	if dirs[0] == dir
		return
	for d, i in dirs
		if d == dir
			dirs.splice(i, 1)
			break
	dirs.unshift dirs
	storage.output_directories = dirs

select_folder = (win, default_dir, callback) ->
	if arguments.length == 1
		callback = arguments[0]
		win = window_utils.getMostRecentBrowserWindow()
		default_dir = null
	file_picker = Cc["@mozilla.org/filepicker;1"].createInstance(Ci.nsIFilePicker)
	file_picker.init(win, null, Ci.nsIFilePicker.modeGetFolder)
	if default_dir?
		try
			dir = Cc["@mozilla.org/file/local;1"].createInstance(Ci.nsILocalFile)
			dir.initWithPath default_dir
			file_picker.displayDirectory = dir
		catch e
			# ignore invalid path
			console.error e
	file_picker.open
		done: (v) ->
			if v == 0
				callback file_picker.file

download_tasks_via_dta = (tasks, folder) ->
	dta = require('download_tools').dta
	if not dta?
		require('notify') type: 'error', message: _('download_tool_firefox_error_multiple_file_no_dta')
		return
	dta.download_tasks_to_dir tasks, folder

download_multiple_tasks_simply = (tasks) ->
	dta = require('download_tools').dta
	if not dta?
		require('notify') type: 'error', message: _('download_tool_firefox_error_multiple_file_no_dta')
		return
	select_folder (folder) ->
		dta.download_tasks_to_dir tasks, folder.path

download_multiple_tasks_review = (tasks) ->
	win = window_utils.openDialog
		url: 'chrome://xunlei-lixian-web/content/multiselect.xul'
		features: 'centerscreen,resizable'
#	win = window_utils.open 'chrome://xunlei-lixian-web/content/multiselect.xul',
#		features: 'centerscreen,resizable'
	setup_dialog = ->
		win.load tasks

		doc = win.document
		menulist = doc.getElementById 'output'
		folders = get_output_folder_list()
		menulist.value = folders[0]
		menupopup = menulist.getElementsByTagName('menupopup')[0]
		for folder in folders
			menuitem = doc.createElementNS NS_XUL, 'menuitem'
			menuitem.setAttribute 'value', folder
			menuitem.setAttribute 'label', folder
			menupopup.appendChild menuitem

		doc.getElementById('browse').addEventListener 'click', ->
			select_folder win, menulist.value, (file) ->
				menulist.value = file.path

		win.onsave = (tasks) ->
			folder = menulist.value
			if require('sdk/io/file').exists folder
				download_tasks_via_dta tasks, folder
				save_output_folder folder
			else
				require('notify') type: 'error', message: _('download_tool_firefox_error_folder_does_not_exist', folder)

		win.oncancel = ->

	win.addEventListener 'load', setup_dialog

download_multiple_tasks = (tasks) ->
#	download_multiple_tasks_simply tasks
	download_multiple_tasks_review tasks

download_tasks = (tasks) ->
	if tasks.length == 0
		return
	else if tasks.length == 1
		download_single_task tasks[0]
	else
		download_multiple_tasks tasks


module.exports =
	download_tasks: download_tasks

