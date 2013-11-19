
username_element = document.getElementById 'username'
password_element = document.getElementById 'password'
login_element = document.getElementById 'login'
save_element = document.getElementById 'save'
verify_element = document.getElementById 'verify'
verification_image_element = document.getElementById 'verification_image'
verification_code_element = document.getElementById 'verification_code'

login_element.addEventListener 'click', ->
	if verify_element.style.display != 'none'
		verification_code = verification_code_element.value
	self.port.emit 'login', username: username_element.value, password: password_element.value, save: save_element.checked, verification_code: verification_code

verification_image_element.addEventListener 'click', ->
	verification_image_element.src = "http://verify2.xunlei.com/image?cachetime=#{new Date().getTime()}"

self.port.on 'login', ({username, password, save, verification_code}) ->
	username_element.value = username ? ''
	password_element.value = password ? ''
	save_element.checked = Boolean save
	if verification_code
		verify_element.style.display = 'block'
		verification_image_element.src = verification_code
	else
		verify_element.style.display = 'none'
