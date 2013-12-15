

{XunleiClient, utils} = require('lixian')

XunleiClient.prototype.http_get = require('http').get
XunleiClient.prototype.http_post = require('http').post
XunleiClient.prototype.http_upload = require('http').upload
XunleiClient.prototype.http_form = require('http').form

XunleiClient.prototype.get_domain_cookie = require('cookie').get
XunleiClient.prototype.set_domain_cookie = require('cookie').set

utils.md5 = require('md5')

utils.setTimeout = require('sdk/timers').setTimeout


{Cu} = require("chrome")
reflect = {}
Cu.import("resource://gre/modules/reflect.jsm", reflect)
parse_javascript = reflect.Reflect.parse

XunleiClient.prototype.parse_queryUrl = (text) ->
	eval_node = (node) ->
		if node.type == 'Literal'
			return node.value
		else if node.type == 'NewExpression'
			return (eval_node(a) for a in node.arguments)
		else if node.type == 'CallExpression'
			return (eval_node(a) for a in node.arguments)
		else if node.type == 'ArrayExpression'
			return (eval_node(a) for a in node.elements)
		else
			console.log node
			throw new Error("Can't eval #{node.type}")
	return eval_node parse_javascript(text).body[0].expression

tasks = require('lixian/tasks')

for n, f of tasks
	do (f) ->
		XunleiClient.prototype[n] = (args...) ->
			f.call null, @, args...


_ = require('sdk/l10n').get
tasks.define_logger (k, args...) ->
	message = _ 'download_status_' + k, args...
	require('notify') type: 'info', message: message, duration: 'forever'

module.exports =
	create: -> new XunleiClient
