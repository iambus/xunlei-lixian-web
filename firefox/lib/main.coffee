
{Widget} = require("sdk/widget")
{Panel} = require("sdk/panel")
tabs = require("sdk/tabs")
self = require("sdk/self")
context_menu = require("sdk/context-menu")
notifications = require("sdk/notifications")
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
		]
	,
		label: _('widget_menu_web_site')
		command: -> tabs.open("http://lixian.vip.xunlei.com/task.html")
	,
		label: _('widget_menu_project_site')
		command: -> tabs.open("https://github.com/iambus/xunlei-lixian-web")
	]
	menu_download_tool_firefox = menu.find 'download_tool_firefox'
	menu_download_tool_firefox.setAttribute 'checked', prefs.download_tool not in ['dta', 'flashgot']
	menu_download_tool_dta = menu.find 'download_tool_dta'
	menu_download_tool_dta.setAttribute 'checked', prefs.download_tool == 'dta'
	menu_download_tool_dta.setAttribute 'disabled', not download_tools.dta
	menu_download_tool_flashgot = menu.find 'download_tool_flashgot'
	menu_download_tool_flashgot.setAttribute 'checked', prefs.download_tool == 'flashgot'
	menu_download_tool_flashgot.setAttribute 'disabled', not download_tools.flashgot
	menu.show()

client = require('client').create()
client.username = storage.username
client.password = storage.password
client.require_login = require_login
client.auto_relogin = true

download_tools = require('download_tools')

get_download_tool = ->
#	default_tool = ->
#		notifications.notify
#			text: "You must install DownThemAll or FlashGot"
	if prefs.download_tool == 'dta'
		if download_tools.dta?
			return download_tools.dta.download_tasks
		else
			notifications.notify
				text: _('download_tool_dta_error_not_found')
			return ->
	else if prefs.download_tool == 'flashgot'
		if download_tools.flashgot?
			return download_tools.flashgot.download_tasks
		else
			notifications.notify
				text: _('download_tool_flashgot_error_not_found')
			return ->
	else
		return download_tools.firefox.download_tasks

download = (urls) ->
	if Object.prototype.toString.call(urls) == '[object String]'
		urls = [urls]
	if urls?.length > 0
		download_tool = get_download_tool()
		client.super_get urls, ({ok, tasks, finished, reason, response}) ->
			if ok
				if finished.length > 0
					download_tool finished
				else
					if tasks.length > 0
						notifications.notify
							text:  _('download_error_task_not_ready')
					else
						notifications.notify
							text: _('download_error_task_not_found')
			else
				notifications.notify
					text: "Error: #{reason}"
				console.log response


context_menu.Item
	label: _('context_menu_download_link')
	image: self.data.url('xunlei.ico')
	context: context_menu.SelectorContext('a[href]')
	contentScriptFile: self.data.url('content/menu/link.js')
	onMessage: (url) ->
		download [url]

context_menu.Item
	label: _('context_menu_download_selection')
	image: self.data.url('xunlei.ico')
	context: context_menu.SelectionContext()
	contentScriptFile: self.data.url('content/menu/text.js')
	onMessage: (urls) ->
		download urls


#tabs.open self.data.url('sample.html')

#exports.onUnload = ->

