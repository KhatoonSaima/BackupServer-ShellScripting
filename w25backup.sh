#!/bin/bash
# =================================================================================
# Script: w25backup.sh
# Description: A continuous backup script that performs full, incremental,
#              differential, and incremental size backups of specified file types
#              in the user's home directory. Backups are created every 2 minutes
#              and logged in w25log.txt.
#
# Usage: ./w25backup.sh [file_type1] [file_type2] [file_type3] [file_type4]
#        - If no file types are provided, all files are backed up.
#        - Example: ./w25backup.sh .txt .pdf .sh .c
#
# Backup Locations:
# - Full backups: ~/backup/fullbup/
# - Incremental backups: ~/backup/incbup/
# - Differential backups: ~/backup/diffbup/
# - Incremental size backups: ~/backup/incsizebup/
#
# Log File: ~/backup/w25log.txt
# Error File: ~/backup/w25error.txt
#
# Author: Saima Khatoon
# Date: 06-04-2025
# =================================================================================

# Number of command line argument should not exceed 4.
if [ $# -gt 4 ]; then
    echo "Error: Too many arguments. Maximum 4 allowed."
    echo "Usage: ./w25backup.sh [file_type1] [file_type2] [file_type3] [file_type4]"
    exit 1
fi

# Set directories
BACKUP_DIR="$HOME/backup"
FULL_BUP_DIR="$BACKUP_DIR/fullbup"
INC_BUP_DIR="$BACKUP_DIR/incbup"
DIFF_BUP_DIR="$BACKUP_DIR/diffbup"
INC_SIZE_BUP_DIR="$BACKUP_DIR/incsizebup"
LOG_FILE="$BACKUP_DIR/w25log.txt"           # Log file
ERROR_FILE="$BACKUP_DIR/w25error.txt"       # Error file
ROOT_DIR="$HOME"

# Create directories if they do not exist
mkdir -p "$FULL_BUP_DIR" "$INC_BUP_DIR" "$DIFF_BUP_DIR" "$INC_SIZE_BUP_DIR"

# Track backup sequence numbers
FULL_COUNT=1
INC_COUNT=1
DIFF_COUNT=1
INC_SIZE_COUNT=1

# Function to log messages
log_message() {
    echo "$(date '+%a %d %b%Y %I:%M:%S %p %Z') $1" >> "$LOG_FILE"
}

# File type filters
if [ $# -eq 0 ]; then
    FILE_TYPES=("")
else
    FILE_TYPES=("$@")
fi

while true; do

    # Resetting the variable - useful for the next iteration
    FULL_BUP_FILE=""
    INC_BUP_FILE1=""
    INC_BUP_FILE2=""
    DIFF_BUP_FILE=""
    INC_SIZE_BUP_FILE=""

    # Step 1: Full Backup
    # Creates an full backup of all the files specified in command line.
    FULL_BUP_FILE="$FULL_BUP_DIR/fullbup-$FULL_COUNT.tar"
    files_full=$(eval "find \"$ROOT_DIR\" -type f \( $(printf -- "-name '*%s' -o " "${FILE_TYPES[@]}" | sed 's/-o $//') \) ! -path \"$ROOT_DIR/backup/*\"")
    #echo "Full backup done"
    tar -cf "$FULL_BUP_FILE" -C "$ROOT_DIR" $(echo "$files_full" | sed "s|$ROOT_DIR/||g") 2>> "$ERROR_FILE"
    log_message "fullbup-$FULL_COUNT.tar was created"
    FULL_COUNT=$((FULL_COUNT + 1))
    sleep 120


    # Step 2: Incremental Backup 1
    # Creates an incremental backup after the full backup (step1).
    # Find files newer than FULL_BUP_FILE and store the list in a variable
    files_fullbackup=$(eval "find \"$ROOT_DIR\" -type f \( $(printf -- "-name '*%s' -o " "${FILE_TYPES[@]}" | sed 's/-o $//') \) ! -path \"$ROOT_DIR/backup/*\" -newer \"$FULL_BUP_FILE\"")
    # Check if any files were found
    if [ -n "$files_fullbackup" ]; then
        # Create the incremental backup
        INC_BUP_FILE1="$INC_BUP_DIR/incbup-$INC_COUNT.tar"
        tar -cf "$INC_BUP_FILE1" -C "$ROOT_DIR" $(echo "$files_fullbackup" | sed "s|$ROOT_DIR/||g") 2>> "$ERROR_FILE"
        log_message "incbup-$INC_COUNT.tar was created"
        INC_COUNT=$((INC_COUNT + 1))
    else
        log_message "No changes - Incremental backup was not created"
    fi
    #echo "Incremental backup 1 done"
    sleep 120


    # Step 3: Incremental Backup 2
    # Creates an incremental backup after the first incremental backup (step2).
    # Find files newer than INC_BUP_FILE1 and store the list in a variable
    if [ -e "$INC_BUP_FILE1" ]; then
        # Use find to locate files matching the specified types and newer than INC_BUP_FILE1
        files_incbackup=$(eval "find \"$ROOT_DIR\" -type f \( $(printf -- "-name '*%s' -o " "${FILE_TYPES[@]}" | sed 's/-o $//') \) ! -path \"$ROOT_DIR/backup/*\" -newer \"$INC_BUP_FILE1\"")
    else
        # Use find to locate files matching the specified types without the -newer condition
        files_incbackup=$(eval "find \"$ROOT_DIR\" -type f \( $(printf -- "-name '*%s' -o " "${FILE_TYPES[@]}" | sed 's/-o $//') \) ! -path \"$ROOT_DIR/backup/*\" -newer \"$FULL_BUP_FILE\"")
    fi
    # Check if any files were found
    if [ -n "$files_incbackup" ]; then
        INC_BUP_FILE2="$INC_BUP_DIR/incbup-$INC_COUNT.tar"
        tar -cf "$INC_BUP_FILE2" -C "$ROOT_DIR" $(echo "$files_incbackup" | sed "s|$ROOT_DIR/||g")  2>> "$ERROR_FILE"
        log_message "incbup-$INC_COUNT.tar was created"
        INC_COUNT=$((INC_COUNT + 1))
    else
        log_message "No changes - Incremental backup was not created"
    fi
    #echo "Incremental backup 2 done"
    sleep 120


    # Step 4: Differential Backup
    # Creates an differential backup after the full backup (step1).
    # Find files newer than FULL_BUP_FILE and store the list in a variable
    files_diffbackup=$(eval "find \"$ROOT_DIR\" -type f \( $(printf -- "-name '*%s' -o " "${FILE_TYPES[@]}" | sed 's/-o $//') \) ! -path \"$ROOT_DIR/backup/*\" -newer \"$FULL_BUP_FILE\"")
    # Check if any files were found
    if [ -n "$files_diffbackup" ]; then
        # Create the incremental backup
        DIFF_BUP_FILE="$DIFF_BUP_DIR/diffbup-$DIFF_COUNT.tar"
        tar -cf "$DIFF_BUP_FILE" -C "$ROOT_DIR" $(echo "$files_diffbackup" | sed "s|$ROOT_DIR/||g") 2>> "$ERROR_FILE"
        log_message "diffbup-$DIFF_COUNT.tar was created"
        DIFF_COUNT=$((DIFF_COUNT + 1))
    else
         log_message "No changes - Differential backup was not created"
    fi
    #echo "Differential backup done"
    sleep 120


    # Step 5: Incremental Backup for Large Files (>100 KB)
    # Creates an incremental backup after the differential backup (step4).
    if [ -e "$DIFF_BUP_FILE" ]; then
        # Use find to locate files matching the specified types and newer than DIFF_BUP_FILE (step4)
        files_incsizebackup=$(eval "find \"$ROOT_DIR\" -type f \( $(printf -- "-name '*%s' -o " "${FILE_TYPES[@]}" | sed 's/-o $//') \) ! -path \"$ROOT_DIR/backup/*\" -newer \"$DIFF_BUP_FILE\" -size +100k")
    elif [ -e "$INC_BUP_FILE2" ]; then
        # Use find to locate files matching the specified types and newer than INC_BUP_FILE2 (step3)
        files_incsizebackup=$(eval "find \"$ROOT_DIR\" -type f \( $(printf -- "-name '*%s' -o " "${FILE_TYPES[@]}" | sed 's/-o $//') \) ! -path \"$ROOT_DIR/backup/*\" -newer \"$INC_BUP_FILE2\" -size +100k")
    elif [ -e "$INC_BUP_FILE1" ]; then
        # Use find to locate files matching the specified types and newer than INC_BUP_FILE1 (step2)
        files_incsizebackup=$(eval "find \"$ROOT_DIR\" -type f \( $(printf -- "-name '*%s' -o " "${FILE_TYPES[@]}" | sed 's/-o $//') \) ! -path \"$ROOT_DIR/backup/*\" -newer \"$INC_BUP_FILE1\" -size +100k")
    else 
        # Use find to locate files matching the specified types and newer than FULL_BUP_FILE (step1)
        files_incsizebackup=$(eval "find \"$ROOT_DIR\" -type f \( $(printf -- "-name '*%s' -o " "${FILE_TYPES[@]}" | sed 's/-o $//') \) ! -path \"$ROOT_DIR/backup/*\" -newer \"$FULL_BUP_FILE\" -size +100k")
    fi
    # Check if any files were found
    if [ -n "$files_incsizebackup" ]; then
        # Create the incremental size backup
        INC_SIZE_BUP_FILE="$INC_SIZE_BUP_DIR/incsizebup-$INC_SIZE_COUNT.tar"
        tar -cf "$INC_SIZE_BUP_FILE" -C "$ROOT_DIR" $(echo "$files_incsizebackup" | sed "s|$ROOT_DIR/||g") 2>> "$ERROR_FILE"
        log_message "incsizebup-$INC_SIZE_COUNT.tar was created"
        INC_SIZE_COUNT=$((INC_SIZE_COUNT + 1))
    else
        log_message "No changes - Incremental size backup was not created"
    fi
    #echo "Incremental size backup done"
    sleep 120

done &
# & to run this script in background