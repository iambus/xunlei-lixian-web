
{Cc, Ci} = require("chrome")

crypto_hash = Cc['@mozilla.org/security/hash;1'].createInstance(Ci.nsICryptoHash)
MD5 = Ci.nsICryptoHash.MD5

unicode_converter =	Cc['@mozilla.org/intl/scriptableunicodeconverter'].	createInstance(Ci.nsIScriptableUnicodeConverter)
unicode_converter.charset = 'UTF-8'

hex_char_code = (code) ->
	('0' + code.toString(16)).slice(-2)

hex_string = (a) ->
	(hex_char_code(a.charCodeAt(i)) for i in [0...a.length]).join ''

md5 = (s) ->
	result = {}
	data = unicode_converter.convertToByteArray(s, result)
	crypto_hash.init MD5
	crypto_hash.update data, data.length
	hash = crypto_hash.finish false
	hex_string(hash)

module.exports = md5
