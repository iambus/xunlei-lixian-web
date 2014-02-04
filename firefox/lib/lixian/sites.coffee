
torrentz = require 'lixian/sites/torrentz'

sites = [torrentz]

urls = (site.pattern for site in sites)

check = (url) ->
	for site in sites
		if site.pattern.test url
			true
	return false

parse = (url) ->
	for site in sites
		if site.pattern.test url
			return site.parse url

parse_all = (urls) ->
	result = []
	for url in urls
		translated = parse(url)
		if translated?
			for u in translated
				result.push u
		else
			result.push url
	return result

module.exports =
	urls: urls
	check: check
	parse: parse
	parse_all: parse_all
