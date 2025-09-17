import json
import urllib.request
import ssl
import certifi
from pathlib import Path

# Fix SSL certificates for macOS
ssl_context = ssl.create_default_context(cafile=certifi.where())
ssl._create_default_https_context = lambda: ssl_context

values = {}
for raw_line in Path('.env').read_text().splitlines():
    line = raw_line.strip()
    if not line or line.startswith('#'):
        continue
    if '=' not in line:
        continue
    key, value = [part.strip() for part in line.split('=', 1)]
    values[key] = value

required = [
    'AZURE_ENDPOINT_URL',
    'AZURE_API_KEY',
    'AZURE_DEPLOYMENT',
    'AZURE_API_VERSION'
]
missing = [key for key in required if not values.get(key)]
if missing:
    raise SystemExit(f"Missing required keys: {', '.join(missing)}")

endpoint = values['AZURE_ENDPOINT_URL'].rstrip('/')
path = f"/openai/deployments/{values['AZURE_DEPLOYMENT']}/chat/completions?api-version={values['AZURE_API_VERSION']}"
url = endpoint + path

payload = {
    'messages': [{'role': 'user', 'content': 'Say hello!'}],
    'max_tokens': 20,
    'temperature': 0,
}

request = urllib.request.Request(
    url,
    data=json.dumps(payload).encode('utf-8'),
    headers={
        'Content-Type': 'application/json',
        'api-key': values['AZURE_API_KEY'],
    },
    method='POST'
)

with urllib.request.urlopen(request, timeout=20) as response:
    print('HTTP', response.status)
    print(response.read().decode('utf-8'))
