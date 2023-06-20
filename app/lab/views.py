from django.http import HttpResponse
import os
# Create your views here.

def index(request):
    env =  os.environ.get("ENVIRONMENT")
    return HttpResponse(f"Hello, world. Environment: {env}")
    