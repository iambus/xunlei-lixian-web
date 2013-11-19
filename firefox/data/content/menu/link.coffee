

#self.on "context", (node, data) ->
#	return true

self.on "click", (node, data) ->
	self.postMessage(node.href)
