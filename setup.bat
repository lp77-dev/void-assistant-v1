@echo off
setlocal EnableDelayedExpansion
title LP77 - VOID DEPLOY SYSTEM
color 0b

echo ===================================================
echo           SISTEMA DE INSTALACAO LP77
echo ===================================================

:CHECK_PYTHON
echo [*] Procurando motor Python no sistema...
set "PY_CMD="

:: Teste 1: Comando padrao
python --version >nul 2>&1
if !errorlevel! equ 0 (
    set "PY_CMD=python"
    goto PYTHON_FOUND
)

:: Teste 2: Launcher 'py'
py --version >nul 2>&1
if !errorlevel! equ 0 (
    set "PY_CMD=py"
    goto PYTHON_FOUND
)

:: Teste 3: Pastas Locais (AppData)
for /d %%i in ("%LocalAppData%\Programs\Python\Python3*") do (
    if exist "%%i\python.exe" (
        set "PY_CMD=%%i\python.exe"
        goto PYTHON_FOUND
    )
)

:INSTALL_PYTHON
echo [!] Python nao encontrado. Iniciando Protocolos de Instalacao...

:: Tentativa A: WinGet (Nativo do Windows 10/11)
echo [*] Tentando via WinGet...
winget install Python.Python.3.12 --silent --override "/quiet InstallAllUsers=1 PrependPath=1" >nul 2>&1
if !errorlevel! equ 0 goto INSTALL_SUCCESS

:: Tentativa B: PowerShell (Download Direto do site oficial)
echo [*] WinGet falhou. Baixando instalador oficial via PowerShell...
powershell -Command "Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.12.2/python-3.12.2-amd64.exe' -OutFile 'py_installer.exe'" >nul 2>&1
if exist py_installer.exe (
    echo [*] Executando instalador...
    start /wait py_installer.exe /quiet InstallAllUsers=1 PrependPath=1
    del py_installer.exe
    goto INSTALL_SUCCESS
)

echo [ERRO] Nao foi possivel instalar o Python automaticamente.
echo Instale manualmente em python.org e marque a caixa "Add to PATH".
pause
exit

:INSTALL_SUCCESS
echo ===================================================
echo [OK] PYTHON INJETADO! FECHE E ABRA O SETUP NOVAMENTE.
echo ===================================================
pause
exit

:PYTHON_FOUND
echo [OK] Python localizado em: !PY_CMD!
set PY_CMD=!PY_CMD:"=!

:VENV_STAGE
if exist "venv" (
    echo [OK] Ambiente isolado (VENV) ja existe.
) else (
    echo [*] Criando ambiente isolado (VENV)...
    "!PY_CMD!" -m venv venv
)
call venv\Scripts\activate

:LIB_STAGE
echo [*] Sincronizando bibliotecas da IA...
python -m pip install --upgrade pip >nul 2>&1
pip install vosk pyttsx3 psutil llama-cpp-python --extra-index-url https://abetlen.github.io/llama-cpp-python/whl/cpu

:FILES_STAGE
if not exist "engine" mkdir engine
echo [*] Puxando arquivos vitais do GitHub...

powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/lp77-dev/void-assistant-v1/main/engine.void' -OutFile 'engine.void'"
powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/lp77-dev/void-assistant-v1/main/engine/main.py' -OutFile 'engine/main.py'"
powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/lp77-dev/void-assistant-v1/main/engine/identity.void' -OutFile 'engine/identity.void'"
powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/lp77-dev/void-assistant-v1/main/engine/commands.void' -OutFile 'engine/commands.void'"

:MODEL_STAGE
if exist "engine\void.brain" goto VOICE_STAGE
echo.
echo ===================================================
echo SELECIONE O MODELO (NUCLEO):
echo [1] 1B (Leve) | [2] 2B (Medio) | [3] 3B (Inteligente)
echo ===================================================
set /p choice="Escolha: "

if "%choice%"=="1" set TGT=1B
if "%choice%"=="2" set TGT=2B
if "%choice%"=="3" set TGT=3B

echo [*] Decodificando link e baixando motor...
for /f "delims=" %%i in ('python -c "import json,base64; d=json.load(open('engine.void')); v=d['%TGT%'][::-1]; print(base64.b64decode(v).decode('utf-8'))"') do set RAW_URL=%%i
powershell -Command "Invoke-WebRequest -Uri '!RAW_URL!' -OutFile 'engine\void.brain'"

:VOICE_STAGE
if exist "vosk-model" goto FINAL_STAGE
echo [*] Baixando modulo de voz (Vosk)...
powershell -Command "Invoke-WebRequest -Uri 'https://alphacephei.com/vosk/models/vosk-model-small-pt-0.3.zip' -OutFile 'v.zip'; Expand-Archive 'v.zip' '.'; Move-Item 'vosk-model-small-pt-0.3' 'vosk-model'; Remove-Item 'v.zip'"

:FINAL_STAGE
if not exist "Iniciar_Void.bat" (
    echo @echo off > Iniciar_Void.bat
    echo chcp 65001 ^>nul >> Iniciar_Void.bat
    echo call venv\Scripts\activate >> Iniciar_Void.bat
    echo python engine\main.py >> Iniciar_Void.bat
)

echo.
echo ===================================================
echo [OK] DEPLOY CONCLUIDO. USE O 'Iniciar_Void.bat'.
echo ===================================================
pause
