#!/bin/bash

# Настройки бэкапа
BACKUP_DIR="/backup"
DB_HOST="mariadb"
DB_NAME="booklore"
DB_USER="booklore"
DB_PASS="secure_booklore_password_2025"
RETENTION_DAYS=7

# Создание директории для бэкапов
mkdir -p $BACKUP_DIR

# Функция для логирования
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $BACKUP_DIR/backup.log
}

# Функция создания бэкапа базы данных
backup_database() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$BACKUP_DIR/booklore_db_backup_$timestamp.sql"
    
    log "Начинаем бэкап базы данных..."
    
    if mariadb-dump -h $DB_HOST -u $DB_USER -p$DB_PASS \
        --single-transaction \
        --routines \
        --triggers \
        --events \
        --add-drop-database \
        --databases $DB_NAME > $backup_file; then
        
        # Сжимаем бэкап
        gzip $backup_file
        backup_file="$backup_file.gz"
        
        log "Бэкап базы данных успешно создан: $backup_file"
        log "Размер файла: $(du -h $backup_file | cut -f1)"
        
        return 0
    else
        log "ОШИБКА: Не удалось создать бэкап базы данных"
        return 1
    fi
}

# Функция создания бэкапа файлов книг
backup_books() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$BACKUP_DIR/booklore_books_backup_$timestamp.tar.gz"
    
    log "Начинаем бэкап файлов книг..."
    
    if tar -czf $backup_file -C / books booklore-data 2>/dev/null; then
        log "Бэкап файлов успешно создан: $backup_file"
        log "Размер архива: $(du -h $backup_file | cut -f1)"
        return 0
    else
        log "ОШИБКА: Не удалось создать бэкап файлов"
        return 1
    fi
}

# Функция очистки старых бэкапов
cleanup_old_backups() {
    log "Очистка старых бэкапов (старше $RETENTION_DAYS дней)..."
    
    local deleted_count=0
    
    # Удаляем старые бэкапы базы данных
    while IFS= read -r -d '' file; do
        rm "$file"
        deleted_count=$((deleted_count + 1))
        log "Удален старый бэкап: $(basename "$file")"
    done < <(find $BACKUP_DIR -name "booklore_*_backup_*.sql.gz" -mtime +$RETENTION_DAYS -print0)
    
    # Удаляем старые архивы книг
    while IFS= read -r -d '' file; do
        rm "$file"
        deleted_count=$((deleted_count + 1))
        log "Удален старый архив: $(basename "$file")"
    done < <(find $BACKUP_DIR -name "booklore_*_backup_*.tar.gz" -mtime +$RETENTION_DAYS -print0)
    
    if [ $deleted_count -eq 0 ]; then
        log "Старых бэкапов для удаления не найдено"
    else
        log "Удалено $deleted_count старых бэкапов"
    fi
}

# Функция отправки уведомления (опционально)
send_notification() {
    local status=$1
    local message=$2
    
    # Здесь можно добавить отправку уведомлений:
    # - Email через SMTP
    # - Webhook в Discord/Slack
    # - Telegram бот
    # - и т.д.
    
    log "Уведомление ($status): $message"
}

# Основная функция
main() {
    log "=== Начало процедуры бэкапа BookLore ==="
    
    local db_backup_success=false
    local files_backup_success=false
    
    # Создаем бэкап базы данных
    if backup_database; then
        db_backup_success=true
    fi
    
    # Создаем бэкап файлов
    if backup_books; then
        files_backup_success=true
    fi
    
    # Очищаем старые бэкапы
    cleanup_old_backups
    
    # Статистика использования места
    log "Использование места в директории бэкапов:"
    du -sh $BACKUP_DIR/* 2>/dev/null | while read size file; do
        log "  $size - $(basename "$file")"
    done
    
    # Отправляем уведомления
    if $db_backup_success && $files_backup_success; then
        send_notification "SUCCESS" "Все бэкапы успешно созданы"
        log "=== Бэкап завершен успешно ==="
        exit 0
    elif $db_backup_success || $files_backup_success; then
        send_notification "PARTIAL" "Некоторые бэкапы не удались"
        log "=== Бэкап завершен частично ==="
        exit 1
    else
        send_notification "FAILURE" "Все бэкапы завершились ошибкой"
        log "=== Бэкап завершился с ошибками ==="
        exit 2
    fi
}

# Запуск основной функции
main "$@"