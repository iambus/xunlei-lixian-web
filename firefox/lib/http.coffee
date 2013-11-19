
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

module.exports =
	get: http_get
	post: http_post
