

{XunleiClient, utils} = require('lixian')

XunleiClient.prototype.http_get = require('http').get
XunleiClient.prototype.http_post = require('http').post
XunleiClient.prototype.http_upload = require('http').upload
XunleiClient.prototype.http_form = require('http').form

XunleiClient.prototype.get_domain_cookie = require('cookie').get
XunleiClient.prototype.set_domain_cookie = require('cookie').set

utils.md5 = require('md5')

{Cc, Ci} = require("chrome")
timer = Cc["@mozilla.org/timer;1"].createInstance(Ci.nsITimer)
utils.setTimeout = (callback, ms) ->
	event =
		notify: (timer) ->
			callback()
	timer.initWithCallback event, ms, Ci.nsITimer.TYPE_ONE_SHOT


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
	XunleiClient.prototype[n] = (args...) ->
		f.call null, @, args...

module.exports =
	create: -> new XunleiClient
