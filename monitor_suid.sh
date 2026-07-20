#!/bin/bash

DIRETORIO_AUDITORIA="/usr/bin"
BASE_CONFIAVEL="suid_baseline.txt"
FOTO_ATUAL="suid_atual.txt"
ARQUIVO_LOG="auditoria_privilegios.log"

echo "=== MONITOR DE PRIVILÉGIOS SUID ATIVADO ==="
echo "Mapeando binários legítimos em ${DIRETORIO_AUDITORIA}..."
echo "------------------------------------------------------------------"

if [ ! -f "${BASE_CONFIAVEL}" ]; then
        find "${DIRETORIO_AUDITORIA}" -perm -4000 2>/dev/null | sort > "${BASE_CONFIAVEL}"
        echo "Baseline de confiança criada com sucesso!"
fi

while true; do
        find "${DIRETORIO_AUDITORIA}" -perm -4000 2>/dev/null | sort > "${FOTO_ATUAL}"

        NOVOS_SUID=$(diff "${BASE_CONFIAVEL}" "${FOTO_ATUAL}" | grep "^>")

        if [ -n "${NOVOS_SUID}" ]; then
                DATA_HORA=$(date "+%Y-%m-%d %H:%M:%S")

                BINARIO_MALICIOSO=$(echo "${NOVOS_SUID}" | awk '{print $2}')

                echo "ALERTA CRÍTICO: Novo binário SUID detetado: ${BINARIO_MALICIOSO}"

                echo "[${DATA_HORA}] VIOLAÇÃO DE PRIVILÉGIO DETETADA!" >> "${ARQUIVO_LOG}"
                echo "Ficheiro modificado/criado: ${BINARIO_MALICIOSO}" >> "${ARQUIVO_LOG}"
                echo "Este binário agora pode rodar como ROOT por qualquer utilizador!" >> "${ARQUIVO_LOG}"
                echo "--------------------------------------------------" >> "${ARQUIVO_LOG}"

                cat "${FOTO_ATUAL}" > "${BASE_CONFIAVEL}"
        else
                echo "Status: [ SEGURO ] Nenhuma alteração de privilégio em ${DIRETORIO_AUDITORIA}."
        fi

        rm -f "${FOTO_ATUAL}"

        sleep 5
done
