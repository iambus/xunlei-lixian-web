
xul = require 'xul'

xThunder = xul.globals.xThunder

download_tasks = (tasks) ->
	referrer = 'http://dynamic.cloud.vip.xunlei.com/'

	links = []
	for t in tasks
		links.push t.download_url

	xThunder.apiDownUrl referrer, links


module.exports =
	download_tasks: download_tasks
