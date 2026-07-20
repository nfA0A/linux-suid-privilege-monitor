#!/bin/bash

# Configurações de Ficheiros
DIRETORIO_AUDITORIA="/usr/bin"
BASE_CONFIAVEL="suid_baseline.txt"
FOTO_ATUAL="suid_atual.txt"
ARQUIVO_LOG="auditoria_privilegios.log"

echo "=== MONITOR DE PRIVILÉGIOS SUID ATIVADO ==="
echo "Mapeando binários legítimos em ${DIRETORIO_AUDITORIA}..."
echo "------------------------------------------------------------------"

# Cria a baseline inicial se ela não existir
if [ ! -f "${BASE_CONFIAVEL}" ]; then
        find "${DIRETORIO_AUDITORIA}" -perm -4000 2>/dev/null | sort > "${BASE_CONFIAVEL}"
        echo "🟢 Baseline de confiança criada com sucesso!"
fi

while true; do
        # 1. Tira uma nova "fotografia" dos binários SUID atuais
        find "${DIRETORIO_AUDITORIA}" -perm -4000 2>/dev/null | sort > "${FOTO_ATUAL}"

        # 2. Compara a foto atual com a baseline usando o diff
        # O grep "^>" filtra apenas as linhas que foram ADICIONADAS na foto atual
        NOVOS_SUID=$(diff "${BASE_CONFIAVEL}" "${FOTO_ATUAL}" | grep "^>")

        # 3. Validação Lógica: Se a variável NÃO estiver vazia (-n), significa que há um invasor
        if [ -n "${NOVOS_SUID}" ]; then
                DATA_HORA=$(date "+%Y-%m-%d %H:%M:%S")

                # Purifica a string para mostrar apenas o caminho do ficheiro
                BINARIO_MALICIOSO=$(echo "${NOVOS_SUID}" | awk '{print $2}')

                echo "🚨 ALERTA CRÍTICO: Novo binário SUID detetado: ${BINARIO_MALICIOSO}"

                # Grava no log forense para auditoria de IT
                echo "[${DATA_HORA}] 🚨 VIOLAÇÃO DE PRIVILÉGIO DETETADA!" >> "${ARQUIVO_LOG}"
                echo "Ficheiro modificado/criado: ${BINARIO_MALICIOSO}" >> "${ARQUIVO_LOG}"
                echo "Este binário agora pode rodar como ROOT por qualquer utilizador!" >> "${ARQUIVO_LOG}"
                echo "--------------------------------------------------" >> "${ARQUIVO_LOG}"

                # Atualiza a baseline para não ficar a apitar o mesmo erro em loop infinito
                cat "${FOTO_ATUAL}" > "${BASE_CONFIAVEL}"
        else
                echo "Status: [ SEGURO ] Nenhuma alteração de privilégio em ${DIRETORIO_AUDITORIA}."
        fi

        # Limpa o ficheiro temporário da foto atual
        rm -f "${FOTO_ATUAL}"

        sleep 5
done
