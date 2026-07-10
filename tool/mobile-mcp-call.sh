#!/usr/bin/env bash
# Call mobile-mcp tools via stdio.
# Usage: mobile-mcp-call.sh <tool_name> '<json_args>'
TOOL="$1"
ARGS="${2:-{}}"

python3 -c "
import subprocess, json, sys

proc = subprocess.Popen(
    ['mcp-server-mobile', '--stdio'],
    stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
    text=True
)

# Send init
init = json.dumps({'jsonrpc':'2.0','id':1,'method':'initialize','params':{'protocolVersion':'2024-11-05','capabilities':{},'clientInfo':{'name':'claude','version':'1.0'}}})
proc.stdin.write(init + '\n')
proc.stdin.flush()

# Read init response
proc.stdout.readline()

# Send tool call
call = json.dumps({'jsonrpc':'2.0','id':2,'method':'tools/call','params':{'name':'$TOOL','arguments':$ARGS}})
proc.stdin.write(call + '\n')
proc.stdin.flush()

# Read tool response
resp = proc.stdout.readline()
print(resp.strip())

proc.terminate()
"
