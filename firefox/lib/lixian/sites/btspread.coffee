

to_bt_url = (url) ->
	hash = url.match(/^http:\/\/www\.btspread\.com\/magnet\/detail\/hash\/([a-zA-Z0-9]{40})$/)?[1]
	if hash?
		"bt://#{hash.toLowerCase()}"

module.exports =
	pattern: /^http:\/\/www\.btspread\.com\/magnet\/detail\/hash\/[a-zA-Z0-9]{40}$/
	parse: (url) ->
		[to_bt_url(url)]


