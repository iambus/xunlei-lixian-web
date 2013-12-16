
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

widget_menu = require 'widget_menu'

login_panel = Panel
	width: 200
	height: 140
	contentURL: self.data.url('content/login.html')
	contentScriptFile: self.data.url('content/login.js')

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

widget_id = 'iambus-xunlei-lixian-web-firefox'

widget = Widget
	id: widget_id
	label: _('widget_label')
	contentURL: self.data.url('xunlei.ico')
	contentScriptWhen: 'ready',
	contentScriptFile: self.data.url('content/widget.js')
#	panel: login_panel
#	onClick: (view) ->
#		tabs.open("http://lixian.vip.xunlei.com/task.html")
widget.port.on 'left-click', ->
	tabs.open("http://lixian.vip.xunlei.com/task.html")
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
		label: _('widget_menu_web_site')
		command: -> tabs.open("http://lixian.vip.xunlei.com/task.html")
	,
		label: _('widget_menu_project_site')
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
client.auto_relogin = true

download_tools = require('download_tools')

download_with = ({ok, tasks, finished, skipped, reason, response}) ->
	download_tool = download_tools.get() # TODO: check download tool before requests
	if ok
		if finished.length > 0
			notify type: 'success', message: _('download_status_done')
			download_tool tasks
			if skipped.length > 0
				notify type: 'warning', message: _('download_warning_skipped')
		else
			if tasks.length > 0
				notify type: 'warning', message: _('download_error_task_not_ready')
			else
				notify type: 'error', message: _('download_error_task_not_found')
	else
		notify type: 'error', message:  _('download_error', reason)
		console.log response

download = (urls) ->
	if Object.prototype.toString.call(urls) == '[object String]'
		urls = [urls]
	if urls?.length > 0
		client.super_get urls, download_with

download_bt = (url) ->
	client.super_get_bt url, download_with

context_menu.Item
	label: _('context_menu_download_link')
	image: self.data.url('xunlei.ico')
	context: context_menu.SelectorContext('a[href]')
	contentScriptFile: self.data.url('content/menu/link.js')
	onMessage: (url) ->
		if url.match /\.torrent$/i
			download_bt url
		else
			download [url]

context_menu.Item
	label: _('context_menu_download_selection')
	image: self.data.url('xunlei.ico')
	context: context_menu.SelectionContext()
	contentScriptFile: self.data.url('content/menu/text.js')
	onMessage: (urls) ->
		download urls


API =
	download_url: (url) -> download [url]

require('api') API
require('protocol').setup()


#exports.onUnload = ->

