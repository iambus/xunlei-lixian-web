

{Cc, Ci} = require("chrome")

io_service = Cc["@mozilla.org/network/io-service;1"].getService(Ci.nsIIOService)
cookie_service = Cc["@mozilla.org/cookieService;1"].getService(Ci.nsICookieService)
cookie_manager = Cc["@mozilla.org/cookiemanager;1"].getService(Ci.nsICookieManager)
cookie_manager2 = Cc["@mozilla.org/cookiemanager;1"].getService(Ci.nsICookieManager2)

get_cookie_string = (url) ->
	cookie_service.getCookieString(io_service.newURI(url, null, null), null)

domain_to_url = (domain) ->
	if domain[0] == '.'
		domain = "www#{domain}"
	if domain.split('.').length == 2
		domain = "www.#{domain}"
	url = "http://#{domain}"
	return url

get_cookie = (domain, key) ->
	url = domain_to_url domain
	#	cookie_string = get_cookie_string(url)
	e = cookie_manager2.getCookiesFromHost url
	while e.hasMoreElements()
		cookie = e.getNext().QueryInterface(Ci.nsICookie)
		if cookie.name == key
			return cookie.value
	return

set_cookie = (domain, key, value) ->
	cookie_manager2.add domain, '/', key, value, false, false, false, Date.now() / 1000 + 60 * 60 * 24 * 365

# only for testing
dump_all_cookies = ->
	e = cookie_manager.enumerator
	while e.hasMoreElements()
		cookie = e.getNext().QueryInterface(Ci.nsICookie)
		console.log cookie.host + ": " + cookie.name + "=" + cookie.value
#		console.log cookie.host + ": " + cookie.name + "=" + cookie.value, cookie.path, cookie.isSecure, cookie.isHttpOnly, cookie.isSession, cookie.expiry, cookie
	return
#dump_all_cookies()

module.exports =
	get: get_cookie
	set: set_cookie
