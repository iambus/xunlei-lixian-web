
{Widget} = require("sdk/widget")
{Panel} = require("sdk/panel")
tabs = require("sdk/tabs")
self = require("sdk/self")
context_menu = require("sdk/context-menu")
notify = require("notify")
{storage} = require("sdk/simple-storage")
{encypt_password} = require('lixian').utils
{prefs} = require("sdk/simple-prefs")
_ = require('sdk/l10n').get

lixian_sites = require 'lixian/sites'

widget_menu = require 'widget_menu'

login_panel = Panel
	width: 200
	height: 180
	contentURL: self.data.url('content/login.html')
	contentScriptFile: self.data.url('content/login.js')

verification_code_panel = Panel
	width: 200
	height: 140
	contentURL: self.data.url('content/verification_code.html')
	contentScriptFile: self.data.url('content/verification_code.js')

task_panel = Panel
	width: 200
	height: 220
	contentURL: self.data.url('content/task.html')
	contentScriptFile: self.data.url('content/task.js')

login_panel.port.on 'login', ({username, password, save, verification_code}) ->
	if password
		password = encypt_password password
	if save
		storage.username = username
		storage.password = password
	storage.save = save
	callback = login_panel.callback
	login_panel.callback = undefined
	login_panel.hide()
	callback? username: username, password: password, verification_code: verification_code

require_login = ({username, password, verification_code}, callback) ->
	if not username
		if storage.save
			username = storage.username
	if not password
		if storage.save
			password = storage.password
	save = storage.save
	username = username or client.get_cookie('.xunlei.com', 'usernewno') or client.last_username
	login_panel.callback = callback
	login_panel.port.emit 'login', username: username, password: password, save: save, verification_code: verification_code
	login_panel.show()

verification_code_panel.port.on 'verify', (verification_code) ->
	callback = verification_code_panel.callback
	verification_code_panel.callback = undefined
	verification_code_panel.hide()
	callback? verification_code

require_verification_code = (callback) ->
	verification_code_panel.callback = callback
	verification_code_panel.port.emit 'verify'
	verification_code_panel.show()

widget_id = 'iambus-xunlei-lixian-web-firefox'

widget = Widget
	id: widget_id
	label: _('widget_label')
	contentURL: self.data.url('lixian.ico')
	contentScriptWhen: 'ready',
	contentScriptFile: self.data.url('content/widget.js')
	panel: task_panel
	onClick: (view) ->
#		tabs.open("http://lixian.vip.xunlei.com/task.html")
		task_panel.port.emit 'show'

task_panel.port.on 'refresh', (page_index) ->
	client.list_tasks_by 4, page_index, 10, (result) ->
		if result.ok
			task_panel.port.emit 'tasks', result
		else
			notify type: 'error', message:  _('list_error', if result.detail?.length < 80 then result.detail else result.reason ? '')
			console.log result.response

task_panel.port.on 'resize', ({width, height}) ->
	if not width?
		width = task_panel.width
	if not height?
		height = task_panel.height
	task_panel.resize width, height

task_panel.port.on 'download', (task) ->
	if task.type != 'bt'
		download_with ok: true, tasks: [task]
	else
		client.list_bt task, (result) ->
			if result.ok
				download_with ok: true, tasks: result.files
			else
				download_with result

task_panel.port.on 'play', (task) ->
	url = "http://vod.lixian.xunlei.com/share.html?from=lxweb&url=#{encodeURIComponent task.original_url}&filename=#{encodeURIComponent task.filename}&userid=#{client.get_id_from_cookie()}&gcid=#{task.gcid}&cid=#{task.cid}&isvip=1"

	{Cc, Ci} = require("chrome")
	io_service = Cc["@mozilla.org/network/io-service;1"].getService(Ci.nsIIOService)
	referer = io_service.newURI('http://dynamic.cloud.vip.xunlei.com/user_task', null, null)

	gBrowser = require('sdk/window/utils').getMostRecentBrowserWindow().gBrowser
	gBrowser.selectedTab = gBrowser.addTab url, {referrerURI: referer}

task_panel.port.on 'delete', (id) ->
	client.delete_task_by_id id, (result) ->
		if result.ok
			notify type: 'success', message:  _('delete_ok')
			task_panel.port.emit 'refresh'
		else
			notify type: 'error', message:  _('delete_error', result.reason), detail: result.detail ? result.response
			console.log result.response

#widget.port.on 'left-click', ->
#	tabs.open("http://lixian.vip.xunlei.com/task.html")
widget.port.on 'right-click', ->
	menu = widget_menu widget_id, 'options', [
		label: _('widget_menu_download_tool')
		items: [
			id: 'download_tool_firefox'
			label: _('widget_menu_download_tool_firefox')
			type: 'radio'
			command: ->
				prefs.download_tool = 'firefox'
		,
			id: 'download_tool_dta'
			label: _('widget_menu_download_tool_dta')
			type: 'radio'
			command: ->
				prefs.download_tool = 'dta'
		,
			id: 'download_tool_flashgot'
			label: _('widget_menu_download_tool_flashgot')
			type: 'radio'
			command: ->
				prefs.download_tool = 'flashgot'
		,
			id: 'download_tool_xthunder'
			label: _('widget_menu_download_tool_xthunder')
			type: 'radio'
			command: ->
				prefs.download_tool = 'xthunder'
		]
	,
		id: 'associate_types'
		label: _('widget_menu_associate_type')
		type: 'checkbox'
		command: ->
			prefs.associate_types = @getAttribute('checked') == 'true'
	,
		id: 'clear_user_info'
		label: _('widget_menu_clear_user_info')
		tooltip: _('widget_menu_clear_user_info_label')
		command: ->
			delete storage.username
			delete storage.password
			delete storage.save
	,
		label: _('widget_menu_web_site')
		command: -> tabs.open("http://lixian.vip.xunlei.com/task.html")
	,
		label: _('widget_menu_project_site')
		tooltip: _('widget_menu_project_site_label')
		command: -> tabs.open("https://github.com/iambus/xunlei-lixian-web")
	]
	menu_download_tool_firefox = menu.find 'download_tool_firefox'
	menu_download_tool_firefox.setAttribute 'checked', prefs.download_tool not in ['dta', 'flashgot', 'xthunder']
	menu_download_tool_dta = menu.find 'download_tool_dta'
	menu_download_tool_dta.setAttribute 'checked', prefs.download_tool == 'dta'
	menu_download_tool_dta.setAttribute 'disabled', not download_tools.dta
	menu_download_tool_flashgot = menu.find 'download_tool_flashgot'
	menu_download_tool_flashgot.setAttribute 'checked', prefs.download_tool == 'flashgot'
	menu_download_tool_flashgot.setAttribute 'disabled', not download_tools.flashgot
	menu_download_tool_xthunder = menu.find 'download_tool_xthunder'
	menu_download_tool_xthunder.setAttribute 'checked', prefs.download_tool == 'xthunder'
	menu_download_tool_xthunder.setAttribute 'disabled', not download_tools.xthunder
	menu_associate_types = menu.find 'associate_types'
	menu_associate_types.setAttribute 'checked', prefs.associate_types
	menu.show()

client = require('client').create()
client.username = storage.username
client.password = storage.password
client.require_login = require_login
client.require_verification_code = require_verification_code
client.auto_relogin = true

download_tools = require('download_tools')

download_with = ({ok, tasks, finished, skipped, reason, detail, response}) ->
	download_tool = download_tools.get() # TODO: check download tool before requests
	if ok
		finished = finished ? (t for t in tasks when t.status_text == 'completed')
		skipped = skipped ? (t for t in tasks when t.status_text != 'completed')
		if finished.length > 0
			notify type: 'success', message: _('download_status_done')
			download_tool tasks
			if skipped.length > 0
				notify type: 'warning', message: _('download_warning_skipped')
		else
			if tasks.length > 0
				notify type: 'warning', message: _('download_error_task_not_ready')
			else
				notify type: 'error', message: _('download_error_task_not_found'), detail: detail ? response
	else
		notify type: 'error', message:  _('download_error', if detail?.length < 80 then detail else reason ? ''), detail: detail ? response
		console.log response

download = (urls) ->
	if Object.prototype.toString.call(urls) == '[object String]'
		urls = [urls]
	if urls?.length > 0
		urls = lixian_sites.parse_all urls
		client.super_get urls, download_with

download_bt = (url) ->
	client.super_get type: 'torrent_url', url: url, download_with

context_menu.Item
	label: _('context_menu_download_link')
	image: self.data.url('lixian.ico')
	context: context_menu.SelectorContext('a[href]')
	contentScriptFile: self.data.url('content/menu/link.js')
	onMessage: (url) ->
		if url.match /\.torrent$/i
			download_bt url
		else
			download [url]

context_menu.Item
	label: _('context_menu_download_selection')
	image: self.data.url('lixian.ico')
	context: context_menu.SelectionContext()
	contentScriptFile: self.data.url('content/menu/text.js')
	onMessage: (urls) ->
		download urls

context_menu.Item
	label: _('context_menu_download_site')
	image: self.data.url('lixian.ico')
	context: context_menu.URLContext(lixian_sites.urls)
	contentScriptFile: self.data.url('content/menu/site.js')
	onMessage: (url) ->
		urls = lixian_sites.parse url
		if urls?
			download urls


API =
	download_url: (url) -> download [url]

require('api') API
require('protocol').setup()


#exports.onUnload = ->

