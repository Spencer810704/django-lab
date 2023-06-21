from django.http import HttpResponse
import os
# Create your views here.

def index(request):
    env = ""
    for name, value in os.environ.items():
        env = env + f"{name}: {value}<br/>"
    # env =  os.environ.get("ENVIRONMENT")
    return HttpResponse(f"Hello, world. Environment: {env}")
    