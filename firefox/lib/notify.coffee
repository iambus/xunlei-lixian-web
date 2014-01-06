

# desktop noitifications

notifications = require("sdk/notifications")

notify_in_desktop = ({message}) ->
	notifications.notify
		text: message

# status bar notifications

window_utils = require('sdk/window/utils')
{setTimeout} = require('sdk/timers')
NS_XUL = 'http://www.mozilla.org/keymaster/gatekeeper/there.is.only.xul'

notificationbox_id = 'xunlei-lixian-web-notificationbox'
get_notification_box_in_status_bar = ->
#	window_utils.getMostRecentBrowserWindow().gBrowser.getNotificationBox()
	doc = window_utils.getMostRecentBrowserWindow().document
	notification_box = doc.getElementById notificationbox_id
	if notification_box?
		return notification_box

	notification_box = doc.createElementNS(NS_XUL, 'notificationbox')
	notification_box.setAttribute 'id', notificationbox_id
	notification_box.setAttribute 'dir', 'reverse'

	addon_bar = doc.getElementById 'addon-bar'
	addon_bar.parentNode.insertBefore notification_box, addon_bar

	return notification_box

notify_id = 0
notify_in_status_bar = ({type, message, detail, duration}) ->
	notification_box = get_notification_box_in_status_bar()
	old_id = notify_id
	id = ++notify_id
	icon = require("sdk/self").data.url('lixian.ico')
	styles =
		info: '#d4e6f7'
		success: '#d4f7e6'
		warning: '#f8f6d8'
#		warning: '#f8e8d8'
		error: '#f7d4e6'
	levels =
		default: notification_box.PRIORITY_INFO_LOW
#		info: notification_box.PRIORITY_INFO_MEDIUM
#		success: notification_box.PRIORITY_INFO_HIGH
#		warning: notification_box.PRIORITY_WARNING_MEDIUM
#		error: notification_box.PRIORITY_CRITICAL_MEDIUM
	durations =
		default: 3
		info: 4
		success: 5
		warning: 7
		error: 10
	buttons = []
	if detail?
		buttons.push
			label: require('sdk/l10n').get('notification_copy_detail')
			callback: ->
				require("sdk/clipboard").set detail
	e = notification_box.appendNotification message, id, icon, levels[type] ? levels.default, buttons
	e.style.backgroundColor = styles[type] ? styles.info

	clear_notification = (id) ->
		element = notification_box.getNotificationWithValue id
		if element?
			notification_box.removeNotification element
	if old_id
		clear_notification old_id
	if duration != 'forever'
		setTimeout ->
			clear_notification id
		, duration ? (durations[type] ? durations.default) * 1000

notify = (message) ->
	if Object.prototype.toString.call(message) != '[object Object]'
		message = message: message
	notify_in_status_bar message

notify.info = (message) ->
	notify type: 'info', message: message

notify.success = (message) ->
	notify type: 'success', message: message

notify.warning = (message) ->
	notify type: 'warning', message: message

notify.error = (message) ->
	notify type: 'error', message: message


require("sdk/system/unload").when ->
	for w in window_utils.windows()
		box = w.document.getElementById notificationbox_id
		if box?
			box.parentNode.removeChild box

module.exports = notify
