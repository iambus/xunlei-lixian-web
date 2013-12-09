
is_ed2k = (url) ->
	url.match /^ed2k:\/\//

normalize_unicode_url = (url) ->
	throw new Error("Not Implemented: normalize_unicode_link")

xunlei_url_decode = (url) ->
	throw new Error("Not Implemented: xunlei_url_decode")

flashget_url_decode = (url) ->
	throw new Error("Not Implemented: flashget_url_decode")

flashgetx_url_decode = (url) ->
	throw new Error("Not Implemented: flashgetx_url_decode")

qqdl_url_decode = (url) ->
	throw new Error("Not Implemented: qqdl_url_decode")

url_unmask = (url) ->
	if url.match('^thunder://')
		return normalize_unicode_url(xunlei_url_decode(url))
	else if url.match('^Flashget://')
		return flashget_url_decode(url)
	else if url.match('^flashgetx://')
		return flashgetx_url_decode(url)
	else if url.match('^qqdl://')
		return qqdl_url_decode(url)
	else
		return url

parse_ed2k_url_hash_hex = (url) ->
	ed2k_re = /^ed2k:\/\/\|file\|([^|]*)\|(\d+)\|([a-fA-F0-9]{32})\|/
	url.match(ed2k_re)?[2].toLowerCase()

magnet_to_infohash = (url) ->
	throw new Error("Not Implemented")

normalize_url = (url) ->
	url = url_unmask(url)
	if url.match /magnet:/
#		throw new Error("Not Implemented")
		return url
	else if url.match /^ed2k:\/\//
		hash = parse_ed2k_url_hash_hex url
		if not hash
			throw new Error("Not Implemented: #{url}")
		return "ed2k:#{hash}"
	else if url.match /^bt:\/\//
		return url.toLowerCase()
	else if url.match /^[0-9a-fA-F]{40}$/
		return "bt://#{url.toLowerCase()}"
#	else if url.match /^(http|https|ftp)/
#		return normalize_unicode_url(url)
	else
		return url

url_equals = (u1, u2) ->
	normalize_url(u1) == normalize_url(u2)

module.exports =
	normalize_url: normalize_url
	url_equals: url_equals
