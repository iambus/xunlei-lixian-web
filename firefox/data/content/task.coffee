
index = 0

tasks_element = document.getElementById 'tasks'
pages_element = document.getElementById 'pages'
refresh_element = document.querySelector '.refresh'

page_tasks = null

refresh = ->
	refresh_element.classList.add 'loading'
	self.port.emit 'refresh', index

document.querySelector('.refresh').onclick = ->
	refresh()

self.port.on 'show', ->
	refresh()

render_tasks = (tasks) ->
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
		task_name.onclick = ->
			task = page_tasks[@parentNode.getAttribute 'task-index']
			if task.status_text == 'completed'
				self.port.emit 'download', task
		task.appendChild task_name
		play = document.createElement 'div'
		play.setAttribute 'class', 'play'
		play.onclick = ->
			self.port.emit 'play', page_tasks[@parentNode.getAttribute 'task-index']
		task.appendChild play
		remove = document.createElement 'div'
		remove.setAttribute 'class', 'delete'
		remove.onclick = ->
			self.port.emit 'delete', parseInt @parentNode.getAttribute 'task-id'
		task.appendChild remove
		tasks_element.appendChild task

render_pages = (total) ->
	show_pages = (enable_previous, pages, enable_next) ->
		pages_element.innerHTML = ''

		previous = document.createElement 'a'
		previous.textContent = '«'
		previous.classList.add 'previous'
		if enable_previous
			previous.onclick = ->
				index--
				refresh()
		else
			previous.classList.add 'disabled'
		pages_element.appendChild previous

		for i in pages
			if i == '...'
				ellipses = document.createElement 'span'
				ellipses.textContent = '...'
				pages_element.appendChild ellipses
			else
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
		if enable_next
			next.onclick = ->
				index++
				refresh()
		else
			next.classList.add 'disabled'
		pages_element.appendChild next

	total_pages = Math.floor total / 10
	if total_pages % 10 != 1
		total_pages += 1

	enable_previous = 0 < index
	enable_next = index < total_pages - 1

	if index < 0 or total_pages <= index
		enable_previous = enable_next = false
		current_page = 0
	else
		current_page = index

	if total_pages <= 11
		show_pages enable_previous, [0...total_pages], enable_next
	else
		start = current_page - 4
		end = current_page + 4
		if start <= 2
			start = 0
		if end >= total_pages - 3
			end = total_pages - 1
		if start == 0 and end < 8
			end = 8
		if end == total_pages - 1 and end - start < 8
			start = end - 8
		pages = [start..end]
		if start > 0
			pages.unshift '...'
			pages.unshift 0
		if end < total_pages - 1
			pages.push '...'
			pages.push total_pages - 1
		show_pages enable_previous, pages, enable_next


resize = ->
	width = 200
	for t in tasks_element.querySelectorAll('.task .task-name')
		if width < t.offsetWidth
			width = t.offsetWidth
	if width > 500
		width = 500
	footer_width = pages_element.offsetWidth + 24
	if width < footer_width
		width = footer_width
	self.port.emit 'resize', width: width + 16

self.port.on 'tasks', ({tasks, total}) ->
	refresh_element.classList.remove 'loading'
	page_tasks = tasks
	render_tasks tasks
	render_pages total
	resize()

self.port.on 'refresh', ->
	refresh()
