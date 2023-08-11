#!/bin/bash

ilog() {
	echo "[INF] " "$@" 1>&2
}
wlog() {
	echo "[WRN] " "$@" 1>&2
}
elog() {
	echo "[ERR] " "$@" 1>&2
}

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
	if [ -n "$PF_MYDOMAIN" ]; then
		ilog "MAIL_DOMAIN is not set, using PF_MYDOMAIN ('$PF_MYDOMAIN')"
		export MAIL_DOMAIN="$PF_MYDOMAIN"
	else
		wlog "please set the MAIL_DOMAIN environment variable to your FQDN. using 'localhost'"
		export MAIL_DOMAIN=localhost
	fi
fi

chmod -R 600 /etc/courier/userdb

# now this is absolutely crazy: postfix checks the number of hard links on a file. But since Docker seems to internally use these, we must limit the amount of changes we make to the fs.
if ! grep -q "$MAIL_DOMAIN" /etc/mailname; then echo "$MAIL_DOMAIN" > /etc/mailname; fi
echo "$MAIL_DOMAIN" > /etc/postfix/vhosts
# create default account
/usr/local/bin/add_mailbox.sh postmaster
echo "changeme" | /usr/local/bin/add_user.sh postmaster

ilog "configuring courier imap"
for VAR in $(env | grep '^CO_' | tr '[:upper:]' '[:lower:]'); do
	CONFVAR=$(echo "$VAR" | cut -d= -f1 | cut -c 4-)
	CONFVAL=$(echo "$VAR" | cut -d= -f2)
	echo "configuring $CONFVAR = $CONFVAL"
	sed -i "s/^$CONFVAR=.*$/$CONFVAR=$CONFVAL/" /etc/courier/imapd-ssl
done

ilog "configuring postfix smtp"
for VAR in $(env | grep '^PF_' | tr '[:upper:]' '[:lower:]'); do
	CONFVAR=$(echo "$VAR" | cut -d= -f1 | cut -c 4- | tr '[:upper:]' '[:lower:]')
	CONFVAL=$(echo "$VAR" | cut -d= -f2)
	echo "configuring $CONFVAR = $CONFVAL"
	postconf -e "$CONFVAR = $CONFVAL"
done

if [ ! -f /etc/postfix/dh1024.pem ] || [ ! -f /etc/postfix/dh512.pem ]; then
	openssl dhparam -out /etc/postfix/dh1024.pem 1024
        openssl dhparam -out /etc/postfix/dh512.pem 512
fi

CERTFILE="$(postconf smtp_tls_cert_file | cut -d ' ' -f3)"
KEYFILE="$(postconf smtp_tls_key_file | cut -d ' ' -f3)"
DHFILE='/etc/postfix/dh512.pem'
IMAPCERTFILE='/etc/courier/imapd.pem' # default from /etc/courier/imapd-ssl
if [ -n "$CERTFILE" ]; then
	ilog "building courier certificate file based on $CERTFILE, $KEYFILE and $DHFILE"
	cat "$CERTFILE" "$KEYFILE" "$DHFILE" > $IMAPCERTFILE
fi

# clear PID files
rm -f /var/spool/postfix/var/run/saslauthd/saslauthd.pid /var/run/courier/imapd.pid /var/run/courier/imapd-ssl.pid /var/spool/postfix/pid/master.pid

postfix reload

/usr/sbin/rsyslogd -f/etc/rsyslog.conf
sleep 1
/etc/init.d/saslauthd start
/etc/init.d/postfix start
/etc/init.d/courier-authdaemon start
# we need plain IMAP such that saslauthd's 'rimap' mechanism can use it for authentication checks
/etc/init.d/courier-imap start
/etc/init.d/courier-imap-ssl start

wait_and_get_socket() {
	sock_file="$1"
	timeout="$2"

	if [ -z "$timeout" ]; then timeout=5; fi

	i=0
	while [ ! -e "${sock_file}" ] && [ "$i" -lt "$timeout" ]; do
		i="$(expr "$i" '+' 1)"
		sleep 1
	done

	if [ "$i" -eq "$timeout" ]; then
		elog "waiting for socket file ${sock_file} timed out."
		exit 1
	fi

	cat "${sock_file}"
}

SASL_PID=$(wait_and_get_socket /var/spool/postfix/var/run/saslauthd/saslauthd.pid)
IMAPD_PID=$(wait_and_get_socket /var/run/courier/imapd.pid)
IMAPD_SSL_PID=$(wait_and_get_socket /var/run/courier/imapd-ssl.pid)
POSTFIX_PID=$(wait_and_get_socket /var/spool/postfix/pid/master.pid | tr -d ' ')

ilog "running and waiting for pids saslauthd: $SASL_PID, imapd: $IMAPD_PID, imapd_ssl: $IMAPD_SSL_PID, postfix: $POSTFIX_PID to exit..."

# we cannot simply `wait` here, as it is not our child process...
tail "--pid=$SASL_PID" -f /var/log/auth.log &
SASL_TAIL_PID="$!"
# no idea what /var/log/btmp is, but there is no explicit logfile for imapd and imapd_ssl
tail "--pid=$IMAPD_PID" -f /var/log/btmp &
IMAPD_TAIL_PID="$!"
tail "--pid=$IMAPD_SSL_PID" -f /var/log/syslog &
IMAPD_SSL_TAIL_PID="$!"
tail "--pid=$POSTFIX_PID" -f /var/log/mail.log &
POSTFIX_TAIL_PID="$!"

wait -n -p EXITED_PID "$SASL_TAIL_PID" "$IMAPD_TAIL_PID" "$IMAPD_SSL_TAIL_PID" "$POSTFIX_TAIL_PID"

ilog "pid $EXITED_PID exited. Bye-bye!"
