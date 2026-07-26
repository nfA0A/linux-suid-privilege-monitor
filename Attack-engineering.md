# ⚠️ Relatório Técnico: Engenharia de Ataque e Elevação de Privilégios via SUID

Este documento detalha os fundamentos teóricos e a mecânica de exploração utilizada para simular ataques de elevação de privilégios (*Privilege Escalation*) no Linux, servindo de base para a construção das regras do **Linux SUID Privilege Monitor**.

---

## 📌 O que é o Bit SUID e Por Que Ele Existe?

No Linux, a regra geral do sistema de arquivos é simples: **qualquer programa é executado com as permissões do usuário que o chamou**. Se um usuário comum executa um comando, esse processo roda estritamente com os privilégios limitados desse usuário.

O **SUID (Set Owner User ID up on execution)** é uma permissão especial aplicada a arquivos executáveis. Quando um binário possui o bit SUID ativo (representado pela letra `s` nas permissões do arquivo, ex: `-rwsr-xr-x`), o Kernel altera essa regra fundamental:

> **A Regra do SUID:** O binário não roda com os privilégios de quem o executou, mas sim com os privilégios do **dono do arquivo** (que frequentemente é o usuário `root`).

### Por que isso é necessário no sistema?
Existem utilitários legítimos que usuários comuns precisam utilizar no dia a dia, mas que exigem alterar arquivos críticos e protegidos do sistema operacional. 

O caso mais clássico é o comando `/usr/bin/passwd`:
1. Um usuário comum precisa conseguir alterar sua própria senha.
2. As senhas criptografadas ficam armazenadas no arquivo `/etc/shadow`, ao qual apenas o `root` possui permissão de escrita.
3. Para resolver esse dilema sem conceder acesso total de administrador ao usuário, o binário `/usr/bin/passwd` possui o bit SUID habilitado. Ao ser executado, ele eleva temporariamente os privilégios do processo para `root` **exclusivamente** durante o processo de troca de senha.

### O Risco de Segurança (O Vetor de Ataque)
Se um atacante conseguir aplicar o bit SUID em um binário genérico (ou se um administrador configurar acidentalmente o SUID em utilitários flexíveis como `find`, `awk`, `python` ou `bash`), esse arquivo se torna uma **porta de entrada imediata para a persistência ou elevação de privilégios**.

---

## ⚙️ Mecânica de Exploração no Kernel

### 1. O Isolamento de Processos (A Regra do Kernel)
O Kernel do Linux trabalha com processos isolados na memória.

Se você executar o binário `/usr/bin/backdoor_teste` (com SUID ativo para `root`), o Kernel criará um processo na memória (por exemplo, com o PID 4520) e concederá a esse processo específico os privilégios de `root` (UID 0).

Se você abrir outro terminal na mesma máquina e executar qualquer outro comando normal (como o `ls`), esse novo comando continuará rodando com as limitações do seu usuário comum. Ele **não ganha** privilégios de `root` automaticamente só porque o `backdoor_teste` está em execução em outra janela.

> **Conclusão técnica:** O privilégio de `root` fica contido/preso exclusivamente dentro do contexto do binário com SUID ativo enquanto ele estiver rodando.

---

### 2. A Ponte para Dominar o Sistema (Herança de Processos)
A grande questão da engenharia de ataque é: **o que o binário executado como root consegue fazer com o restante do sistema?**

Se o atacante configurou o SUID em um binário que permite executar subcomandos ou abrir arquivos (como `find`, `awk`, `vim` ou um script customizado), ele utilizará essa capacidade para gerar um novo **processo-filho**.

No Linux, existe uma regra de ouro no gerenciamento de processos:
> **Regra de Ouro:** Todo processo-filho herda as permissões e os privilégios do seu processo-pai.

---

### 🔄 Fluxo Completo de Execução do Ataque

[ Usuário Comum ]
│
▼ (Executa binário com SUID)
[ Processo-Pai: /usr/bin/find ] (Roda como ROOT devido ao SUID)
│
▼ (Executa: find . -exec /bin/sh -p ;)
[ Processo-Filho: /bin/sh ] ──► (Herda privilégios do Pai: Posição de ROOT Irrestrito #)


1. **Ação Inicial:** O usuário comum executa o binário vulnerável.
   * **Processo-Pai:** `/usr/bin/find` (Roda como **ROOT** devido ao SUID).
2. **Injeção de Comando:** Através dos parâmetros nativos do utilitário, o atacante solicita a abertura de um terminal:
   ```bash
   find . -exec /bin/sh -p \;
Criação do Shell: O find cria um novo processo (processo-filho) para carregar o shell /bin/sh.

Herança do Privilégio: Como o processo-pai (find) era root, o processo-filho (sh) é instanciado como root autêntico.

🎯 Resultado
O atacante obtém um prompt interativo (#) onde qualquer comando subseqüente rodará com acesso irrestrito, assumindo o controle total do sistema operacional a partir dessa "ponte" criada pelo bit SUID.
