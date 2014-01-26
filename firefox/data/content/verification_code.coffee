
ok = document.getElementById 'ok'
verification_image_element = document.getElementById 'verification_image'
verification_code_element = document.getElementById 'verification_code'

refresh = ->
	verification_image_element.src = "http://verify2.xunlei.com/image?t=MVA&cachetime=#{new Date().getTime()}"
	verification_code_element.focus()
	verification_code_element.select()

done = ->
	verification_code = verification_code_element.value
	self.port.emit 'verify', verification_code

self.port.on 'verify', refresh

verification_image_element.addEventListener 'click', refresh


ok.addEventListener 'click', done

verification_code_element.addEventListener 'keypress', (e) ->
	if e.keyCode == 13
		done()

