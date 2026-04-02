import sys
import os
import re
import base64
import psutil
import platform
import socket
import subprocess
from datetime import datetime

try:
    import pyttsx3
    from llama_cpp import Llama
except ImportError as e:
    print(f"[!] ERRO FATAL: Biblioteca ausente ({e}). Execute o instalador novamente.")
    input("Pressione Enter para sair...")
    sys.exit(1)

if sys.stdout and hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')
if sys.stdin and hasattr(sys.stdin, 'reconfigure'):
    sys.stdin.reconfigure(encoding='utf-8')

def get_base_path():
    if getattr(sys, 'frozen', False):
        return os.path.dirname(sys.executable)
    return os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def resource_path(relative_path):
    if hasattr(sys, '_MEIPASS'):
        return os.path.join(sys._MEIPASS, relative_path)
    return os.path.join(get_base_path(), relative_path)

def decrypt_void(file_name):
    path = resource_path(file_name)
    if not os.path.exists(path):
        return ""
    try:
        with open(path, 'r', encoding='utf-8') as f:
            h = f.read().strip()
        step1 = base64.b64decode(h).decode('utf-8')[::-1]
        return base64.b64decode(step1).decode('utf-8')
    except Exception as e:
        return f"[ERRO DE LEITURA DA MEMORIA: {e}]"

def get_full_hardware_status():
    i = []
    i.append(f"HORARIO: {datetime.now().strftime('%H:%M:%S')}")
    i.append(f"DATA: {datetime.now().strftime('%d/%m/%Y')}")
    i.append(f"SISTEMA: {platform.system()} {platform.release()}")
    
    try:
        ram = psutil.virtual_memory()
        i.append(f"RAM_USO: {ram.percent}% ({ram.available // (1024**2)}MB livres)")
        i.append(f"CPU_USO: {psutil.cpu_percent()}%")
    except:
        i.append("RAM_USO: INDISPONIVEL | CPU_USO: INDISPONIVEL")

    try:
        mb = subprocess.check_output('wmic baseboard get product', shell=True, text=True, stderr=subprocess.DEVNULL).split('\n')[1].strip()
        i.append(f"PLACA_MAE: {mb}")
    except: pass

    try:
        gpu = subprocess.check_output('wmic path win32_videocontroller get name', shell=True, text=True, stderr=subprocess.DEVNULL).split('\n')[1].strip()
        if gpu: i.append(f"GPU: {gpu}")
    except: pass

    try:
        i.append(f"IP_LOCAL: {socket.gethostbyname(socket.gethostname())}")
    except: pass

    return " | ".join(i)

def inicializar_voz():
    try:
        engine = pyttsx3.init()
        return engine
    except Exception as e:
        print(f"[!] Aviso: Modulo de voz falhou ao iniciar. Executando em modo silencioso. Erro: {e}")
        return None

os.system('cls' if os.name == 'nt' else 'clear')
print("===================================================")
print("       LP77 ASSISTANT - NÚCLEO OPERACIONAL")
print("===================================================")
print("[*] Carregando memórias criptografadas...")

identity = decrypt_void("engine/identity.void")
commands = decrypt_void("engine/commands.void")
engine_voz = inicializar_voz()

base_dir = get_base_path()
model_path = os.path.join(base_dir, "engine", "void.brain")

if not os.path.exists(model_path):
    print(f"\n[!] ERRO CRÍTICO: Cérebro não encontrado.")
    print(f"[*] O arquivo 'void.brain' DEVE estar no caminho: {model_path}")
    input("\nPressione Enter para sair...")
    sys.exit(1)

print("[*] Acordando IA (Isso pode levar alguns segundos)...")
try:
    l = Llama(model_path=model_path, n_ctx=2048, verbose=False)
except Exception as e:
    print(f"\n[!] ERRO FATAL AO CARREGAR O MODELO: {e}")
    input("Pressione Enter para sair...")
    sys.exit(1)

print("\n[OK] SISTEMA ONLINE E PRONTO.")
print("===================================================\n")

while True:
    try:
        user_input = input("LP77 > ")
        if not user_input.strip(): continue
        if user_input.lower() in ['sair', 'exit', 'quit', 'desligar']: 
            print("[*] Encerrando processos...")
            break

        status = get_full_hardware_status()
        prompt = f"{identity}\n\n{commands}\n\n[STATUS_ATUAL]: {status}\n\nUsuario: {user_input}\nVoid:"

        response_raw = l(prompt, max_tokens=256, stop=["Usuario:", "LP77:"])['choices'][0]['text']
        
        fala = re.search(r'<fala>(.*?)</fala>', response_raw, re.IGNORECASE | re.DOTALL)
        exec_cmd = re.search(r'<exec>(.*?)</exec>', response_raw, re.IGNORECASE | re.DOTALL)
        danger_cmd = re.search(r'<perigo>(.*?)</perigo>', response_raw, re.IGNORECASE | re.DOTALL)

        if fala:
            txt = fala.group(1).strip()
            print(f"\nVOID: {txt}\n")
            if engine_voz:
                engine_voz.say(txt)
                engine_voz.runAndWait()
        else:
            clean_text = re.sub(r'<.*?>.*?</.*?>', '', response_raw).strip()
            if clean_text:
                print(f"\nVOID: {clean_text}\n")

        if danger_cmd:
            cmd = danger_cmd.group(1).strip()
            print(f"[!] ALERTA DE SEGURANÇA: A IA solicitou rodar: {cmd}")
            if input("AUTORIZAR? (s/n): ").strip().lower() == 's': 
                os.system(cmd)
            else:
                print("[*] Comando bloqueado.")
        elif exec_cmd:
            cmd = exec_cmd.group(1).strip()
            print(f"[*] Executando processo em background...")
            os.system(cmd)

    except KeyboardInterrupt:
        print("\n[*] Interrupção de teclado detectada. Encerrando...")
        break
    except Exception as e:
        print(f"\n[!] ERRO INTERNO: {e}")
