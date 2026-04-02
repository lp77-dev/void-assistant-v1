import customtkinter as ctk
import os, sys, json, base64, urllib.request, threading
from llama_cpp import Llama

ctk.set_appearance_mode("dark")
ctk.set_default_color_theme("blue")

def get_base_path():
    if getattr(sys, 'frozen', False): return os.path.dirname(sys.executable)
    return os.path.dirname(os.path.abspath(__file__))

BASE_DIR = get_base_path()
ENGINE_DIR = os.path.join(BASE_DIR, "engine")
BRAIN_PATH = os.path.join(ENGINE_DIR, "void.brain")
os.makedirs(ENGINE_DIR, exist_ok=True)

class VoidApp(ctk.CTk):
    def __init__(self):
        super().__init__()
        self.title("LP77 - VOID ASSISTANT")
        self.geometry("900x600")
        self.llm = None
        self.identity = "Voce e a Void, assistente da LP77."
        
        if not os.path.exists(BRAIN_PATH):
            self.setup_installer_ui()
        else:
            self.setup_loading_ui()
            threading.Thread(target=self.load_ai, daemon=True).start()

    def setup_installer_ui(self):
        self.clear_window()
        self.inst_frame = ctk.CTkFrame(self, fg_color="transparent")
        self.inst_frame.pack(expand=True, fill="both", padx=50, pady=50)
        
        ctk.CTkLabel(self.inst_frame, text="VOID DEPLOY SYSTEM", font=("Roboto", 28, "bold")).pack(pady=20)
        ctk.CTkLabel(self.inst_frame, text="Nenhum nucleo detectado. Selecione a arquitetura para download:").pack(pady=10)
        
        self.btn_1b = ctk.CTkButton(self.inst_frame, text="Void-1-1B (Rapido)", command=lambda: self.start_download("1B"))
        self.btn_1b.pack(pady=10)
        self.btn_2b = ctk.CTkButton(self.inst_frame, text="Void-1-2B (Equilibrado)", command=lambda: self.start_download("2B"))
        self.btn_2b.pack(pady=10)
        self.btn_3b = ctk.CTkButton(self.inst_frame, text="Void-1-3B (Inteligente)", command=lambda: self.start_download("3B"))
        self.btn_3b.pack(pady=10)
        
        self.progress_lbl = ctk.CTkLabel(self.inst_frame, text="")
        self.progress_lbl.pack(pady=10)
        self.progress_bar = ctk.CTkProgressBar(self.inst_frame, width=400)
        self.progress_bar.set(0)
        self.progress_bar.pack(pady=10)
        self.progress_bar.pack_forget()

    def start_download(self, core_type):
        self.btn_1b.configure(state="disabled")
        self.btn_2b.configure(state="disabled")
        self.btn_3b.configure(state="disabled")
        self.progress_bar.pack()
        threading.Thread(target=self.download_model, args=(core_type,), daemon=True).start()

    def download_model(self, core_type):
        try:
            self.progress_lbl.configure(text="Sincronizando com GitHub LP77...")
            req = urllib.request.urlopen("https://raw.githubusercontent.com/lp77-dev/void-assistant-v1/main/engine.void")
            data = json.loads(req.read().decode('utf-8'))
            enc_url = data[core_type][::-1]
            url = base64.b64decode(enc_url).decode('utf-8')
            
            self.progress_lbl.configure(text=f"Baixando Nucleo {core_type}...")
            
            def report(blocknum, blocksize, totalsize):
                readsofar = blocknum * blocksize
                if totalsize > 0:
                    percent = readsofar * 100 / totalsize
                    self.progress_bar.set(percent / 100)
                    self.progress_lbl.configure(text=f"Baixando: {int(percent)}%")
            
            urllib.request.urlretrieve(url, BRAIN_PATH, report)
            self.progress_lbl.configure(text="Download Concluido! Iniciando Motor...")
            self.setup_loading_ui()
            self.load_ai()
        except Exception as e:
            self.progress_lbl.configure(text=f"Erro FATAL: {e}")

    def setup_loading_ui(self):
        self.clear_window()
        self.load_frame = ctk.CTkFrame(self, fg_color="transparent")
        self.load_frame.pack(expand=True)
        ctk.CTkLabel(self.load_frame, text="ACORDANDO A IA...", font=("Roboto", 24, "bold")).pack()
        self.spinner = ctk.CTkProgressBar(self.load_frame, mode="indeterminate")
        self.spinner.pack(pady=20)
        self.spinner.start()

    def load_ai(self):
        try:
            self.llm = Llama(model_path=BRAIN_PATH, n_ctx=2048, verbose=False)
            self.after(0, self.setup_chat_ui)
        except Exception as e:
            self.after(0, lambda: ctk.CTkLabel(self.load_frame, text=f"ERRO DE MOTOR: {e}", text_color="red").pack())

    def setup_chat_ui(self):
        self.clear_window()
        
        self.top_bar = ctk.CTkFrame(self, height=50, corner_radius=0)
        self.top_bar.pack(side="top", fill="x")
        ctk.CTkLabel(self.top_bar, text="LP77 - VOID", font=("Roboto", 16, "bold")).pack(side="left", padx=20)
        ctk.CTkButton(self.top_bar, text="⚙️ Config", width=50, fg_color="transparent", border_width=1).pack(side="right", padx=10, pady=10)

        self.chat_box = ctk.CTkTextbox(self, state="disabled", wrap="word", font=("Roboto", 14))
        self.chat_box.pack(expand=True, fill="both", padx=20, pady=20)

        self.input_frame = ctk.CTkFrame(self, fg_color="transparent")
        self.input_frame.pack(side="bottom", fill="x", padx=20, pady=20)
        
        self.entry = ctk.CTkEntry(self.input_frame, placeholder_text="Mande uma mensagem para a Void...", height=40)
        self.entry.pack(side="left", expand=True, fill="x", padx=(0, 10))
        self.entry.bind("<Return>", lambda e: self.send_message())
        
        self.btn_send = ctk.CTkButton(self.input_frame, text="Enviar", width=80, height=40, command=self.send_message)
        self.btn_send.pack(side="right")

        self.append_chat("Void", "Sistemas online. Como posso ajudar a LP77 hoje?")

    def append_chat(self, sender, text):
        self.chat_box.configure(state="normal")
        self.chat_box.insert("end", f"\n{sender}:\n{text}\n" + "-"*40 + "\n")
        self.chat_box.configure(state="disabled")
        self.chat_box.yview("end")

    def send_message(self):
        user_text = self.entry.get().strip()
        if not user_text: return
        self.entry.delete(0, "end")
        self.append_chat("Voce", user_text)
        self.btn_send.configure(state="disabled")
        threading.Thread(target=self.generate_response, args=(user_text,), daemon=True).start()

    def generate_response(self, user_text):
        prompt = f"{self.identity}\nUsuario: {user_text}\nVoid:"
        try:
            res = self.llm(prompt, max_tokens=256, stop=["Usuario:", "LP77:"])['choices'][0]['text'].strip()
            self.after(0, lambda: self.append_chat("Void", res))
        except Exception as e:
            self.after(0, lambda: self.append_chat("ERRO", str(e)))
        finally:
            self.after(0, lambda: self.btn_send.configure(state="normal"))

    def clear_window(self):
        for widget in self.winfo_children(): widget.pack_forget()

if __name__ == "__main__":
    app = VoidApp()
    app.mainloop()
