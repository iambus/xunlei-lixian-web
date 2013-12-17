
_ = require('sdk/l10n').get

{Cc, Ci, Cu} = require("chrome")

Cu.import('resource://gre/modules/Services.jsm')
download_manager = Cc["@mozilla.org/download-manager;1"].getService(Ci.nsIDownloadManager)

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

##################
# multiple files #
##################

get_output_folder_list = ->
	folders = storage.output_directories
	if folders?
		return folders
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
	dirs.unshift dir
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

download_tasks_via_firefox = (tasks, folder) ->
	io_file = require('sdk/io/file')
	download1 = (url, path) ->
		# TODO: escape invalid filenames
		dir = io_file.dirname path
		io_file.mkpath dir
		web_browser_persist = Cc["@mozilla.org/embedding/browser/nsWebBrowserPersist;1"].createInstance(Ci.nsIWebBrowserPersist)
		uri = Services.io.newURI url, 'utf-8', null
		file = Cc["@mozilla.org/file/local;1"].createInstance(Ci.nsILocalFile)
		file.initWithPath path
		download = download_manager.addDownload download_manager.DOWNLOAD_TYPE_DOWNLOAD,
			uri
			Services.io.newFileURI(file)
			null
			null
			Math.round(Date.now() * 1000)
			null
			web_browser_persist
			false # TODO: set aIsPrivate
		web_browser_persist.progressListener = download.QueryInterface(Ci.nsIWebProgressListener)
		web_browser_persist.saveURI download.source,
			null
			null
			null
			null
			download.targetFile
			null # XXX: there is a warning in documentation about setting aPrivacyContext to null, but I don't know how to fix it.
	for t in tasks
		if t.status_text == 'completed'
			path = io_file.join.apply(null, [folder].concat t.full_path.split('/'))
			download1 t.download_url, path
	return

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

		dta = require('download_tools').dta
		if dta?
			doc.getElementById('tool').value = 'dta'
		else
			doc.getElementById('tool-dta').disabled = true
			if tasks.length > 5
				require('notify') type: 'warning', message: _('download_tool_firefox_warning_dta_not_installed')

		doc.getElementById('tool-firefox').addEventListener 'command', ->
			if tasks.length > 5
				require('notify') type: 'warning', message: _('download_tool_firefox_warning_not_recommended')

		win.onsave = (tasks) ->
			folder = menulist.value
			if require('sdk/io/file').exists folder
				if doc.getElementById('tool').value == 'dta'
					download_tasks_via_dta tasks, folder
				else
					download_tasks_via_firefox tasks, folder
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

