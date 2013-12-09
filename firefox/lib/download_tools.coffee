

firefox = require('download_tool/firefox')
dta = require('download_tool/dta')
flashgot = require('download_tool/flashgot')
xthunder = require('download_tool/xthunder')

{prefs} = require("sdk/simple-prefs")
notifications = require("sdk/notifications")

tools =
	firefox: firefox
	dta: dta
	flashgot: flashgot
	xthunder: xthunder

get_download_tool = ->
	tool = tools[prefs.download_tool] ? firefox
	return tool.download_tasks


module.exports =
	firefox: firefox
	dta: dta
	flashgot: flashgot
	xthunder: xthunder
	get: get_download_tool
