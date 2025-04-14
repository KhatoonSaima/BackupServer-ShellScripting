# 🗄️ W25 Backup Script

This Bash script (`w25backup.sh`) performs continuous automated backups (full, incremental, differential, and size-based) of specified file types from a given directory tree.

---

## 📦 Features

- **Supports up to 4 file types** (e.g. `.c`, `.txt`, `.pdf`, `.jpg`)
- **Performs 5-step backup cycle** every 120 seconds:
  1. Full backup
  2. Incremental backup (Step 1 ➡️ Step 2)
  3. Incremental backup (Step 2 ➡️ Step 3)
  4. Differential backup (based on Step 1)
  5. Incremental backup of files >100KB (based on Step 1)
- **Maintains a detailed log file** `w25log.txt`
- **Automatically creates backup folders** if not already present
- **Backups exclude the `backup` directory itself**

---

## 📂 Directory Structure

The script expects to back up files from the root directory(can be changed):
```
/Users/<your-username>/Downloads/ASP
```

Backups will be saved in:
```
$HOME/backup/
├── fullbup/       → Full backups
├── incbup/        → Incremental backups
├── diffbup/       → Differential backups
└── incsizebup/    → Incremental backups of large files
```

---

## 🚀 Usage

```bash
./w25backup.sh .c .txt .pdf .jpg
```

You can pass **up to 4 file extensions** as arguments. If **no arguments** are given, **all file types** are included.

✅ Valid examples:
```bash
./w25backup.sh
./w25backup.sh .txt
./w25backup.sh .c .cpp
./w25backup.sh .docx .pptx .pdf .png
```

❌ Invalid usage:
```bash
./w25backup.sh .c .cpp .txt .pdf .jpg    # More than 4 types
```

---

## 📓 Log File

The script writes status logs to:
```
$HOME/backup/w25log.txt
```

Sample log:
```
Mon 14 Apr2025 12:00:00 PM EDT fullbup-1.tar was created
Mon 14 Apr2025 12:02:00 PM EDT incbup-1.tar was created
Mon 14 Apr2025 12:04:00 PM EDT No changes - Incremental backup was not created
...
```

---

## 🛑 Stop the Script

Since the script runs continuously in the background, you can stop it with:

```bash
ps aux | grep w25backup.sh
kill <PID>
```

Or use:
```bash
pkill -f w25backup.sh
```

---

## 🧪 Extracting Backups

To extract any `.tar` file:
```bash
tar -xf fullbup-1.tar
```

---

## 🧾 Notes

- Make sure the script is **executable**:
  ```bash
  chmod +x w25backup.sh
  ```
- Run with Zsh or Bash shell.
- Ensure you have **read permissions** to source files.

---

## 👨‍💻 Author

- Saima Khatoon
