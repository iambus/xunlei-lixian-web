

firefox = require('download_tool/firefox')
dta = require('download_tool/dta')
flashgot = require('download_tool/flashgot')
xthunder = require('download_tool/xthunder')

simple_prefs = require("sdk/simple-prefs")

tools =
	firefox: firefox
	dta: dta
	flashgot: flashgot
	xthunder: xthunder

get_download_tool = ->
	tool = tools[simple_prefs.prefs.download_tool] ? firefox
	return tool.download_tasks

simple_prefs.on 'download_tool', ->
	if not tools[simple_prefs.prefs.download_tool]
		require('notify').error require('sdk/l10n').get "download_tool_#{simple_prefs.prefs.download_tool}_error_not_found"
	else
		require('notify') require('sdk/l10n').get "download_tool_changed"

module.exports =
	firefox: firefox
	dta: dta
	flashgot: flashgot
	xthunder: xthunder
	get: get_download_tool
