1. O Isolamento de Processos (A Regra do Kernel)
O Kernel do Linux trabalha com processos isolados.

Se você rodar o /usr/bin/backdoor_teste (com SUID ativo), o Kernel vai criar um processo na memória (digamos, com o PID 4520) e dará a esse processo específico o poder de root (UID 0).

Se você abrir outro terminal ou executar qualquer outro comando normal (como o ls), esse outro comando continuará rodando com o seu usuário comum (X). Ele não ganha privilégios de root automaticamente só porque o backdoor está rodando em outra janela.

Então, tecnicamente, o privilégio de root está preso dentro daquele binário enquanto ele estiver rodando.

2. A Ponte para Dominar o Sistema Todo
A grande sacada é: o que o binário com privilégio de root consegue fazer com o resto do sistema?

Se o atacante configurou o SUID em um binário que permite executar novos comandos (como o find, awk ou um script em C), ele usará esse binário para gerar um novo processo-filho.

No Linux, existe uma regra de ouro: todo processo-filho herda os privilégios do processo-pai.

Então o fluxo do ataque para dominar o sistema todo é assim:

Você (usuário comum) executa o binário SUID:
Processo-Pai: /usr/bin/find (Roda como ROOT devido ao SUID)

Por dentro dele, você manda ele abrir o shell:
find . -exec /bin/sh -p \;

O find cria um novo processo (processo-filho) para o shell /bin/sh.

Como o processo-pai (find) é root, o processo-filho (sh) nasce como root de verdade.

Agora você está com um prompt de comando (#) onde qualquer comando que você digitar ali dentro rodará como root.

Pronto! O atacante usou a "ponte" do binário SUID para conseguir um shell de root irrestrito, assumindo o controle total do sistema operacional inteiro a partir dali.
