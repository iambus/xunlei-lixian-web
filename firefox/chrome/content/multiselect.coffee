
all_tasks = []
completed_tasks = []
hide_incomplete = false
hide_dir = false


tree = document.getElementById 'files'

redraw = ->
	box = tree.boxObject
	box.QueryInterface(Components.interfaces.nsITreeBoxObject)
	box.invalidate()

document.getElementById('check-all').addEventListener 'command', ->
	for t in all_tasks
		if t.status_text == 'completed'
			t.checked = @checked
	redraw()

document.getElementById('hide-incomplete').addEventListener 'command', ->
	hide_incomplete = @checked
	if hide_incomplete
		tasks = completed_tasks
	else
		tasks = all_tasks
	tree.view = new TreeView tasks
	redraw()

document.getElementById('hide-dir').addEventListener 'command', ->
	hide_dir = @checked
	redraw()

class TreeView
	constructor: (@tasks) ->
		@reset()
	reset: ->
		@rowCount = @tasks.length
	getCellText: (row, column) ->
		task = @tasks[row]
		if column.index == 1
			if hide_dir
				return task.filename
			else
				return task.full_path
		else
			return ''
	getCellValue: (row, column) ->
		if column.index == 0
			task = @tasks[row]
			return task.checked ? task.status_text == 'completed'
	setCellValue: (row, column, value) ->
		if column.index == 0
			task = @tasks[row]
			task.checked = value == 'true'
	isEditable: (row, column) ->
		column.index == 0 and @tasks[row].status_text == 'completed'
	getRowProperties: (row) ->
		properties = []
		task = @tasks[row]
		if task.checked ? task.status_text == 'completed'
			properties.push 'checked'
		if hide_incomplete and task.status_text != 'completed'
			properties.push 'hidden'
		return properties.join ' '
	getCellProperties: (row ,column) ->
		task = @tasks[row]
		if task.status_text != 'completed'
			return 'disabled'
	getColumnProperties: (colid, column) ->
	cycleHeader: (column) ->
	isSorted: ->
		return false
	setTree: (treebox) ->
		@treebox = treebox
	isContainer: (row) ->
		return false
	isSeparator: (row) ->
		return false
	getLevel: (row) ->
		return 0
	getImageSrc: (row, column) ->
		return null

window.load = (tasks) ->
	all_tasks = tasks
	completed_tasks = (t for t in tasks when t.status_text == 'completed')

	tree.view = new TreeView tasks

window.onsave = ->

window.oncancel = ->

window.save = ->
	tasks = []
	for t in all_tasks
		if t.checked ? t.status_text == 'completed'
			tasks.push t
	window.onsave tasks

window.cancel = ->
	window.oncancel()

