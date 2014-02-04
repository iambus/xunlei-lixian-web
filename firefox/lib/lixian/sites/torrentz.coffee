

to_bt_url = (url) ->
	hash = url.match(/^http:\/\/torrentz.eu\/([a-zA-Z0-9]{40})$/)?[1]
	if hash?
		"bt://#{hash.toLowerCase()}"

module.exports =
	pattern: /^http:\/\/torrentz.eu\/[a-zA-Z0-9]{40}$/
	parse: (url) ->
		[to_bt_url(url)]


