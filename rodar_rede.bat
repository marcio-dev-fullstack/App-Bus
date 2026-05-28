@echo off
:: Busca o IP IPv4 filtrando por termos universais estáveis
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /i "IPv4"') do (
    set temp_ip=%%a
    goto :sucesso
)

:sucesso
set local_ip=%temp_ip: =%

echo =======================================================
echo IP Detectado com Sucesso: %local_ip%
echo Iniciando BusEscolar na Rede Local...
echo =======================================================

flutter run -d chrome --web-hostname=%local_ip% --web-port=8080