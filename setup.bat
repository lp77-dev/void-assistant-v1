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
$searchPaths = @(
    "$env:LOCALAPPDATA\Programs\Python",
    "$env:ProgramFiles\Python",
    "C:\Python312",
    "C:\Python311"
)
foreach ($p in $searchPaths) {
    if (Test-Path $p) {
        $exe = Get-ChildItem -Path $p -Filter "python.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($exe) { $PY_CMD = $exe.FullName; break }
    }
}
if (-not $PY_CMD) {
    $realPy = Get-Command "python.exe" -All -ErrorAction SilentlyContinue | Where-Object { $_.Source -notlike "*WindowsApps*" } | Select-Object -First 1
    if ($realPy) { $PY_CMD = $realPy.Source }
}
if (-not $PY_CMD) {
    Write-Host "[!] Python nao localizado no sistema."
    Write-Host "[*] Tentando instalacao automatica via WinGet..."
    winget install Python.Python.3.12 --silent --override "/quiet InstallAllUsers=1 PrependPath=1 Include_test=0"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[!] WinGet falhou. Iniciando Download Direto..."
        Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.12.2/python-3.12.2-amd64.exe' -OutFile 'python_installer.exe'
        if (Test-Path "python_installer.exe") {
            Start-Process -FilePath "python_installer.exe" -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1" -Wait
            Remove-Item "python_installer.exe"
        } else {
            Write-Host "[!] ERRO: Instale o Python 3.12 manualmente e marque 'Add to PATH'."
            Read-Host "Pressione Enter para sair"
            exit
        }
    }
    Write-Host "`n==================================================="
    Write-Host "[OK] PYTHON INSTALADO! REINICIE O SETUP."
    Write-Host "==================================================="
    Read-Host "Pressione Enter"
    exit
}
Write-Host "[OK] Motor Python localizado: $PY_CMD"
$baseDir = Get-Location
$venvDir = Join-Path $baseDir "venv"
$python_venv = Join-Path $venvDir "Scripts\python.exe"
$pip_venv = Join-Path $venvDir "Scripts\pip.exe"
if (-not (Test-Path $venvDir)) {
    Write-Host "[*] Criando ambiente de contencao (VENV)..."
    Start-Process -FilePath $PY_CMD -ArgumentList "-m venv venv" -Wait -WindowStyle Hidden
}
if (Test-Path $python_venv) {
    Write-Host "[*] Instalando dependencias pendentes..."
    & $python_venv -m pip install --upgrade pip --quiet
    & $python_venv -m pip install vosk pyttsx3 keyboard sounddevice scipy psutil llama-cpp-python --extra-index-url https://abetlen.github.io/llama-cpp-python/whl/cpu --quiet
    Write-Host "[OK] Bibliotecas sincronizadas."
}
if (-not (Test-Path "engine")) { New-Item -ItemType Directory -Path "engine" | Out-Null }
Write-Host "[*] Sincronizando Base de Dados..."
$files = @(
    @{uri='https://raw.githubusercontent.com/lp77-dev/void-assistant-v1/main/engine.void'; out='engine.void'},
    @{uri='https://raw.githubusercontent.com/lp77-dev/void-assistant-v1/main/engine/main.py'; out='engine/main.py'},
    @{uri='https://raw.githubusercontent.com/lp77-dev/void-assistant-v1/main/engine/identity.void'; out='engine/identity.void'},
    @{uri='https://raw.githubusercontent.com/lp77-dev/void-assistant-v1/main/engine/commands.void'; out='engine/commands.void'}
)
foreach ($f in $files) {
    try { Invoke-WebRequest -Uri $f.uri -OutFile $f.out -ErrorAction Stop } catch { Write-Host "[!] Falha ao baixar: $($f.out)" }
}
if (-not (Test-Path "engine\void.brain")) {
    Write-Host "`n==================================================="
    Write-Host "                SELECAO DE NUCLEO"
    Write-Host "==================================================="
    Write-Host "[1] Void-1-1B [2] Void-1-2B [3] Void-1-3B"
    Write-Host "==================================================="
    $choice = Read-Host "INPUT SELECTION"
    if ($choice -eq "1") { $TGT = "1B" } elseif ($choice -eq "2") { $TGT = "2B" } else { $TGT = "3B" }
    if (Test-Path "engine.void") {
        $RAW_URL = & $python_venv -c "import json,base64; d=json.load(open('engine.void')); v=d['$TGT'][::-1]; print(base64.b64decode(v).decode('utf-8'))"
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
if (-not (Test-Path "Iniciar_Void.bat")) {
    $launcher = "@echo off`r`nchcp 65001 >nul`r`ntitle VOID ASSISTANT - TERMINAL`r`ncolor 0c`r`ncall venv\Scripts\activate`r`npython engine\main.py"
    Set-Content -Path "Iniciar_Void.bat" -Value $launcher
}
Write-Host "`n==================================================="
Write-Host "[OK] SISTEMA PRONTO PARA OPERACAO."
Write-Host "==================================================="
Read-Host "Pressione Enter para fechar"
