# Backup e Recuperacao: rsync + BorgBackup

Este repositorio contem o material do seminario sobre solucoes de backup em ambientes Linux. A solucao foca em eficiencia atraves de sincronizacao delta, deduplicacao e seguranca criptografica.

## Integrantes

* **Diogo Alves Silveira**
* **Gabriel Xavier Gomes Maia**
* **João Victor de Souza Lucena**
* **Nathan Amaro Trajano**

---

## Escopo e Visao Geral

Este trabalho abrange desde a analise teorica de riscos ate a implementacao pratica de uma rotina de backup resiliente.

### 1. Diagnostico de Riscos

A apresentacao detalha os desafios enfrentados por administradores de sistemas:

* **Falhas Humanas:** Exclusoes acidentais ou comandos errados em producao.
* **Seguranca:** Ameacas de Ransomware e sequestro de dados.
* **Hardware:** Fim da vida util de dispositivos e corrupcao de dados.

### 2. Stack Tecnologica

Utilizamos duas ferramentas complementares para cobrir as lacunas de um backup simples:

* **rsync:** Transferencia eficiente e sincronizacao de arquivos via SSH.
* **BorgBackup:** Gerenciamento de historico, deduplicacao, compressao e snapshots versionados.

### 3. Demonstracao Pratica (Hands-on)

O ciclo de vida completo do backup demonstrado inclui:

* Configuracao de repositorios criptografados.
* Execucao de backups incrementais e deduplicacao.
* Simulacao de desastre e recuperacao de dados.
* Auditoria e verificacao de integridade.

---

## rsync (Remote Sync)
O rsync é uma ferramenta clássica de administração de sistemas voltada para a sincronização eficiente de arquivos e diretórios.

Sua principal característica é a transferência incremental: em vez de copiar o arquivo inteiro a cada execução, ele identifica e transfere apenas as partes que foram alteradas (deltas), o que otimiza significativamente o uso da rede. Além disso, ele preserva metadados como permissões e links simbólicos, operando nativamente sobre SSH para garantir segurança.

**No entanto**, por ser focado em espelhamento, ele não gerencia um histórico de versões; se um arquivo for deletado na origem, ele será removido no destino.

## BorgBackup (Borg)
O BorgBackup é um sistema moderno de backup que resolve as limitações de versionamento do rsync.

Ele utiliza uma técnica de deduplicação baseada em blocos (chunks), onde arquivos são divididos e apenas blocos únicos são armazenados, gerando uma enorme economia de espaço. Todo o repositório é protegido por criptografia de ponta, transformando os dados no destino em "blocos de lixo criptográfico" ilegíveis sem a chave. Com suporte a snapshots versionados e modo append-only (que impede a exclusão maliciosa de backups antigos por ransomware), o Borg oferece uma camada de segurança e recuperação rápida para ambientes críticos.

---

## Demo

### 1. Sincronizacao com rsync

O **rsync** e ideal para espelhamento, mas nao mantem historico. Se um dado e apagado na origem, ele e apagado no destino.

```bash
# Instalacao e preparacao do ambiente
sudo apt install rsync
# Cria a pasta de origem dos dados e a pasta que servirá de destino para o rsync.
mkdir ~/documentos ~/backup

# Cria um arquivo de texto com conteúdo inicial para testar o backup.
echo "teste backup" > ~/documentos/arquivo1.txt
# Sincroniza a pasta documentos com a pasta backup. A flag -a preserva atributos, -v mostra o progresso e --delete apaga no destino o que não existe mais na origem.
rsync -av --delete ~/documentos/ $USER@localhost:/home/$USER/backup/

# Modifica o arquivo existente para testar a sincronização incremental.
echo "nova linha" >> ~/documentos/arquivo1.txt
# Sincroniza
rsync -av --delete ~/documentos/ $USER@localhost:/home/$USER/backup/

# Simulacao de Erro: O espelhamento apaga o backup se a origem sumir
rm ~/documentos/arquivo1.txt
# Demonstra o risco do rsync puro; ao sincronizar após o erro, o backup também perde o arquivo, pois ele apenas espelha o estado atual.
rsync -av --delete ~/documentos/ $USER@localhost:/home/$USER/backup/

```

### 2. Backup Robusto com BorgBackup

Para resolver a falta de historico, o **Borg** cria snapshots versionados e seguros.

```bash
# Instalacao e inicializacao do repositorio (com criptografia)
sudo apt install borgbackup
# Inicializa um novo repositório de backup. O modo repokey armazena a chave de criptografia dentro do repositório, protegida por uma senha.
borg init --encryption=repokey /home/$USER/borg-repo

# Cria o primeiro snapshot chamado "backup-1" contendo os dados da pasta backup.
borg create /home/$USER/borg-repo::backup-1 /home/$USER/backup

# Simulacao de perda total e restauracao
rm -rf ~/backup/
borg list /home/$USER/borg-repo # Lista todos os snapshots disponíveis no repositório, permitindo escolher qual versão restaurar.
borg extract /home/$USER/borg-repo::backup-1 # Extrai os dados do snapshot "backup-1" de volta para o sistema.
mv home/$USER/backup/ ~/  # Restaura para o local original

```

### 3. Manutencao e Auditoria

```bash
# Estatisticas de compressao e deduplicacao
borg info ~/borg-repo::backup-1

# Verificacao de integridade (Check & Repair)
borg check ~/borg-repo
borg check --repair ~/borg-repo

```

---

## Arquitetura da Solucao

```text
[Servidor Origem] --(rsync/SSH)--> [Servidor Backup] --(Snapshots)--> [Repositorio Borg]

```

## Beneficios Resumidos

* **Economia de Espaco:** Deduplicacao por blocos que armazena dados repetidos apenas uma vez.
* **Seguranca:** Dados armazenados como blocos criptografados no destino.
* **Imutabilidade:** Suporte a modo Append-Only contra delecoes maliciosas.
* **Recuperacao Simples:** Extracao rapida de arquivos ou snapshots especificos.

---

## Como Executar o Script de Backup

Para automatizar o processo e garantir a integridade dos dados sem intervenção manual, siga os passos abaixo:
1. Preparação

Certifique-se de que o arquivo possui permissão de execução:

```Bash

chmod +x backup.sh
```

2. Execução Manual

Você pode rodar o backup a qualquer momento com o comando(Tente executar dentro da pasta do repositorio se tiver duvidas):

```Bash

./backup.sh
```
O script gerará um log detalhado em ~/backup_log.txt, permitindo auditar o sucesso da operação.

---

 # Apresentação (PDF): 
 **https://github.com/nathantrajano/SysAdmin-project/blob/main/slide-1.pdf**

--- 

# 🔗 Referências

Para aprofundamento nas ferramentas utilizadas, consulte as documentações oficiais:

BorgBackup Documentation: https://borgbackup.readthedocs.io

rsync Manual: https://linux.die.net/man/1/rsync
