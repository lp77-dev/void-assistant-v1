import sys
import os
import re
import base64
import psutil
import platform
import socket
import subprocess
from datetime import datetime
import pyttsx3
from llama_cpp import Llama

sys.stdout.reconfigure(encoding='utf-8')
sys.stdin.reconfigure(encoding='utf-8')

def d(f_n):
    if not os.path.exists(f_n):
        return ""
    try:
        with open(f_n, 'r', encoding='utf-8') as f:
            h = f.read().strip()
        return base64.b64decode(base64.b64decode(h).decode('utf-8')[::-1]).decode('utf-8')
    except:
        return ""

def get_sys_info():
    i = []
    i.append(f"DATA_HORA: {datetime.now().strftime('%d/%m/%Y %H:%M:%S')}")
    i.append(f"OS: {platform.system()} {platform.release()} ({platform.version()})")
    i.append(f"CPU: {platform.processor()} | USO: {psutil.cpu_percent()}% | THREADS: {psutil.cpu_count(logical=True)}")
    r = psutil.virtual_memory()
    i.append(f"RAM: USO {r.percent}% | DISP {r.available // (1024**2)}MB | TOTAL {r.total // (1024**2)}MB")
    d_ = psutil.disk_usage('C:\\')
    i.append(f"DISCO_C: USO {d_.percent}% | LIVRE {d_.free // (1024**3)}GB")
    i.append(f"HOSTNAME: {socket.gethostname()}")
    
    try:
        w = subprocess.check_output('netsh wlan show interfaces', shell=True, text=True, stderr=subprocess.DEVNULL)
        ssid = re.search(r'SSID\s*:\s(.*)', w)
        i.append(f"WIFI: {ssid.group(1).strip() if ssid else 'LAN/Desconectado'}")
    except:
        pass
        
    try:
        mb = subprocess.check_output('wmic baseboard get product', shell=True, text=True, stderr=subprocess.DEVNULL).replace('Product', '').strip()
        i.append(f"PLACA_MAE: {mb}")
    except:
        pass
        
    try:
        gpu = subprocess.check_output('wmic path win32_videocontroller get name', shell=True, text=True, stderr=subprocess.DEVNULL).replace('Name', '').strip()
        i.append(f"GPU: {gpu}")
    except:
        pass
        
    b = psutil.sensors_battery()
    if b:
        i.append(f"BATERIA: {b.percent}% | PLUGADO: {b.power_plugged}")
        
    return " || ".join(i)

def p(t):
    f = re.search(r'<fala>(.*?)</fala>', t, re.S)
    e = re.search(r'<exec>(.*?)</exec>', t, re.S)
    pr = re.search(r'<perigo>(.*?)</perigo>', t, re.S)
    return {
        "f": f.group(1).strip() if f else "",
        "e": e.group(1).strip() if e else None,
        "p": pr.group(1).strip() if pr else None
    }

iden = d("engine/identity.void")
cmds = d("engine/commands.void")

e = pyttsx3.init()
l = Llama(model_path="engine/void.brain", n_ctx=2048)

os.system('cls' if os.name == 'nt' else 'clear')
print("[ VOID ASSISTANT ONLINE | LP77 NATIVE ]")

while True:
    c = input("\nLP77 > ")
    if c.lower() in ['sair', 'exit', 'quit']:
        break
        
    s = get_sys_info()
    pr = f"{iden}\n\n{cmds}\n\nSTATUS_SISTEMA: {s}\n\nUsuario: {c}\nVoid:"
    
    out = l(pr, max_tokens=300, stop=["Usuario:", "LP77:"])
    r = out['choices'][0]['text']
    x = p(r)
    
    if x["f"]:
        print(f"VOID: {x['f']}")
        e.say(x['f'])
        e.runAndWait()
        
    if x["p"]:
        print(f"\n[!] COMANDO PERIGOSO: {x['p']}")
        if input("AUTORIZAR EXECUCAO CRITICA? (S/N): ").upper() == 'S':
            os.system(x['p'])
    elif x["e"]:
        os.system(x['e'])
