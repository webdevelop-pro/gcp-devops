import base64
import json

def b64encode(s):
    return base64.b64encode(s.encode()).decode()

def to_json(s):
    return json.dumps(s)

def to_json_escape(s):
    ss = json.dumps(s)
    sss = json.dumps(ss)
    return sss[1:-1]
