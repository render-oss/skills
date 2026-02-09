from django.http import JsonResponse


def health_check(request):
    return JsonResponse({"status": "ok"})


def hello(request):
    return JsonResponse({
        "message": "Hello from Django!",
    })
