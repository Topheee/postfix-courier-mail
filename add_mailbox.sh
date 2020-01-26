#!/bin/sh

if [ -z "$1" ]; then
	echo "ERROR: please specify a mailbox address"
	exit 1
fi

MAILADDRESS="$1@$MAIL_DOMAIN"

VMAPS_FILE="$(echo $PF_VIRTUAL_MAILBOX_MAPS | cut -d: -f2)"

if [ $(cat "$VMAPS_FILE" | grep -c "^$MAILADDRESS") -gt 0 ]; then
	echo "INFO: skipping $MAILADDRESS, because they are already created"
	exit 0
fi

echo "adding $MAILADDRESS"

BOX=$1
if [ ! -z "$2" ]; then
	echo "INFO: using box $2"
	BOX=$2
fi

# the '/' at the end is important - it means, that this mailbox is in maildir format, as courier expects it!
SUBPATH="$MAILDIR_PATH/default/$BOX/"

mkdir -p "/home/vmail/$SUBPATH"
chown "$VMAIL_UID:$VMAIL_GID" "/home/vmail/$SUBPATH"
echo "$MAILADDRESS $SUBPATH" >> "$VMAPS_FILE"

postmap "$VMAPS_FILE"
