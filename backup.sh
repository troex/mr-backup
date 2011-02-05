#!/bin/sh

# backup script
# author Troex Nevelin <troex@fury.scancode.ru>

BROOT="/mnt/backup/"
POOL="${BROOT}pool/"
ARCHIVE="${BROOT}archive/"
CONF="${BROOT}conf/"

if [ `whoami` != "root" ];
then
	echo "Error: this script must be run as 'root'"
	exit 1
fi

if [ -z $1 ]
then
	echo "Error: no host specified"
	exit 1
fi

HOST="$1"
DATE=`date +%Y-%m-%d`

BPATH="${POOL}${HOST}/"
if [ ! -d ${BPATH} ]
then
	echo "No previous backup found, starting new one ${BPATH}"
	mkdir -p ${BPATH}
fi

BBPATH="${ARCHIVE}${HOST}/${DATE}/"
if [ ! -d ${BBPATH} ]
then
	mkdir -p ${BBPATH}
fi

# default config
SSH="ssh -p 22"
REMOTE="root@${HOST}:/"
OPTS="--archive --backup --compress --delete-after --delete-excluded --stats --verbose --numeric-ids"

# include local config if exists
LCONF="${CONF}${HOST}.conf"
if [ -f ${LCONF} ]
then
	. ${LCONF}
fi

# add backup dir
OPTS="${OPTS} --backup-dir=${BBPATH}"

# add exclude lists
EXCLUDE="${CONF}${HOST}.exclude"
if [ -f "${EXCLUDE}" ]
then
	OPTS="$OPTS --exclude-from=${EXCLUDE}"
fi


echo "Started ${HOST} backup at `date`"

echo \# rsync ${OPTS} -e \"${SSH}\" ${REMOTE} ${LOCAL} ${BPATH}

rsync ${OPTS} -e "${SSH}" ${REMOTE} ${LOCAL} ${BPATH}

echo "Finished ${HOST} backup at `date`"
echo

exit 0
