import base64
import json
import bcrypt

def b64encode(s):
    return base64.b64encode(s.encode()).decode()

def to_json(s):
    return json.dumps(s)

def to_json_escape(s):
    ss = json.dumps(s)
    sss = json.dumps(ss)
    return sss[1:-1]

def generate_htpasswd(username, password):
    bcrypted = bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt(rounds=12)).decode("utf-8")
    return f"{username}:{bcrypted}"