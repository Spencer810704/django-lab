from django.http import HttpResponse
import os
# Create your views here.

def index(request):
    env_var = ""
    for name, value in os.environ.items():
        env_var = env_var + f"{name}: {value}<br/>"
    env =  os.environ.get("ENVIRONMENT")
    return HttpResponse(f"Environment: {env}<br/><br/> Variables:{env_var}")
    