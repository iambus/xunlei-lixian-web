
{Request} = require 'sdk/request'

http_get = (url, callback) ->
	console.log 'GET ' + url
	request = Request
		url: url
		onComplete: (response) ->
			callback
				ok: true
				text: response.text
				json: response.json
				status: response.status
				status_text: response.status_text
				headers: response.headers
	request.get()

http_post = (url, form, callback) ->
	console.log 'POST ' + url
	request = Request
		url: url
		content: form
		onComplete: (response) ->
			callback
				ok: true
				text: response.text
				json: response.json
				status: response.status
				status_text: response.status_text
				headers: response.headers
	request.post()

http_get_binary = (url, callback) ->
	console.log 'GET [binary] ' + url
#	{Cc, Ci} = require 'chrome'
#	request = Cc["@mozilla.org/xmlextras/xmlhttprequest;1"].createInstance(Ci.nsIJSXMLHttpRequest)
#	request.open 'GET', url
#	request.onload = ->
#		onUnload.unload()
#		callback request.response
#	request.onerror = ->
#		onUnload.unload()
#	request.send(null)
#	onUnload =
#		unload: ->
#			try
#				request.abord()
#			catch e
#	require('sdk/system/unload').ensure onUnload
	{XMLHttpRequest} = require('sdk/net/xhr')
	request = new XMLHttpRequest
	request.open 'GET', url
	request.responseType = 'arraybuffer'
	request.onload = ->
		callback
			ok: true
			arraybuffer: request.response
	request.send null

http_upload = (url, form, callback) ->
	console.log 'UPLOAD ' + url
	{XMLHttpRequest} = require('sdk/net/xhr')
	request = new XMLHttpRequest
	request.open 'POST', url
	request.onload = ->
		callback
			ok: true
			text: request.response
#	data = http_form()
#	for k, v of form
#		data.append k, v
#	request.send data
	request.send form

http_form = ->
	{Cc, Ci} = require 'chrome'
	Cc["@mozilla.org/files/formdata;1"].createInstance(Ci.nsIDOMFormData)

module.exports =
	get: http_get
	post: http_post
	get_binary: http_get_binary
	upload: http_upload
	form: http_form
