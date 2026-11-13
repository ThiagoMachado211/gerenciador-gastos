class SecurityHeaders:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        response = self.get_response(request)
        response['Content-Security-Policy'] = "default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self' data:; object-src 'none'; base-uri 'self'; form-action 'self'; frame-ancestors 'none'"
        response['Permissions-Policy'] = 'camera=(), microphone=(), geolocation=()'
        if request.user.is_authenticated:
            response['Cache-Control'] = 'no-store'
        return response
