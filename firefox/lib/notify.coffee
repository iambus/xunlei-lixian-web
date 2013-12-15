

# desktop noitifications

notifications = require("sdk/notifications")

notify_in_desktop = ({message}) ->
	notifications.notify
		text: message

# status bar notifications

window_utils = require('sdk/window/utils')
{setTimeout} = require('sdk/timers')
NS_XUL = 'http://www.mozilla.org/keymaster/gatekeeper/there.is.only.xul'

get_notification_box_in_status_bar = ->
#	window_utils.getMostRecentBrowserWindow().gBrowser.getNotificationBox()
	doc = window_utils.getMostRecentBrowserWindow().document
	box_id = 'xunlei-lixian-web-notificationbox'
	notification_box = doc.getElementById box_id
	if notification_box?
		return notification_box

	notification_box = doc.createElementNS(NS_XUL, 'notificationbox')
	notification_box.setAttribute 'id', box_id
	notification_box.setAttribute 'dir', 'reverse'

	addon_bar = doc.getElementById 'addon-bar'
	addon_bar.parentNode.insertBefore notification_box, addon_bar

	return notification_box

notify_id = 0
notify_in_status_bar = ({type, message}) ->
	notification_box = get_notification_box_in_status_bar()
	clear_notification = (id) ->
		element = notification_box.getNotificationWithValue id
		if element?
			notification_box.removeNotification element
	old_id = notify_id
	id = ++notify_id
	icon = require("sdk/self").data.url('xunlei.ico')
	e = notification_box.appendNotification message, id, icon, notification_box.PRIORITY_INFO_LOW, {}
	e.style.backgroundColor = if type == 'error' then '#f8e8d8' else '#dbeaf9'
	if old_id
		clear_notification old_id
	setTimeout ->
		clear_notification id
	, 3000

notify = (message) ->
	if Object.prototype.toString.call(message) == '[object String]'
		message = message: message
	notify_in_status_bar message

module.exports = notify
