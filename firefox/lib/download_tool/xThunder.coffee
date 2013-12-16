
main_window = require('sdk/window/utils').getMostRecentBrowserWindow()

xThunder = main_window.xThunder

download_tasks = (tasks) ->
	referrer = 'http://dynamic.cloud.vip.xunlei.com/'

	links = []
	for t in tasks
		if t.status_text != 'completed'
			continue
		links.push t.download_url

	xThunder.apiDownUrl referrer, links

if xThunder?
	module.exports =
		download_tasks: download_tasks
else
	module.exports = undefined
