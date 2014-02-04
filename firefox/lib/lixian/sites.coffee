
torrentz = require 'lixian/sites/torrentz'

sites = [torrentz]

module.exports =
	urls: (site.pattern for site in sites)
	check: (url) ->
		for site in sites
			if site.pattern.test url
				true
		return false
	parse: (url) ->
		for site in sites
			if site.pattern.test url
				return site.parse url
