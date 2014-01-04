
join_url = (base, url) ->
	if url.match /^http:/i
		return url
	if url.match /^\//
		return base.replace(/\/$/, '') + url
	throw new Error("Not Implemented: #{url}")

encypt_password = (password) ->
	if not password.match /^[0-9a-f]{32}$/
		password = utils.md5 utils.md5 password
	return password

current_timestamp = ->
	new Date().getTime()


no_cache = (url) ->
	if url.indexOf('?') == -1
		url += '?'
	else
		url += '&'
	url += 'nocache=' + current_timestamp()


################################################################################
# utils
################################################################################

utils =
	encypt_password: encypt_password
	md5: ->
		throw new Error("Not Implemented: md5")
	setTimeout: this.setTimeout

################################################################################
# task
################################################################################

status_map =
	0: 'waiting'
	1: 'downloading'
	2: 'completed'
	3: 'failed'
	5: 'pending'
expired_map =
	0: false
	4: true
class Task
	constructor: (json) ->
		for k, v of json
			@[k] = v
		@type = @protocol = @url.match('^[^:]+')[0].toLowerCase()
		@name = unescape(@taskname).replace /(&amp;)+/g, '&'
		@filename = @name
		@full_path = @filename
		@original_url = @url
		@download_url = @lixian_url
		@bt_hash = @cid
		@size = parseInt @filesize
		@size_text = parseInt @ysfilesize
		@status = parseInt @download_status
		@status_text = status_map[@download_status]
		@expired = expired_map[@flag]
class TaskFile
	constructor: (json) ->
		for k, v of json
			@[k] = v
		@type = 'bt'
		@index = @id
		@id = @taskid
		@name = @title.replace /(&amp;)+/g, '&'
		@filename = @name.replace /^.*\\/, ''
		@dirs = @name.match(/^(.*)\\/)?[1].split('\\') ? []
		@full_path = @dirs.concat([@filename]).join('/')
		@original_url = @url
		@download_url = @downurl
		@size_text = @size
		@size = parseInt @filesize
		@status = parseInt @download_status
		@status_text = status_map[@download_status]

################################################################################
# client
################################################################################

class XunleiClient
	constructor: ->
		@initialized = false
		@id = null
		@base_url = 'http://dynamic.cloud.vip.xunlei.com/'
		@page_size = 100
		@bt_page_size = 9999

	get_domain_cookie: (domain, key) ->
		throw new Error("Not Implemented: get_domain_cookie")

	set_domain_cookie: (domain, key, value) ->
		throw new Error("Not Implemented: set_domain_cookie")

	get_cookie: (domain, key) ->
		if not key?
			key = domain
			domain = "dynamic.cloud.vip.xunlei.com"
		@get_domain_cookie domain, key

	set_cookie: (domain, key, value) ->
		@set_domain_cookie domain, key, value

	http_get: (url, callback) ->
		throw new Error("Not Implemented: http_get")

	http_post: (url, form, callback) ->
		throw new Error("Not Implemented: http_post")

	http_upload: (url, form, callback) ->
		throw new Error("Not Implemented: http_upload")

	http_form: ->
		throw new Error("Not Implemented: http_upload")

	url: (u) ->
		join_url(@base_url, u)

	get: (url, callback) -> # support auto-relogin relavant url
		url = @url url
		@http_get url, (result) =>
			if @auto_relogin and @is_session_timed_out_response(result.text)
				@auto_login (result) =>
					if result.ok
						@http_get url, callback
					else
						callback result
			else
				callback result

	post: (url, form, callback) -> # support auto-relogin relavant url
		url = @url url
		@http_post url, form, (result) =>
			if @auto_relogin and @is_session_timed_out_response(result.text)
				@auto_login (result) =>
					if result.ok
						@http_post url, form, callback
					else
						callback result
			else
				callback result

	upload: (url, form, callback) -> # support auto-relogin relavant url
		url = @url url
		@login_check =>
			# TODO: check response for session timeout
			@http_upload url, form, callback

	init: (callback) ->
		if @initialized
			callback()
			return
		@get_json @to_page_url(0, 1), (data) ->
			@initialized = true
			callback()

	#########
	# login #
	#########

	is_session_timed_out_response: (text) ->
		text == '''<script>document.cookie ="sessionid=; path=/; domain=xunlei.com"; document.cookie ="lx_sessionid=; path=/; domain=vip.xunlei.com";top.location='http://lixian.vip.xunlei.com/task.html?error=1'</script>'''

	get_id_from_cookie: ->
		@get_cookie('xunlei.com', 'userid')

	login_with_verification_code: (username, password, verification_code, callback) ->
		@last_username = username
		@last_login_time = new Date
		password = encypt_password password
		verification_code = verification_code?.toUpperCase()
		password = utils.md5 password + verification_code
		login_url = 'http://login.xunlei.com/sec2login/'
		form =
			u: username
			p: password
			verifycode: verification_code
		@http_post login_url, form, ({text}) =>
			if not @get_id_from_cookie()
				callback? ok: false
			else
				callback? ok: true

	login_without_retry: (username, password, callback) ->
		cachetime = current_timestamp()
		check_url = no_cache "http://login.xunlei.com/check?u=#{username}"
		@http_get check_url, ({text}) =>
			verification_code = @get_cookie('check_result')?.substr(2)
			if verification_code
				@login_with_verification_code username, password, verification_code, callback
			else
				callback
					ok: false
					reason: "Verification code required"
					verification_code: no_cache "http://verify2.xunlei.com/image"

	login_with_retry: (username, password, callback, retries=30) ->
		@login_without_retry username, password, (result) =>
			if result.ok
				callback result
			else if result.verification_code
				callback result
			else if retries > 0
				console.log "login failed, retrying..."
				utils.setTimeout =>
					@login_with_retry username, password, callback, retries-1
				, 1000
			else
				callback result

	login: (username, password, callback) ->
		@login_with_retry username, password, callback

	login_enrich_cookie: (callback) ->
		cachetime = current_timestamp()
		check_url = no_cache "http://dynamic.cloud.vip.xunlei.com/interface/verify_login"
		@http_get check_url, ({text}) =>
			if text == '({"result":0})'
				callback
					ok: false
					reason: "Session timed out" # XXX: or already logged in?
			else
				m = text.match /^verify_login_resp\((\{.*\})\)$/
				if m
					json = JSON.parse(m[1])
					if json.result == 1
						for k, v of json.data
							@set_cookie '.xunlei.com', k, v
						@set_cookie '.xunlei.com', 'sessionid', @get_cookie '.xunlei.com', 'lsessionid'
						callback ok: true
					else
						callback
							ok: false
							reason: "result: #{json.result}"
							response: text
				else
					callback
						ok: false
						reason: "Can't parse response"
						response: text

	auto_login: (callback) ->
		console.log "session timedout. trying to relogin..."
		if @username and @password
			@login @username, @password, (result) =>
				if result.ok
					callback result
				else if result.verification_code
					if @require_login
						@require_login
							username: @username
							password: @password
							verification_code: result.verification_code
						, ({username, password, verification_code}) =>
								@username = username
								@password = password
								@login_with_verification_code @username, @password, verification_code, callback
					else
						callback result
				else
					callback result
		else
			@require_login
				username: @username
				password: @password
			, ({username, password}) =>
					@username = username
					@password = password
					@auto_login callback


	login_check: (callback) ->
#		if @get_cookie('.xunlei.com', 'sessionid')
#			throw new Error("Not Implemented: login_check")
#		else if @get_cookie '.xunlei.com', 'lsessionid'
#			@login_enrich_cookie (result) =>
#				if result.ok
#					callback result
#				else
#					callback ok: false
#		else
#			callback ok: false, reason: 'No session found'
		if not (@get_cookie('xunlei.com', 'userid') and @get_cookie('.xunlei.com', 'sessionid'))
			@login_enrich_cookie (result) =>
				if result.ok
					callback result
				else
					if @auto_relogin
						@auto_login (result) =>
							callback result
					else
						callback ok: false, reason: 'auto-relogin is disabled'
		else
			callback ok: true

	# TODO:
	auto_relogin_for: ({url, form, pattern, callback}) ->
		if form?
			request = (callback) => @post url, form, callback
		else
			request = (callback) => @get url, callback
		if Object.prototype.toString.call(pattern) == '[object RegExp]'
			is_timeout = (text) -> pattern.match text
		else
			is_timeout = (text) -> text == pattern
		relogin = =>
			@auto_login (result) =>
				if result.ok
					request (result) =>
						callback result
				else
					callback result
		start = =>
			request (result) =>
				{text} = result
				if is_timeout(text) and @auto_relogin
					relogin()
				else
					callback result
		@login_check =>
			start()

	with_id: (callback) ->
		@login_check =>
			callback @get_id_from_cookie()

	#######
	# add #
	#######

	add_simple_task: (url, callback) ->
		throw new Error("Not Implemented: add_simple_task")

	upload_torrent_file_by_blob: (blob, callback) ->
		upload_url = '/interface/torrent_upload'
		form = new @http_form()
		form.append 'filepath', blob, 'attachment.torrent'
		@upload upload_url, form, ({text}) =>
			upload_failed = text?.match(/<script>document\.domain="xunlei\.com";var btResult =(\{"ret_value":0\});<\/script>/)?[1]
			upload_success = text?.match(/<script>document\.domain="xunlei\.com";var btResult =(\{.*\});<\/script>/)?[1]
			already_exists = text?.match(/parent\.edit_bt_list\((\{.*\}),'','0'\)/)?[1]
			if upload_failed?
				callback ok: false, reason: 'Upload failed', response: text
			else if upload_success?
				result = JSON.parse upload_success
				callback
					ok: true
					done: false
					info_hash: result['infoid']
					name: result['ftitle']
					size: result['btsize']
					files: (id: x.id, name: x.subtitle, size: x.subsize for x in result['filelist'])
			else if already_exists?
				result = JSON.parse already_exists
				callback
					ok: true
					done: true
					info_hash: result['infoid']
			else
				callback ok: false, reason: 'Failed be parse upload result', response: text

	parse_jsonp_response: (response, jsonp) ->
		code = response.match("^#{jsonp}\\((.+)\\)$")?[1]
		if code?
			return JSON.parse code

	commit_bt_task: ({info_hash, name, size, files}, callback) ->
		@with_id (id) =>
			form =
				uid: id
				btname: name
				cid: info_hash
				tsize: size
				findex: (f['id']+'_' for f in files).join('')
				size: (f['size']+'_' for f in files).join('')
				from: '0'
			try_commit = =>
				jsonp = "jsonp#{current_timestamp()}"
				commit_url = "/interface/bt_task_commit?callback=#{jsonp}"
				@post commit_url, form, ({text}) =>
					result = @parse_jsonp_response text, jsonp
					if result?.progress? and result.progress not in [-12, -11]
						callback ok: true, reason: 'BT task created', info_hash: info_hash
					else if result?.progress in [-12, -11]
						if @require_verification_code
							@require_verification_code (verification_code) ->
								form.verify_code = verification_code
								try_commit()
						else
							callback ok: false, reason: 'Verification code required', response: text
					else
						callback ok: false, reason: 'Failed be parse bt result', detail: "Failed be parse bt result: #{text}", response: text
			try_commit()

	add_bt_task_by_blob: (blob, callback) ->
		@upload_torrent_file_by_blob blob, (result) =>
			if result.ok and not result.done
				@commit_bt_task result, callback
			else
				callback result

	query_bt_task_by_url: (url, callback) ->
		url = "/interface/url_query?callback=queryUrl&u=#{encodeURIComponent url}&random=#{current_timestamp()}"
		@get url, ({text}) =>
			m = text.match /^queryUrl(\(1,.*\))\s*$/ # XXX: sometimes it returns queryUrl(0,...)?
			if m
				[_, cid, tsize, btname, _, names, sizes_, sizes, _, types, findexes, timestamp, _] = @parse_queryUrl text
				callback
					ok: true
					done: false
					info_hash: cid
					name: btname
					size: tsize
					files: (name: name, id: findexes[i], size: sizes[i] for name, i in names)
			else
				m = text.match /^queryUrl\(-1,'([^']{40})/
				if m
					callback ok: true, done: true, reason: 'BT task alrady exists', info_hash: m[1]
				else
					callback ok: false, reason: 'Failed to add bt task', response: text

	add_bt_task_by_query_url: (url, callback) ->
		@query_bt_task_by_url url, (result) =>
			if result.ok and not result.done
				@commit_bt_task result, callback
			else
				callback result

	add_bt_task_by_info_hash: (hash, callback) ->
		hash = hash.toUpperCase()
		@with_id (id) =>
			url = "http://dynamic.cloud.vip.xunlei.com/interface/get_torrent?userid=#{id}&infoid=#{hash}"
			@add_bt_task_by_query_url url, callback

	add_magnet_task: (url, callback) ->
		@login_check =>
			# TODO: check response for session timeout
			@add_bt_task_by_query_url url, callback

	add_task: (url, callback) ->
		throw new Error("Not Implemented: add_task")

	add_batch_tasks: (urls, callback) ->
		urls = (url for url in urls when url.match(/^(http|https|ftp|ed2k|thunder):/i))
		if not urls
			callback ok: false, reason: 'No valid URL found'
			return
		form = {}
		for url, i in urls
			form["cid[#{i}]"] = ''
			form["url[#{i}]"] = url
		form['batch_old_taskid'] = '0' + ('' for [0...urls.length]).join(',')
		try_add = =>
			jsonp = "jsonp#{current_timestamp()}"
			url = "/interface/batch_task_commit?callback=#{jsonp}"
	#		@post url, form, callback
			@auto_relogin_for
				url: url
				form: form
				pattern: '''<script>document.cookie ="sessionid=; path=/; domain=xunlei.com"; document.cookie ="lx_sessionid=; path=/; domain=vip.xunlei.com";top.location='http://lixian.vip.xunlei.com/task.html?error=1'</script>'''
				callback: (result) =>
					if result.ok
						text = result.text
						code = @parse_jsonp_response text, jsonp
						if code? and code not in [-12, -11]
							callback ok: true
						else if code in [-12, -11]
							if @require_verification_code
								@require_verification_code (verification_code) ->
									form.verify_code = verification_code
									try_add()
							else
								callback ok: false, reason: 'Verification code required', response: text
						else
							callback ok: false, reason: 'jsonp', detail: text, response: text
					else
						callback result
		try_add()

	########
	# list #
	########

	set_page_size_in_cokie: (size) ->
		@set_cookie '.vip.xunlei.com', 'pagenum', size

	to_page_url: (type_id, page_index, page_size) ->
		# type_id: 1 for downloading, 2 for completed, 4 for downloading+completed+expired, 11 for deleted, 13 for expired
		if type_id == 0
			type_id = 4
		page = page_index + 1
		p = 1 # XXX: what is it?
		url = no_cache "/interface/showtask_unfresh?type_id=#{type_id}&page=#{page}&tasknum=#{page_size}&p=#{p}&interfrom=task"
		return url

	parse_rebuild: (text) ->
		m = text.match /^rebuild\((\{(.+)\})\)$/
		if m
			result = JSON.parse(m[1])
			if result.rtcode == 0
				info = result.info
				info.ok = true
				info.tasks = (new Task(t) for t in info.tasks)
				info.total = info.total_num
				info
			else
				ok: false
				reason: "rtcode: #{result.rtcode}"
				response: text
		else
			ok: false
			reason: "Can't parse response"
			response: text

	list_tasks_by: (type_id, page_index, page_size, callback) ->
		url = @to_page_url type_id, page_index, page_size
		@auto_relogin_for
			url: url
			pattern: 'rebuild({"rtcode":-1,"list":[]})'
			callback: (result) =>
				if result.ok
					callback @parse_rebuild result.text
				else
					callback result

	list_tasks_by_page: (page_index, callback) ->
		@list_tasks_by 4, page_index, @page_size, callback

	parse_fill_bt_list: (text) ->
		m = text.match /^fill_bt_list\((\{(.+)\})\)$/
		if m
			json = JSON.parse(m[1])
			if json.Result?.Record?
				ok: true
				files: (new TaskFile(f) for f in json.Result.Record)
				total: json.Result.btnum
				json: json
			else
				ok: false
				reason: "Can't find Result.Record"
				response: text
		else
			ok: false
			reason: "Can't parse response"
			response: text

	list_bt: (task, callback) ->
		if task.type != 'bt'
			callback ok: false, reason: 'Not a bt task'
			return

		@with_id (id) =>
			url = no_cache "/interface/fill_bt_list?callback=fill_bt_list&tid=#{task.id}&infoid=#{task.bt_hash}&g_net=1&p=1&uid=#{id}"
			@set_page_size_in_cokie 9999
			@get url, ({text}) =>
				result = @parse_fill_bt_list text
				{ok, files} = result
				if ok
					unless files.length == 1 and files[0].name == task.name
						for file in files
							file.dirs.unshift task.name
#							file.dirname = file.dirs.join '/'
							file.full_path = task.name + '/' + file.full_path
				callback result

	##########
	# delete #
	##########

	delete_tasks_by_id: (ids, callback) ->
		jsonp = "jsonp#{current_timestamp()}"
		form =
			taskids: ids.join(',')+','
			databases: '0,'
		url = no_cache "/interface/task_delete?callback=#{jsonp}&type=2" # XXX: what is 'type'?
		@post url, form, (result) ->
			if result.ok
				if result.text == """#{jsonp}({"result":1,"type":2})"""
					callback ok: true
				else
					callback
						ok: false
						reason: "Can't parse response"
						response: result.text
			else
				callback result

	delete_task_by_id: (id, callback) ->
		@delete_tasks_by_id [id], callback

################################################################################
# export
################################################################################

module.exports =
	XunleiClient: XunleiClient
	utils: utils
