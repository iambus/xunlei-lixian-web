
is_http = (text) ->
	/^(http|https|ftp|thunder):\/\//i.test text

is_ed2k = (text) ->
	/^ed2k:\/\//i.test text

is_magnet = (text) ->
	/magnet:/i.test text

is_bt = (text) ->
	/^bt:\/\/[0-9a-f]{40}$/i.test text

is_bt_hash = (text) ->
	/^[0-9a-f]{40}$/i.test text

is_valid_url = (text) ->
	text = text.toLowerCase()
	is_http(text) or is_ed2k(text) or is_magnet(text) or is_bt(text) or is_bt_hash(text)


unique_links = (links) ->
	result = []
	cached = {}
	for link in links
		if not cached[link]
			result.push link
			cached[link] = true
	result

filter_links = (links) ->
	(link for link in links when is_valid_url link)


get_links_from_html = ->
	selection = window.getSelection()
	links = []
	for link in document.links
		if selection.containsNode link, true
			links.push link.href
	links = unique_links filter_links links
	if links.length > 0
		return links

get_links_from_text = ->
	text = window.getSelection().toString()
	links = (link.trim() for link in text.split /[\r\n]/)
	links = unique_links filter_links links
	if links.length > 0
		return links


#self.on "context", (node, data) ->
#	return true

self.on "click", (node, data) ->
	links = get_links_from_html() or get_links_from_text()
	if links
		self.postMessage links
