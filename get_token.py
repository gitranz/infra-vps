import os, django, asyncio
from asgiref.sync import sync_to_async

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'khoj.app.settings')
django.setup()

from django.contrib.auth import get_user_model
from khoj.database.models import KhojToken # Re-attempting direct import

async def _get_token():
    User = get_user_model()
    user = await sync_to_async(User.objects.get)(email='hirnhaut@gmail.com')

    # Use synchronous ORM call wrapped in sync_to_async
    token_obj, created = await sync_to_async(KhojToken.objects.get_or_create)(user=user)
    print(token_obj.token)

if __name__ == '__main__':
    asyncio.run(_get_token())