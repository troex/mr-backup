#!/bin/sh

# mr-backup.sh
# homepage:  https://github.com/troex/mr-backup
# author:    Troex Nevelin <troex@fury.scancode.ru>

BROOT="" # backup root directory

# usage help
case $1 in
""|-h|--help)
	echo "Usage: mr-backup.sh [HOST]"
	echo "Backup unix server using rsync+ssh, more info https://github.com/troex/mr-backup"
	exit 0
	;;
esac

# include global config
GCONF="${0}.conf"
if [ -f ${GCONF} ]
then
	. ${GCONF}
else
	echo "Error: global config ${GCONF} not found"
	exit 1
fi

# default options, do not change them here, use global/host config
POOL="${BROOT}/pool/"        # pool where current snapshots will be located
ARCHIVE="${BROOT}/archive/"  # backup history will go here
CONF="${BROOT}/conf.d/"      # config directory
HOST="$1"                    # hostname to backup
SSH="ssh"                    # ssh and it's options, eg. "ssh -p 2022"
REMOTE="root@${HOST}"        # remote source host and user for rsync
RBPATHS=""                   # space separated paths on remote server which will be backuped
OPTS="--archive --compress --delete-after --delete-excluded --stats --verbose --numeric-ids" # default rsync opts
DATE=`date +%Y-%m-%d`        # used in archive path
EXIT_ON_ERROR="yes"          # whatever to terminate script if we got an error from rsync

# include global config once more to overwrite default values if any
. ${GCONF}

if [ -z "$BROOT" ]
then
	echo "Error: backup root directory is not set"
	exit 1
fi

if [ ! -d $BROOT ]
then
	echo "Error: backup root directory ${BROOT} does not exist"
	exit 1
fi

if [ -z "$HOST" ]
then
	echo "Error: no host specified for backup"
	exit 1
fi

# include host config
LCONF="${CONF}${HOST}.conf"
if [ -f ${LCONF} ]
then
	. ${LCONF}
else
	echo "Error: host config ${LCONF} not found"
	exit 1
fi

if [ -z "$RBPATHS" ]
then
	echo "Error: remote backup paths are not set"
	exit 1
fi

# add exclude lists
EXCLUDE="${CONF}${HOST}.exclude"
if [ -f "${EXCLUDE}" ]
then
	OPTS="$OPTS --exclude-from=${EXCLUDE}"
fi

if [ `whoami` != "root" ];
then
	echo "Warning: this script must be run as 'root' to save file owners"
	#exit 1
fi

for RBP in $RBPATHS
do
	[ -n $RBP ] || continue
	FROM="${REMOTE}:${RBP}/"

	TO="${POOL}${HOST}${RBP}/"
	if [ ! -d $TO ]
	then
		mkdir -p $TO
	fi

	# backup old data if ARCHIVE is set
	if [ -n "${ARCHIVE}" ]
	then
		BBPATH="${ARCHIVE}${HOST}/${DATE}${RBP}"
		if [ ! -d ${BBPATH} ]
		then
			mkdir -p ${BBPATH}
		fi
		BPOPTS="--backup --backup-dir=${BBPATH}"
	fi

	echo "Started ${HOST} backup at `date`"
	echo \# rsync ${OPTS} ${BPOPTS} -e \"${SSH}\" ${FROM} ${TO}

	rsync ${OPTS} ${BPOPTS} -e "${SSH}" ${FROM} ${TO}
	RET=$?

	echo "Finished ${HOST} backup at `date`"
	echo

	if [ ${RET} -gt 0 ]
	then
		if [ ${EXIT_ON_ERROR} == "yes" ]
		then
			echo "Exit due to error code from rsync: ${RET}"
			exit ${RET}
		fi
	fi
done

exit 0
