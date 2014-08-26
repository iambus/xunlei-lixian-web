
base64 = require('sdk/base64')

module.exports =
	encode: (s) -> base64.encode(s, 'utf-8')
	decode: (s) -> base64.decode(s, 'utf-8')
