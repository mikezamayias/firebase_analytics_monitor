#!/usr/bin/env python3
"""Call mobile-mcp tools via stdio. Usage: mobile-mcp-call.py <tool_name> [json_args]"""
import subprocess, json, sys, select, time

tool = sys.argv[1]
args = json.loads(sys.argv[2]) if len(sys.argv) > 2 else {}

proc = subprocess.Popen(
    ['mcp-server-mobile', '--stdio'],
    stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
    text=True, bufsize=1
)

def send(msg):
    proc.stdin.write(json.dumps(msg) + '\n')
    proc.stdin.flush()

def read_response(timeout=30):
    buf = ''
    deadline = time.time() + timeout
    while time.time() < deadline:
        ready, _, _ = select.select([proc.stdout], [], [], 0.5)
        if ready:
            chunk = proc.stdout.readline()
            if chunk:
                buf += chunk
                try:
                    return json.loads(buf.strip())
                except json.JSONDecodeError:
                    continue
    return None

send({
    'jsonrpc': '2.0', 'id': 1, 'method': 'initialize',
    'params': {
        'protocolVersion': '2024-11-05',
        'capabilities': {},
        'clientInfo': {'name': 'claude', 'version': '1.0'}
    }
})
read_response(10)

send({
    'jsonrpc': '2.0', 'id': 2, 'method': 'tools/call',
    'params': {'name': tool, 'arguments': args}
})
resp = read_response(30)

if resp:
    content = resp.get('result', {}).get('content', [])
    for c in content:
        if c.get('type') == 'text':
            print(c['text'])
        elif c.get('type') == 'image':
            print(f"[image: {len(c.get('data',''))} bytes base64]")
else:
    print('TIMEOUT: no response within 30s')

proc.terminate()
