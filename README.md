mr-backup
=========

Simple backup script for unix machines that uses rsync+ssh to synchronize data.
It stores current snapshot of remote files and incremental backup of old files.

Usage
-----

* Installation not required
* Just clone this script to directory where you want to deploy backup
* Rename _mr-backup.sh.conf.example_ to _mr-backup.sh.conf_ and set your backup root directory
* Check _conf.d/example.org.conf_ for sample host config
* Run the script to backup server `./mr-backup.sh example.org`
