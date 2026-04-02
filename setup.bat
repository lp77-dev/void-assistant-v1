@echo off
setlocal EnableDelayedExpansion
title VOID ASSISTANT - SYSTEM
color 0b

echo ===================================================
echo                VOID ASSISTANT (v1.0)
echo ===================================================

:: 1. CACA AO NUCLEO PYTHON
set "PY_CMD="

python --version >nul 2>&1
if %errorlevel% equ 0 set "PY_CMD=python"

if not defined PY_CMD (
    py --version >nul 2>&1
    if %errorlevel% equ 0 set "PY_CMD=py"
)

if not defined PY_CMD (
    for /d %%i in ("%LocalAppData%\Programs\Python\Python3*") do (
        if exist "%%i\python.exe" set "PY_CMD=%%i\python.exe"
    )
)
if not defined PY_CMD (
    for /d %%i in ("C:\Program Files\Python3*") do (
        if exist "%%i\python.exe" set "PY_CMD=%%i\python.exe"
    )
)

if not defined PY_CMD (
    echo [!] Python nao localizado no sistema.
    echo [*] Baixando e configurando automaticamente (Aguarde)...
    winget install Python.Python.3.12 --silent --override "/quiet InstallAllUsers=1 PrependPath=1 Include_test=0"
    echo.
    echo ===================================================
    echo [OK] PYTHON INSTALADO COM SUCESSO!
    echo O Windows precisa de 1 segundo para processar.
    echo FECHE ESTA TELA E ABRA O SETUP NOVAMENTE.
    echo ===================================================
    pause
    exit
)

echo [OK] Motor Python localizado e validado.
set PY_CMD=!PY_CMD:"=!

:: 2. VERIFICACAO DO AMBIENTE (VENV)
if not exist "venv" (
    echo [*] Criando ambiente de contencao (VENV)...
    "!PY_CMD!" -m venv venv
) else (
    echo [OK] VENV detectado.
)

call venv\Scripts\activate

:: 3. VERIFICACAO DE BIBLIOTECAS
python -c "import llama_cpp, vosk, pyttsx3, psutil" >nul 2>&1
if %errorlevel% neq 0 (
    echo [*] Instalando dependencias pendentes...
    python -m pip install --upgrade pip >nul 2>&1
    pip install vosk pyttsx3 keyboard sounddevice scipy psutil llama-cpp-python --extra-index-url https://abetlen.github.io/llama-cpp-python/whl/cpu >nul 2>&1
) else (
    echo [OK] Bibliotecas sincronizadas.
)

if not exist "engine" mkdir engine

:: 4. VERIFICACAO DA BASE DE DADOS
if not exist "engine.void" (
    echo [*] Baixando mapa de motores...
    powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/lp77-dev/void-assistant-v1/main/engine.void' -OutFile 'engine.void'" >nul 2>&1
)

:: 5. VERIFICACAO DO MOTOR
if exist "engine\void.brain" (
    echo [OK] Motor ja instalado. Pulando download.
    goto SKIP_ENGINE
)

echo.
echo ===================================================
echo                SELECAO DE NUCLEO
echo ===================================================
echo [1] Void-1-1B (Foco em Baixa Latencia - Mais Rapido)
echo [2] Void-1-2B (Foco em Processamento Hibrido - Medio)
echo [3] Void-1-3B (Foco em Decisoes Criticas - Inteligente)
echo ===================================================
set /p choice="INPUT SELECTION (1/2/3): "

if "%choice%"=="1" set TGT=1B
if "%choice%"=="2" set TGT=2B
if "%choice%"=="3" set TGT=3B

echo [*] Decodificando rota segura...
for /f "delims=" %%i in ('python -c "import json,base64; d=json.load(open('engine.void')); v=d['%TGT%'][::-1]; print(base64.b64decode(v).decode('utf-8'))"') do set RAW_URL=%%i

echo [*] Puxando Void.%TGT% do servidor...
powershell -Command "Invoke-WebRequest -Uri '!RAW_URL!' -OutFile 'engine\void.brain'"

:SKIP_ENGINE
:: 6. VERIFICACAO DO MODULO DE VOZ
if not exist "vosk-model" (
    echo [*] Baixando modulos de audicao...
    powershell -Command "Invoke-WebRequest -Uri 'https://alphacephei.com/vosk/models/vosk-model-small-pt-0.3.zip' -OutFile 'vosk.zip'; Expand-Archive -Path 'vosk.zip' -DestinationPath '.'; Move-Item -Path 'vosk-model-small-pt-0.3' -Destination 'vosk-model'; Remove-Item 'vosk.zip'" >nul 2>&1
) else (
    echo [OK] Modulo Vosk detectado.
)

:: 7. VERIFICACAO DA ARQUITETURA E MEMORIA
if not exist "engine\main.py" (
    echo [*] Baixando Sistema Nervoso e Memorias Criptografadas...
    powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/lp77-dev/void-assistant-v1/main/engine/main.py' -OutFile 'engine\main.py'" >nul 2>&1
    powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/lp77-dev/void-assistant-v1/main/engine/identity.void' -OutFile 'engine\identity.void'" >nul 2>&1
    powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/lp77-dev/void-assistant-v1/main/engine/commands.void' -OutFile 'engine\commands.void'" >nul 2>&1
)

:: 8. GERACAO DO LAUNCHER
if not exist "Iniciar_Void.bat" (
    echo @echo off > Iniciar_Void.bat
    echo chcp 65001 ^>nul >> Iniciar_Void.bat
    echo title VOID ASSISTANT - TERMINAL >> Iniciar_Void.bat
    echo color 0c >> Iniciar_Void.bat
    echo call venv\Scripts\activate >> Iniciar_Void.bat
    echo python engine\main.py >> Iniciar_Void.bat
)

echo.
echo ===================================================
echo [OK] SISTEMA PRONTO PARA OPERACAO.
echo ===================================================
pause
