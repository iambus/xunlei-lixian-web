
{Widget} = require("sdk/widget")
{Panel} = require("sdk/panel")
tabs = require("sdk/tabs")
self = require("sdk/self")
context_menu = require("sdk/context-menu")
notifications = require("sdk/notifications")
{storage} = require("sdk/simple-storage")
{encypt_password} = require('lixian').utils
{prefs} = require("sdk/simple-prefs")

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
	label: "迅雷离线下载"
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
		label: '下载工具'
		items: [
			id: 'download_tool_firefox'
			label: '系统'
			type: 'radio'
			command: ->
				prefs.download_tool = 'firefox'
		,
			id: 'download_tool_dta'
			label: 'DownThemAll!'
			type: 'radio'
			command: ->
				prefs.download_tool = 'dta'
		,
			id: 'download_tool_flashgot'
			label: 'FlashGot'
			type: 'radio'
			command: ->
				prefs.download_tool = 'flashgot'
		]
	,
		label: '访问迅雷离线官网'
		command: -> tabs.open("http://lixian.vip.xunlei.com/task.html")
	,
		label: '访问项目主页'
		command: -> tabs.open("https://github.com/iambus/xunlei-lixian-web")
	]
	menu_download_tool_firefox = menu.find 'download_tool_firefox'
	menu_download_tool_firefox.setAttribute 'checked', prefs.download_tool not in ['dta', 'flashgot']
	menu_download_tool_dta = menu.find 'download_tool_dta'
	menu_download_tool_dta.setAttribute 'checked', prefs.download_tool == 'dta'
	menu_download_tool_dta.setAttribute 'disabled', not dta
	menu_download_tool_flashgot = menu.find 'download_tool_flashgot'
	menu_download_tool_flashgot.setAttribute 'checked', prefs.download_tool == 'flashgot'
	menu_download_tool_flashgot.setAttribute 'disabled', not flashgot
	menu.show()

client = require('client').create()
client.username = storage.username
client.password = storage.password
client.require_login = require_login
client.auto_relogin = true

dta = require('dta')
flashgot = require('flashgot')


get_download_tool = ->
	default_tool = ->
		notifications.notify
			text: "You must install DownThemAll or FlashGot"
	if prefs.download_tool == 'dta'
		if dta?
			return dta.download_tasks
		else
			notifications.notify
				text: "DownThemAll! not installed"
			return ->
	else if prefs.download_tool == 'flashgot'
		if flashgot?
			return flashgot.download_tasks
		else
			notifications.notify
				text: "FlashGot not installed"
			return ->
	else
		return default_tool

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
							text: "Task is not ready"
					else
						notifications.notify
							text: "No task found"
			else
				notifications.notify
					text: "Error: #{reason}"
				console.log response


context_menu.Item
	label: "从迅雷离线下载此链接"
	image: self.data.url('xunlei.ico')
	context: context_menu.SelectorContext('a[href]')
	contentScriptFile: self.data.url('content/menu/link.js')
	onMessage: (url) ->
		download [url]

context_menu.Item
	label: "从迅雷离线下载选中的链接"
	image: self.data.url('xunlei.ico')
	context: context_menu.SelectionContext()
	contentScriptFile: self.data.url('content/menu/text.js')
	onMessage: (urls) ->
		download urls


#tabs.open self.data.url('sample.html')

