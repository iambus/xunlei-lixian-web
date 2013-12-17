
all_tasks = []

set_properties = (node, properties) ->
	keys = []
	for k, v of properties
		if v
			keys.push k
	node.setAttribute 'properties', keys.join('')

document.getElementById('check-all').addEventListener 'command', ->
	for checkbox in document.querySelectorAll "#files treechildren treerow[status='completed'] treecell.checkbox"
		checkbox.setAttribute 'value', @checked

document.getElementById('hide-incomplete').addEventListener 'command', ->
	for treerow in document.querySelectorAll "#files treechildren treerow:not([status='completed'])"
		treerow.parentNode.hidden = @checked

document.getElementById('hide-dir').addEventListener 'command', ->
	for cell in document.querySelectorAll "#files treechildren treecell.path"
		label = if @checked then cell.getAttribute('filename') else cell.getAttribute('path')
		cell.setAttribute 'label', label

window.load = (tasks) ->
	all_tasks = tasks

	treechildren = document.querySelector '#files treechildren'
	for t, i in all_tasks
		treeitem = document.createElement('treeitem')


		treerow = document.createElement('treerow')
		treerow.setAttribute 'status', t.status_text
		treerow.setAttribute 'task_index', i
		set_properties treerow,
#			checked: t.status_text == 'completed'
			disabled: t.status_text != 'completed'

		checkbox = document.createElement('treecell')
		checkbox.setAttribute 'value', t.status_text == 'completed'
		checkbox.setAttribute 'editable', t.status_text == 'completed'
		checkbox.setAttribute 'class', 'checkbox'
		set_properties checkbox,
			disabled: t.status_text != 'completed'
		checkbox.onclick = ->
			console.log @
		checkbox.addEventListener 'click', ->
			console.log @getAttribute('checked')

		file = document.createElement('treecell')
		file.setAttribute 'label', t.full_path
		file.setAttribute 'editable', false
		file.setAttribute 'filename', t.filename
		file.setAttribute 'path', t.full_path
		file.setAttribute 'class', 'path'
		set_properties file,
			disabled: t.status_text != 'completed'

		treerow.appendChild checkbox
		treerow.appendChild file
		treeitem.appendChild treerow
		treechildren.appendChild treeitem

window.onsave = ->

window.oncancel = ->

window.save = ->
	tasks = []
	for treerow in document.querySelectorAll('#files treechildren treerow')
		if treerow.getElementsByTagName('treecell')[0].getAttribute('value') == 'true'
			index = parseInt treerow.getAttribute 'task_index'
			task = all_tasks[index]
			if task?
				tasks.push task
	window.onsave tasks

window.cancel = ->
	window.oncancel()

