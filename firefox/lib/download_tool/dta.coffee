
xul = require 'xul'

DTA = xul.globals.DTA
#{Cu} = require 'chrome'
#glue = {}
#Cu.import("chrome://dta-modules/content/glue.jsm", glue)
#DTA = glue.require("api")

download_tasks = (tasks) ->
	referer = 'http://dynamic.cloud.vip.xunlei.com/'

	links = []

	for t in tasks
		links.push
			url: new DTA.URL DTA.IOService.newURI t.download_url, 'utf-8', null
			referrer: referer
			fileName: t.filename
			description: t.name
			ultDescription: t.name

#	console.log links
	DTA.saveLinkArray xul.main, links, []

download_tasks_to_dir = (tasks, dirname) ->
	referer = 'http://dynamic.cloud.vip.xunlei.com/'
	numIstance = DTA.incrementSeries()
	mask = DTA.getDropDownValue 'renaming', false

	join_path = require('sdk/io/file').join

	links = []

	for t in tasks
		dir = if t.dirs?.length then join_path.call(null, dirname, t.dirs...) else dirname
		links.push
			url: new DTA.URL DTA.IOService.newURI t.download_url, 'utf-8', null
			referrer: referer
			fileName: t.filename
			dirSave: dir
			description: t.name
			ultDescription: t.name
			numIstance: numIstance
			mask: mask

#	console.log links
#	DTA.turboSendLinksToManager xul.main, links
	DTA.sendLinksToManager xul.main, true, links


if DTA?
	module.exports =
		download_tasks: download_tasks
		download_tasks_to_dir: download_tasks_to_dir
else
	module.exports = undefined
