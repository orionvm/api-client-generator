class APIConnectionError(Exception):
	pass

class APIError(Exception):
	def __init__(self, json, body, status, message=None):
		self.json = json
		self.body = body
		self.status = status

		if message == None:
			message = body

		super(APIError, self).__init__(message)

class AuthenticationError(APIError):
	pass
class UnauthorizedError(APIError):
	pass
class InvalidRequestError(APIError):
	pass
class ValidationError(APIError):
	def __init__(self, json, body, status):
		msg = "%s: %s" % (json['error'], json['details'])
		super(ValidationError, self).__init__(json, body, status, msg)
