
module.exports =
	pattern: /^http:\/\/.*\/attachment\.php\?aid=\d+$/
	parse: (url) ->
		[type: 'torrent_url', url: url]
