@echo off
title LP77 - VOID IA
set "TEMP_PS1=%~dp0temp_setup.ps1"
powershell -NoProfile -Command "Get-Content '%~f0' | Select-Object -Skip 10 | Set-Content '%TEMP_PS1%' -Encoding UTF8"
powershell -NoProfile -ExecutionPolicy Bypass -File "%TEMP_PS1%"
if exist "%TEMP_PS1%" del "%TEMP_PS1%"
exit /b

$Host.UI.RawUI.WindowTitle = "VOID ASSISTANT - SYSTEM"
Clear-Host
Write-Host "==================================================="
Write-Host "                VOID ASSISTANT (v1.0)"
Write-Host "==================================================="
$PY_CMD = ""
$allPy = Where-Object { $_.Source -notlike "*WindowsApps*" } -InputObject (Get-Command "python" -All -ErrorAction SilentlyContinue)
if ($allPy) { $PY_CMD = $allPy[0].Path }
if (-not $PY_CMD) {
    $allPy = Where-Object { $_.Source -notlike "*WindowsApps*" } -InputObject (Get-Command "py" -All -ErrorAction SilentlyContinue)
    if ($allPy) { $PY_CMD = $allPy[0].Path }
}
if (-not $PY_CMD) {
    $paths = @("$env:LOCALAPPDATA\Programs\Python", "C:\Program Files\Python")
    foreach ($p in $paths) {
        if (Test-Path $p) {
            $dir = Get-ChildItem $p -Directory | Where-Object { $_.Name -like "Python3*" } | Select-Object -First 1
            if ($dir) { $PY_CMD = Join-Path $dir.FullName "python.exe" }
        }
    }
}
if (-not $PY_CMD) {
    Write-Host "[!] Python nao localizado no sistema."
    Write-Host "[*] Tentando instalacao automatica via WinGet..."
    winget install Python.Python.3.12 --silent --override "/quiet InstallAllUsers=1 PrependPath=1 Include_test=0"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[!] WinGet falhou ou nao existe neste Windows."
        Write-Host "[*] Iniciando Protocolo de Download Direto (PowerShell)..."
        Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.12.2/python-3.12.2-amd64.exe' -OutFile 'python_installer.exe'
        if (Test-Path "python_installer.exe") {
            Write-Host "[*] Executando instalador silencioso..."
            Start-Process -FilePath "python_installer.exe" -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1 Include_test=0" -Wait
            Remove-Item "python_installer.exe"
        } else {
            Write-Host "[!] ERRO CRITICO: Nao foi possivel baixar o Python."
            Write-Host "[*] Instale manualmente em python.org e marque `"Add to PATH`"."
            Read-Host "Pressione Enter para sair"
            exit
        }
    }
    Write-Host ""
    Write-Host "==================================================="
    Write-Host "[OK] PYTHON INSTALADO COM SUCESSO!"
    Write-Host "O Windows precisa de alguns segundos para processar."
    Write-Host "FECHE ESTA TELA E ABRA O SETUP NOVAMENTE."
    Write-Host "==================================================="
    Read-Host "Pressione Enter para fechar"
    exit
}
Write-Host "[OK] Motor Python localizado e validado."
if (-not (Test-Path "venv")) {
    Write-Host "[*] Criando ambiente de contencao (VENV)..."
    Start-Process -FilePath $PY_CMD -ArgumentList "-m venv venv" -Wait
} else {
    Write-Host "[OK] VENV detectado."
}
$python_venv = Join-Path (Get-Location) "venv\Scripts\python.exe"
$pip_venv = Join-Path (Get-Location) "venv\Scripts\pip.exe"
Write-Host "[*] Instalando dependencias pendentes..."
if (Test-Path $pip_venv) {
    & $python_venv -m pip install --upgrade pip --quiet
    & $pip_venv install vosk pyttsx3 keyboard sounddevice scipy psutil llama-cpp-python --extra-index-url https://abetlen.github.io/llama-cpp-python/whl/cpu --quiet
    Write-Host "[OK] Bibliotecas sincronizadas."
}
if (-not (Test-Path "engine")) { New-Item -ItemType Directory -Path "engine" | Out-Null }
if (-not (Test-Path "engine.void")) {
    Write-Host "[*] Baixando mapa de motores..."
    try { Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/lp77-dev/void-assistant-v1/main/engine.void' -OutFile 'engine.void' } catch {}
}
if (Test-Path "engine\void.brain") {
    Write-Host "[OK] Motor ja instalado. Pulando download."
} else {
    Write-Host "`n==================================================="
    Write-Host "                SELECAO DE NUCLEO"
    Write-Host "==================================================="
    Write-Host "[1] Void-1-1B (Foco em Baixa Latencia - Mais Rapido)"
    Write-Host "[2] Void-1-2B (Foco em Processamento Hibrido - Medio)"
    Write-Host "[3] Void-1-3B (Foco em Decisoes Criticas - Inteligente)"
    Write-Host "==================================================="
    $choice = Read-Host "INPUT SELECTION (1/2/3)"
    if ($choice -eq "1") { $TGT = "1B" } elseif ($choice -eq "2") { $TGT = "2B" } else { $TGT = "3B" }
    Write-Host "[*] Decodificando rota segura..."
    if (Test-Path "engine.void") {
        $RAW_URL = & $python_venv -c "import json,base64; d=json.load(open('engine.void')); v=d['$TGT'][::-1]; print(base64.b64decode(v).decode('utf-8'))"
        Write-Host "[*] Puxando Void.$TGT do servidor..."
        if ($RAW_URL) { Invoke-WebRequest -Uri $RAW_URL -OutFile 'engine\void.brain' }
    }
}
if (-not (Test-Path "vosk-model")) {
    Write-Host "[*] Baixando modulos de audicao..."
    Invoke-WebRequest -Uri 'https://alphacephei.com/vosk/models/vosk-model-small-pt-0.3.zip' -OutFile 'vosk.zip'
    Expand-Archive -Path 'vosk.zip' -DestinationPath '.'
    Move-Item -Path 'vosk-model-small-pt-0.3' -Destination 'vosk-model'
    Remove-Item 'vosk.zip'
}
if (-not (Test-Path "engine\main.py")) {
    Write-Host "[*] Baixando Sistema e Memorias..."
    Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/lp77-dev/void-assistant-v1/main/engine/main.py' -OutFile 'engine\main.py'
    Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/lp77-dev/void-assistant-v1/main/engine/identity.void' -OutFile 'engine\identity.void'
    Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/lp77-dev/void-assistant-v1/main/engine/commands.void' -OutFile 'engine\commands.void'
}
if (-not (Test-Path "Iniciar_Void.bat")) {
    $launcher = "@echo off`r`nchcp 65001 >nul`r`ntitle VOID ASSISTANT - TERMINAL`r`ncolor 0c`r`ncall venv\Scripts\activate`r`npython engine\main.py"
    Set-Content -Path "Iniciar_Void.bat" -Value $launcher
}
Write-Host "`n==================================================="
Write-Host "[OK] SISTEMA PRONTO PARA OPERACAO."
Write-Host "==================================================="
Read-Host "Pressione Enter para fechar"
