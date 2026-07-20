# Linux SUID Privilege Monitor (linux-suid-privilege-monitor)

Este repositório contém uma ferramenta de automação defensiva desenvolvida em Bash Script voltada para a auditoria contínua e monitoramento em tempo real do sistema de arquivos Linux. O objetivo principal do projeto é mitigar vetores de ataque associados a desvios de baseline e persistências silenciosas via SUID.

---

## 🛠️ 1. Documentação da Ferramenta

### 1.1 O que o Script faz?
O script `monitor_suid.sh` atua como um fiscal de segurança local (FIM - File Integrity Monitoring). Ele opera coletando periodicamente todos os binários do sistema que possuem o bit especial **SUID** ativo e comparando esse estado atual com uma baseline segura previamente validada.

### 1.2 Mecânica de Detecção (Por baixo do capô)
A lógica de análise e filtragem do script é baseada em três etapas fundamentais:
1. **Varredura Ativa:** Utiliza o comando `find / -perm -4000` para caçar arquivos SUID.
2. **Análise de Diferencial:** Utiliza o utilitário `diff` para comparar a varredura atual com a baseline estável.
3. **Análise de String com Regex:** Aplica a expressão regular `^>` para filtrar o output do `diff`, isolando de forma cirúrgica apenas as linhas que representam novos binários perigosos que foram adicionados ou modificados no sistema, eliminando falsos positivos.

### 1.3 Estrutura do Repositório
```text
linux-suid-privilege-monitor/
├── monitor_suid.sh         # Código-fonte limpo e automatizado da ferramenta
└── README.md               # Relatório Técnico de Engenharia de Segurança
