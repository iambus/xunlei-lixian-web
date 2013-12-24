
base32_decode = (s) ->
	a = []
	bits = 0
	v = 0
	s = s.toUpperCase()
	for i in [0...s.length]
		c = s.charCodeAt i
		if 65 <= c <= 90
			c -= 65
		else if 50 <= c <= 55
			c = c - 50 + 26
		else
			throw new Error("Incorrect base32 letter: #{s[i]}")
		if bits < 3
			bits += 5
			v = (v << 5) | c
		else if bits == 3
			a.push ((v << 5) | c)
			bits = 0
			v = 0
		else
			a.push (v << (8 - bits)) | (c >> (bits - 3))
			bits = bits - 3
			v = c & ((1 << bits) - 1)
	new Uint8Array a


hex_char_code = (code) ->
	('0' + code.toString(16)).slice(-2)

array_to_hex = (a) ->
	(hex_char_code(a[i]) for i in [0...a.length]).join ''

base32_to_hex = (s) ->
	array_to_hex base32_decode s

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
	url = url.replace /&.*$/, ''
	info_hash = url.match(/^magnet:\?xt=urn:btih:(.+)/)?[1]
	if not info_hash?
		return
	if info_hash.match /^[a-fA-F0-9]{40}$/
		return info_hash.toLowerCase()
	else if info_hash.match /^[A-Z2-7]{32}$/
		return base32_to_hex info_hash
	else
		return

normalize_url = (url) ->
	url = url_unmask(url)
	if url.match /magnet:/
		hash = magnet_to_infohash url
		if hash
			return "bt://#{hash}"
		else
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
