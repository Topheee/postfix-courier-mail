#!/bin/sh

# signal handler for graceful shutdown of the container
nice_exit() {
	/etc/init.d/courier-imap stop
	/etc/init.d/courier-imap-ssl stop
	/etc/init.d/courier-authdaemon stop
	/etc/init.d/postfix stop
	/etc/init.d/saslauthd stop
}

trap nice_exit INT TERM

# we require an environment variable MAIL_DOMAIN to be present
if [ -z "$MAIL_DOMAIN" ]; then
	if [ ! -z "$PF_MYDOMAIN" ]; then
		echo "INFO: MAIL_DOMAIN is not set, using PF_MYDOMAIN ('$PF_MYDOMAIN')"
		export MAIL_DOMAIN="$PF_MYDOMAIN"
	else
		echo "WARN: please set the MAIL_DOMAIN environment variable to your FQDN. using 'localhost'"
		export MAIL_DOMAIN=localhost
	fi
fi

chmod -R 600 /etc/courier/userdb

echo "$MAIL_DOMAIN" > /etc/mailname
echo "$MAIL_DOMAIN" > /etc/postfix/vhosts
# create default account
/usr/local/bin/add_mailbox.sh postmaster
echo "changeme" | /usr/local/bin/add_user.sh postmaster

echo "INFO: configuring courier imap"
for VAR in $(env | grep '^CO_' | tr '[:upper:]' '[:lower:]'); do
	CONFVAR=$(echo "$VAR" | cut -d= -f1 | cut -c 4-)
	CONFVAL=$(echo "$VAR" | cut -d= -f2)
	echo "configuring $CONFVAR = $CONFVAL"
	sed -i "s/^$CONFVAR=.*$/$CONFVAR=$CONFVAL/" /etc/courier/imapd-ssl
done

echo "INFO: configuring postfix smtp"
for VAR in $(env | grep '^PF_' | tr '[:upper:]' '[:lower:]'); do
	CONFVAR=$(echo "$VAR" | cut -d= -f1 | cut -c 4- | tr '[:upper:]' '[:lower:]')
	CONFVAL=$(echo "$VAR" | cut -d= -f2)
	echo "configuring $CONFVAR = $CONFVAL"
	postconf -e "$CONFVAR = $CONFVAL"
done

if [ ! -f /etc/postfix/dh1024.pem -o ! -f /etc/postfix/dh512.pem ]; then
	openssl dhparam -out /etc/postfix/dh1024.pem 1024
        openssl dhparam -out /etc/postfix/dh512.pem 512
fi

CERTFILE="$(postconf smtp_tls_cert_file | cut -d ' ' -f3)"
KEYFILE="$(postconf smtp_tls_key_file | cut -d ' ' -f3)"
DHFILE='/etc/postfix/dh512.pem'
IMAPCERTFILE='/etc/courier/imapd.pem' # default from /etc/courier/imapd-ssl
if [ ! -z "$CERTFILE" ]; then
	echo "INFO: building courier certificate file based on $CERTFILE, $KEYFILE and $DHFILE"
	cat "$CERTFILE" "$KEYFILE" "$DHFILE" > $IMAPCERTFILE
fi

postfix reload

/etc/init.d/rsyslog start
sleep 1
/etc/init.d/saslauthd start
/etc/init.d/postfix start
/etc/init.d/courier-authdaemon start
# we need plain IMAP such that saslauthd's 'rimap' mechanism can use it for authentication checks
/etc/init.d/courier-imap start
/etc/init.d/courier-imap-ssl start

SASL_PID=$(cat /var/spool/postfix/var/run/saslauthd/saslauthd.pid)
#while [ ! -e "/var/spool/postfix/pid/master.pid" ]; do sleep 1; done
#POSTFIX_PID=$(cat /var/spool/postfix/pid/master.pid | tr -d ' ')

#tail -f /var/log/syslog
#while [ ! -e "/var/log/mail.log" ]; do sleep 1; done
#tail -f /var/log/auth.log /var/log/mail.log /var/log/mail.err &

echo "INFO: running and waiting for pid $SASL_PID to exit..."
# we cannot simply `wait` here, as it is not our child process...
#wait "$SASL_PID"
tail --pid=$SASL_PID -f /var/log/syslog &
#tail --pid=$SASL_PID -f /dev/null &
wait $!

echo "INFO: pid $SASL_PID exited. Bye-bye!"

