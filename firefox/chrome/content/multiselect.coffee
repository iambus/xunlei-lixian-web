
all_tasks = []

set_properties = (node, properties) ->
	keys = []
	for k, v of properties
		if v
			keys.push k
	node.setAttribute 'properties', keys.join('')

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
		set_properties checkbox,
			disabled: t.status_text != 'completed'
		checkbox.onclick = ->
			console.log @
		checkbox.addEventListener 'click', ->
			console.log @getAttribute('checked')

		file = document.createElement('treecell')
		file.setAttribute 'label', t.full_path
		file.setAttribute 'editable', false
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

