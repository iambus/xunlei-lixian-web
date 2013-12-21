
index = 0

tasks_element = document.getElementById 'tasks'
pages_element = document.getElementById 'pages'

page_tasks = null

refresh = ->
	self.port.emit 'refresh', index

document.querySelector('.refresh').onclick = ->
	refresh()

self.port.on 'show', ->
	refresh()

self.port.on 'tasks', ({tasks, total}) ->
	page_tasks = tasks
	tasks_element.innerHTML = ''
	for t, i in tasks
		task = document.createElement 'div'
		task.setAttribute 'class', 'task'
		task.setAttribute 'task-id', t.id
		task.setAttribute 'task-index', i
		task.setAttribute 'status', t.status_text
		task_name = document.createElement 'span'
		task_name.setAttribute 'class', 'task-name'
		task_name.textContent = t.name
		task.appendChild task_name
		buttons = document.createElement 'div'
		buttons.setAttribute 'class', 'buttons'
		download = document.createElement 'div'
		download.setAttribute 'class', 'download'
		download.onclick = ->
			self.port.emit 'download', page_tasks[@parentNode.parentNode.getAttribute 'task-index']
		buttons.appendChild download
		remove = document.createElement 'div'
		remove.setAttribute 'class', 'delete'
		remove.onclick = ->
			self.port.emit 'delete', parseInt @parentNode.parentNode.getAttribute 'task-id'
		buttons.appendChild remove
		task.appendChild buttons
		tasks_element.appendChild task

	pages = Math.floor total / 10
	if pages % 10 != 1
		pages += 1
	if index >= pages or pages == 0
		throw new Error("Not Implemented")
	pages_element.innerHTML = ''
	previous = document.createElement 'a'
	previous.textContent = '«'
	previous.classList.add 'previous'
	if index <= 0
		previous.classList.add 'disabled'
	else
		previous.onclick = ->
			index--
			refresh()
	pages_element.appendChild previous
	for i in [0...pages]
		p = document.createElement 'a'
		p.textContent = i + 1
		if i == index
			p.classList.add 'current'
		p.setAttribute 'page', i
		p.onclick = ->
			index = parseInt @getAttribute('page')
			refresh()
		pages_element.appendChild p
	next = document.createElement 'a'
	next.textContent = '»'
	next.classList.add 'next'
	if index >= pages - 1
		next.classList.add 'disabled'
	else
		next.onclick = ->
			index++
			refresh()
	pages_element.appendChild next

	width = 200
	for t in tasks_element.querySelectorAll('.task .task-name')
		if width < t.offsetWidth
			width = t.offsetWidth
	if width > 500
		width = 500
	self.port.emit 'resize', width: width + 16

self.port.on 'refresh', ->
	refresh()
