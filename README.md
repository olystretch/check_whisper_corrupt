check_whisper_corrupt
=====================

Bash script to find or remove corrupt whisper files - For use with Graphite

Usage: ./check_whisper_corrupt.sh options

OPTIONS:
-h   Show this message
-x   enable debug mode
-d   Path of directory to check. Defaults to: /opt/graphite/storage/whisper
-m   Max depth of directory recursion. Defaults to unlimited
-n   Nagios monitor. Suppresses output intended for user, and uses Nagios exit statuses and messages

Choose only ONE of the following file handling options:

-b   Create backups of files before deleting (CAREFUL!!! this can fill your disk FAST)
-r   Don't create backups, just remove the file
-c   Check and list files, don't delete (Default)

Example:
./check_whisper_corrupt.sh -d /opt/graphite/storage/whisper/foo/bar -m 4
