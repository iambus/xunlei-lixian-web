
window_utils = require('sdk/window/utils')

NS_XUL = 'http://www.mozilla.org/keymaster/gatekeeper/there.is.only.xul'

full_widget_id = (widget_id) ->
	"widget:#{require('self').id}-#{widget_id}"

full_menu_id = (widget_id) ->
	"menu:#{require('self').id}-#{widget_id}"

create_simple_menu_item = (doc, {label, id, type, command}) ->
	menuitem = doc.createElementNS(NS_XUL, 'menuitem')
	menuitem.setAttribute 'label', label
	if id?
		menuitem.setAttribute 'id', full_menu_id id
	if type?
		menuitem.setAttribute 'type', type
	if command?
		menuitem.addEventListener 'command', command
	return menuitem

create_nested_menu = (doc, {label, command, items}) ->
	menu = doc.createElementNS(NS_XUL, 'menu')
	menu.setAttribute 'label', label
	menupopup = doc.createElementNS(NS_XUL, 'menupopup')
	for menu_info in items
		menuitem = create_menu_item doc, menu_info
		menupopup.appendChild menuitem
	menu.appendChild menupopup
	return menu

create_menu_item = (doc, info) ->
	if info.items?
		create_nested_menu doc, info
	else
		create_simple_menu_item doc, info

widget_menu = (widget_id, menu_id, menus) ->
	doc = window_utils.getMostRecentBrowserWindow().document
	toolbaritem = doc.getElementById full_widget_id widget_id
	menupopup_id = full_menu_id menu_id
	menupopup = doc.getElementById menupopup_id
	if not menupopup?
		menupopup = doc.createElementNS(NS_XUL, 'menupopup')
		menupopup.setAttribute 'id', menupopup_id

		for menu_info in menus
			menuitem = create_menu_item doc, menu_info
			menupopup.appendChild menuitem

		toolbaritem.appendChild menupopup

	show: -> menupopup.openPopup toolbaritem, 'before_start'
	find: (id) -> doc.getElementById full_menu_id id

module.exports =
	widget_menu
