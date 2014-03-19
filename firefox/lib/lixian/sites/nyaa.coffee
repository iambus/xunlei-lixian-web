
pattern = /^http:\/\/sukebei.nyaa.(?:eu|se)\/\?page=(?:view|torrentinfo)&tid=(\d+)\b.*$/

to_torrent_url = (url) ->
	tid = url.match(pattern)?[1]
	if tid?
		type: 'torrent_url'
		url: "http://sukebei.nyaa.se/?page=download&tid=#{tid}&txt=1"

module.exports =
	pattern: pattern
	parse: (url) ->
		[to_torrent_url(url)]
