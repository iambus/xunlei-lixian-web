
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
			fileName: t.name
			description: t.name
			ultDescription: t.name

#	console.log links
	DTA.saveLinkArray xul.main, links, []


if DTA?
	module.exports =
		download_tasks: download_tasks
else
	module.exports = undefined
