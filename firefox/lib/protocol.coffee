
{Cc, Ci} = require("chrome")

#handler_name = 'xunlei-lixian-web'
handler_name = '迅雷离线下载'

create_handler = ->
	handler = Cc["@mozilla.org/uriloader/web-handler-app;1"].createInstance(Ci.nsIWebHandlerApp)
	handler.name = handler_name
	handler.uriTemplate = 'chrome://xunlei-lixian-web/content/protocol.xul?%s'
	return handler

external_protocol_service = Cc["@mozilla.org/uriloader/external-protocol-service;1"].getService(Ci.nsIExternalProtocolService)

register_handler = (type, overwrite) ->
	handler_info = external_protocol_service.getProtocolHandlerInfo type
	handlers = handler_info.possibleApplicationHandlers
	for i in [0...handlers.length]
		handler = handlers.queryElementAt(i, Ci.nsIHandlerApp)
		if handler.name == handler_name
			if overwrite
				handlers.removeElementAt i
				break
			else
				return
	handler = create_handler()
	handlers.appendElement(handler, false)
	handler_info.alwaysAskBeforeHandling = false
	handler_info.preferredApplicationHandler = handler

	handler_service = Cc["@mozilla.org/uriloader/handler-service;1"].getService(Ci.nsIHandlerService)
	handler_service.store handler_info

unregister_handler = (type) ->
	handler_info = external_protocol_service.getProtocolHandlerInfo type
	handlers = handler_info.possibleApplicationHandlers
	for i in [0...handlers.length]
		handler = handlers.queryElementAt(i, Ci.nsIHandlerApp)
		if handler.name == handler_name
			handlers.removeElementAt i

			handler_info.alwaysAskBeforeHandling = true
			handler_info.preferredApplicationHandler = undefined

			handler_service = Cc["@mozilla.org/uriloader/handler-service;1"].getService(Ci.nsIHandlerService)
			handler_service.store handler_info
			return

associate_types = (types, overwrite) ->
	for type in types
		register_handler type, overwrite

disassociate_types = (types) ->
	for type in types
		unregister_handler type

setup = ->
	associated_types = ['ed2k', 'magnet']
	simple_prefs = require("sdk/simple-prefs")

	simple_prefs.on 'associate_types', ->
		if simple_prefs.prefs.associate_types
			associate_types associated_types, true
		else
			disassociate_types associated_types

	if simple_prefs.prefs.associate_types
		associate_types associated_types, false

	require("sdk/system/unload").when ->
		disassociate_types associated_types



module.exports =
	associate_types: associate_types
	disassociate_types: disassociate_types
	setup: setup
