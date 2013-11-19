
{normalize_url} = require 'urls'

class CachedList
	constructor: (@client) ->
		@tasks = []
		@done = false
	fetch: (page_index, callback) ->
		@client.list_tasks_by_page page_index, callback
	search_array: (url, tasks) ->
		for t in tasks
			if t.original_url == url
				return t
	search_cached: (url) ->
		if @total?
			return @search_array url, @tasks
	search_remote: (url, callback) ->
		if @done
			callback ok: true, task: null
		else
			page_index = Math.floor(@tasks.length/@client.page_size)
			@fetch page_index, (result)=>
				{ok, tasks, total} = result
				if not @total?
					@total = total
				if ok
					@total = total
					for t in tasks
						@tasks.push t
					if tasks.length < @client.page_size or @tasks.length > @total
						@done = true
					task = @search_array url, tasks
					if task
						callback ok: true, task: task
					else
						@search_remote url, callback
				else
					callback result

search_tasks = (client, urls, callback) ->
	if urls.length == 0
		callback ok: true, tasks: []
		return
	urls = urls.slice()
	cached = new CachedList client
	tasks = []
	not_found = []
	search = ->
		while urls.length > 0
			url = urls.shift()
			task = cached.search_cached url
			if task
				tasks.push task
			else
				if cached.done
					not_found.push url
				else
					cached.search_remote url, (result) ->
						{ok, task} = result
						if ok
							if task
								tasks.push task
							else
								not_found.push url
							search()
						else
							callback result
					return
		callback ok: true, tasks: tasks, not_found: not_found
	search()

add_bt_tasks = (client, urls, callback) ->
	urls = urls.slice()
	hashes = []
	add = ->
		if urls.length == 0
			callback ok: true, hashes: hashes
			return
		url = urls.shift()
		if url.match /^maget:/
			client.add_magnet_task url, (result) ->
				if result.ok
					hashes.push result.info_hash
					add()
				else
					callback result
		else
			m = url.match '^(?:bt://)?([0-9a-fA-F]{40})$'
			if m
				client.add_bt_task_by_info_hash m[1], (result) ->
					if result.ok
						hashes.push result.info_hash
						add()
					else
						callback result
			else
				throw new Error("Invalid bt url: #{url}")
	add()

super_add = (client, urls, callback) ->
	normal_urls = (url for url in urls when url.match(/^(http|https|ftp|ed2k|thunder):/i))
	bt_urls = (url for url in urls when url.match(/^(bt|magnet):|(^[0-9a-fA-F]{40}$)/i))
	urls = []
	add_normal = (callback) ->
		if normal_urls.length > 0
			client.add_batch_tasks urls, (result) ->
				if result.ok
					urls = urls.concat normal_urls
					callback ok: true
				else
					callback result
		else
			callback ok: true
	add_bt = (callback) ->
		if bt_urls.length > 0
			add_bt_tasks client, bt_urls, (result) ->
				if result.ok
					urls.push "bt://#{hash}" for hash in result.hashes
					callback ok: true
				else
					callback result
		else
			callback ok: true
	add_normal (result) ->
		if result.ok
			add_bt (result) ->
				if result.ok
					callback ok: true, urls: urls
				else
					callback result
		else
			callback result

expand_bt_tasks = (client, tasks, callback) ->
	tasks = tasks.slice()
	expanded = []
	cached = {}
	expand = ->
		while tasks.length > 0
			task = tasks.shift()
			if not cached[task.id]
				cached[task.id] = true
				if task.type != 'bt'
					expanded.push task
				else
					client.list_bt task, (result) ->
						if result.ok
							expanded.push file for file in result.files
							expand()
						else
							callback result
					return
		finished = (t for t in expanded when t.status_text == 'completed')
		skipped = (t for t in expanded when t.status_text != 'completed')
		callback ok: true, tasks: expanded, finished: finished, skipped: skipped
	expand()

super_search = (client, urls, callback) ->
	search_tasks client, urls, (result) ->
		if result.ok
			expand_bt_tasks client, result.tasks, callback
		else
			callback result

super_get = (client, urls, callback) ->
	super_add client, urls, (result) ->
		if result.ok
			super_search client, result.urls, callback
		else
			callback result

module.exports =
	search_tasks: search_tasks
	super_add: super_add
	super_search: super_search
	super_get: super_get

