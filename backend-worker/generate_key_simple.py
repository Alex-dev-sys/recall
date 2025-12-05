import base64
import os

# Генерируем 32 байта случайных данных
key = base64.urlsafe_b64encode(os.urandom(32))
print(key.decode())
