#!/bin/sh

if [ $# -lt 1 ]; then
	echo "ERROR: you need to specify a name"
	exit 1
fi

NAME="default/$1"

echo "adding user $NAME"

userdb "$NAME" set "uid=$VMAIL_UID" "gid=$VMAIL_GID" "home=/home/vmail/$MAILDIR_PATH/$NAME" "mail=/home/vmail/$MAILDIR_PATH/$NAME"

userdbpw -md5 | userdb "$NAME" set systempw

makeuserdb
