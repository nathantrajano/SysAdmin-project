#!/bin/bash

# =================================================================
# SCRIPT DE BACKUP AUTOMATIZADO: RSYNC + BORGBACKUP
# Integrantes: Diogo, Gabriel, João Victor e Nathan
# =================================================================

# Configuracoes de Diretorios
ORIGEM="/home/$USER/documentos"
DESTINO_TEMP="/home/$USER/backup"
BORG_REPO="/home/$USER/borg-repo"
LOG_FILE="/home/$USER/backup_log.txt"

# Nome do snapshot (Data e Hora)
BACKUP_NAME="backup-$(date +%Y-%m-%d_%H-%M)"

echo "--- Iniciando processo de backup: $(date) ---" | tee -a "$LOG_FILE"

# 1. Sincronizacao com rsync (Espelhamento inicial)
# -a: archive, -v: verbose, --delete: remove no destino o que foi apagado na origem
echo "[1/3] Sincronizando arquivos com rsync..." | tee -a "$LOG_FILE"
rsync -av --delete "$ORIGEM/" "$DESTINO_TEMP/" >> "$LOG_FILE" 2>&1

# 2. Criacao do Snapshot com BorgBackup
# Cria um backup versionado e deduplicado do diretorio sincronizado
echo "[2/3] Criando snapshot no BorgBackup: $BACKUP_NAME" | tee -a "$LOG_FILE"
borg create --stats --progress "$BORG_REPO::$BACKUP_NAME" "$DESTINO_TEMP" >> "$LOG_FILE" 2>&1

if [ $? -eq 0 ]; then
    echo "Snapshot criado com sucesso!" | tee -a "$LOG_FILE"
else
    echo "Erro ao criar snapshot no Borg." | tee -a "$LOG_FILE"
    exit 1
fi

# 3. Politica de Retencao (Pruning)
# Mantem os ultimos 7 diarios, 4 semanais e 6 mensais
echo "[3/3] Aplicando politica de retencao..." | tee -a "$LOG_FILE"
borg prune -v --list --keep-daily=7 --keep-weekly=4 --keep-monthly=6 "$BORG_REPO" >> "$LOG_FILE" 2>&1

echo "--- Backup finalizado: $(date) ---" | tee -a "$LOG_FILE"