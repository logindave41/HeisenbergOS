# HeisenbergOS

SOBRE O PROJETO E O SEU NOME

Este é um projeto não muito ambicioso de desenvolver um sistema operacional 
próprio, simples, no modo x86-64, pronto para funcionar sob circunstâncias
controladas (sob uma VM no QEMU). O nome HeisenbergOS vem do fato de que há
muita incerteza sobre se esse projeto vai, algum dia, ser completado. Pensei
em nomeá-lo "Quantum OS", mas o nome já existe... :)

SOBRE AS FERRAMENTAS DE TRABALHO

GCC 4.8 ou superior;
LD 2.24 ou superior (binutils  2.24 ou superior);
NASM 2.10 ou superior;

SISTEMA OPERACIONAL HOST

Primariamente o projeto será construído sob Linux, mas nada impede que o
usuário do Windows ou OS/X não o desenvolva... Não deverá haver dependências de
sistema operacional (pathnames, por exemplo, deverão ser todos relativos ao 
diretório raiz do projeto, usando a notação UNIX, que é aceita mesmo no 
Windows).

ESTRUTURA INICIAL DE DIRETÓRIOS DO PROJETO

docs/    - Contém textos sobre o projeto.
src/     - O código fonte, é claro.
scripts/ - Scripts em bash ou python (somente esses dois!) auxiliares

No diretório docs/ teremos, além de linhas diretoras do projeto (decisões
de implementação e avisos sobre "armadilhas", por exemplo), descrições sobre
hardware e como esses devem ser manipulados corretamente... Coisas assim...

Inicialmente o diretório src/ contém apenas dois subdiretórios: boot/ e kernel/,
Onde boot/ contém o código da MBR e o bootstrap. O diretório kernel/ será
preenchido com o código do kernel em modo protegido a medida que for
implementado. Essas estruturas sofrerão alterações à medida que avançarmos.

HIERARQUIA DE DECISÕES SOBRE O PROJETO

EU centralizo as decisões sobre implementação e o que será colocado no projeto.
Isso permite que apenas material relevante seja inserido no projeto...
As contribuições serão creditadas aos respectivos autores...

Mais adiante podemos ter grupos dedicados. Por exemplo, um grupo dedicado às
rotinas de gerenciamento de memória, outro para rotinas de vídeo, outro para
redes e sockets, etc... Neste caso a hierarquia persiste: EU decido o que entra
ou não no projeto, mas os grupos terão que ter seus próprios "chefes" para
fazerm essa filtragem prévia...

CONTROLE DE VERSÂO

Usarei o GIT e o github.com/fredericopissarra/HeisenbergOS. Mas é necessário
que tenhamos uma política bem definida de criação de merge de branches... Isso
será decidifo em discussão...

SO IT BEGINS...

Vamu lá, cambada! Mãos à obra!

