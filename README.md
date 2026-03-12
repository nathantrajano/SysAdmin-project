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

## Demo

### 1. Sincronizacao com rsync

O **rsync** e ideal para espelhamento, mas nao mantem historico. Se um dado e apagado na origem, ele e apagado no destino.

```bash
# Instalacao e preparacao do ambiente
sudo apt install rsync
mkdir ~/documentos ~/backup

# Sincronizacao inicial (Criacao do espelho)
echo "teste backup" > ~/documentos/arquivo1.txt
rsync -av --delete ~/documentos/ $USER@localhost:/home/$USER/backup/

# Atualizacao incremental
echo "nova linha" >> ~/documentos/arquivo1.txt
rsync -av --delete ~/documentos/ $USER@localhost:/home/$USER/backup/

# Simulacao de Erro: O espelhamento apaga o backup se a origem sumir
rm ~/documentos/arquivo1.txt
rsync -av --delete ~/documentos/ $USER@localhost:/home/$USER/backup/

```

### 2. Backup Robusto com BorgBackup

Para resolver a falta de historico, o **Borg** cria snapshots versionados e seguros.

```bash
# Instalacao e inicializacao do repositorio (com criptografia)
sudo apt install borgbackup
borg init --encryption=repokey /home/$USER/borg-repo

# Criando um snapshot versionado
borg create /home/$USER/borg-repo::backup-1 /home/$USER/backup

# Simulacao de perda total e restauracao
rm -rf ~/backup/
borg list /home/$USER/borg-repo
borg extract /home/$USER/borg-repo::backup-1
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
