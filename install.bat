@echo off
REM Duplo-clique aqui (ou rode no cmd) para instalar tudo.
REM Ignora a politica de execucao so nesta chamada.
where pwsh >nul 2>nul
if %errorlevel%==0 (
    pwsh -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install.ps1" %*
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install.ps1" %*
)
echo.
pause
