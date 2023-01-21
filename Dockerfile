FROM ubuntu:22.04

# SMTP and IMAPS
EXPOSE 25 993

# *** SMTP ***

ENV MAILDIR_PATH=mail

# Python3 is a recommendation of postfix (see apt-cache show postfix)
# rsyslog is required to receive logs
# the SASL packages are for authentication
# apt-utils is necessary for the installation in Docker
# ca-certificates installs the common internet certificate authorities necessary for TLS
RUN echo postfix postfix/main_mailer_type string "'Internet Site'" | debconf-set-selections && \
	echo postfix postfix/mynetworks string "127.0.0.0/8" | debconf-set-selections && \
	echo postfix postfix/mailname string localhost.localdomain | debconf-set-selections && \
	echo postfix postfix/destinations string $myhostname, localdomain, localhost, localhost.localdomain, localhost | debconf-set-selections && \
	apt-get update && apt-get -y install apt-utils ca-certificates rsyslog python3 libsasl2-2 sasl2-bin libsasl2-modules postfix && \
	apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* ~/.cache ~/.npm

RUN postconf -e 'home_mailbox = emails/' && \
	postconf -e 'smtpd_sasl_auth_enable = yes' && \
	postconf -e 'smtpd_sasl_security_options = noanonymous' && \
	postconf -e 'smtpd_recipient_restrictions = permit_sasl_authenticated,permit_mynetworks,reject_unauth_destination' && \
	postconf -e 'inet_interfaces = all' && \
	postconf -e 'inet_protocols = ipv4' && \
# standard rather restrictive configuration parameters
	postconf -e 'append_dot_mydomain = no' && \
	postconf -e 'authorized_verp_clients =' && \
	postconf -e 'backwards_bounce_logfile_compatibility = no' && \
	postconf -e 'biff = no' && \
	postconf -e 'broken_sasl_auth_clients = no' && \
	postconf -e 'default_destination_concurrency_limit = 10' && \
	postconf -e 'default_destination_rate_delay = 1s' && \
	postconf -e 'default_extra_recipient_limit = 100' && \
	postconf -e 'default_process_limit = 20' && \
	postconf -e 'default_recipient_limit = 100' && \
	postconf -e 'default_transport = smtp' && \
	postconf -e 'default_transport_rate_delay = 3s' && \
	postconf -e 'disable_vrfy_command = yes' && \
	postconf -e 'header_address_token_limit = 1024' && \
	postconf -e 'mail_name = IntergalacticLocalPostOffice' && \
	postconf -e 'mailbox_size_limit = 51200000' && \
	postconf -e 'masquerade_domains = $mydomain' && \
	postconf -e 'message_size_limit = 10240000' && \
	postconf -e 'resolve_null_domain = no' && \
	postconf -e 'resolve_numeric_domain = no' && \
	postconf -e 'show_user_unknown_table_name = no' && \
	postconf -e 'smtp_address_verify_target = rcpt' && \
	postconf -e 'smtp_cname_overrides_servername = no' && \
	postconf -e 'smtp_defer_if_no_mx_address_found = no' && \
	postconf -e 'smtp_dns_support_level = dnssec' && \
	postconf -e 'smtp_enforce_tls = yes' && \
	postconf -e 'smtp_host_lookup = dns' && \
	postconf -e 'smtp_quote_rfc821_envelope = yes' && \
	postconf -e 'smtp_sender_dependent_authentication = yes' && \
	postconf -e 'smtp_starttls_timeout = 30s' && \
	postconf -e 'smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt' && \
	postconf -e 'smtp_tls_block_early_mail_reply = yes' && \
	postconf -e 'smtp_tls_ciphers = high' && \
	postconf -e 'smtp_tls_dane_insecure_mx_policy = dane' && \
	postconf -e 'smtp_tls_enforce_peername = yes' && \
	postconf -e 'smtp_tls_exclude_ciphers = aNULL, MD5, DES' && \
	postconf -e 'smtp_tls_force_insecure_host_tlsa_lookup = no' && \
	postconf -e 'smtp_tls_loglevel = 1' && \
	postconf -e 'smtp_tls_mandatory_ciphers = high' && \
	postconf -e 'smtp_tls_mandatory_protocols = !SSLv2, !SSLv3' && \
	postconf -e 'smtp_tls_protocols = $smtp_tls_mandatory_protocols' && \
	postconf -e 'smtp_tls_scert_verifydepth = 5' && \
	# dane-only would be better, but not all mailservers are dnssec, and dane may falls back to unencrypted...
	postconf -e 'smtp_tls_security_level = secure' && \
	postconf -e 'smtp_use_tls = no' && \
	postconf -e 'smtpd_client_auth_rate_limit = 20' && \
	postconf -e 'smtpd_client_connection_rate_limit = 20' && \
	postconf -e 'smtpd_client_message_rate_limit = 200' && \
	postconf -e 'smtpd_client_new_tls_session_rate_limit = 20' && \
	postconf -e 'smtpd_client_recipient_rate_limit = 1000' && \
	postconf -e 'smtpd_delay_open_until_valid_rcpt = yes' && \
	postconf -e 'smtpd_delay_reject = yes' && \
	postconf -e 'smtpd_enforce_tls = yes' && \
	postconf -e 'smtpd_etrn_restrictions = permit_mynetworks, reject' && \
	postconf -e 'smtpd_helo_required = yes' && \
	postconf -e 'smtpd_helo_restrictions = reject_invalid_helo_hostname, reject_non_fqdn_helo_hostname' && \
	postconf -e 'smtpd_peername_lookup = yes' && \
	postconf -e 'smtpd_recipient_limit = 100' && \
	postconf -e 'smtpd_reject_footer = \c. Go away!' && \
	postconf -e 'smtpd_reject_unlisted_recipient = yes' && \
	# yes would be better
	postconf -e 'smtpd_reject_unlisted_sender = no'&& \
	postconf -e 'smtpd_sasl_auth_enable = yes' && \
	postconf -e 'smtpd_tls_CAfile = $smtp_tls_CAfile' && \
	postconf -e 'smtpd_tls_ask_ccert = no' && \
	postconf -e 'smtpd_tls_auth_only = yes' && \
	postconf -e 'smtpd_tls_ccert_verifydepth = 5' && \
	postconf -e 'smtpd_tls_ciphers = high' && \
	# generate with openssl dhparam -out /etc/postfix/dh1024.pem 1024
	postconf -e 'smtpd_tls_dh1024_param_file = /etc/postfix/dh1024.pem' && \
	# generate with openssl dhparam -out /etc/postfix/dh512.pem 512
	postconf -e 'smtpd_tls_dh512_param_file = /etc/postfix/dh512.pem' && \
	postconf -e 'smtpd_tls_exclude_ciphers = $smtp_tls_exclude_ciphers' && \
	postconf -e 'smtpd_tls_loglevel = 1' && \
	postconf -e 'smtpd_tls_mandatory_ciphers = high' && \
	postconf -e 'smtpd_tls_mandatory_protocols = $smtp_tls_mandatory_protocols' && \
	postconf -e 'smtpd_tls_protocols = $smtp_tls_protocols' && \
	postconf -e 'smtpd_tls_received_header = no' && \
	postconf -e 'smtpd_tls_req_ccert = no' && \
	postconf -e 'smtpd_tls_security_level = encrypt' && \
	postconf -e 'smtpd_tls_wrappermode = no' && \
	postconf -e 'smtpd_use_tls = no' && \
	postconf -e 'smtputf8_enable = yes' && \
	postconf -e 'soft_bounce = no' && \
	postconf -e 'swap_bangpath = no' && \
	postconf -e 'tls_append_default_CA = no' && \
	postconf -e 'tls_dane_digests = sha512 sha256' && \
	postconf -e 'tls_preempt_cipherlist = yes'

# we run in chroot mode (although it is not really necessary, because Docker already does it)
RUN sed -i '/^smtp /d' /etc/postfix/master.cf && \
	echo 'smtp unix - - n - - smtp' >> /etc/postfix/master.cf && \
	echo 'smtp inet n - y - - smtpd' >> /etc/postfix/master.cf

# *** SASL ***
# based on https://wiki.debian.org/PostfixAndSASL

RUN usermod -G sasl postfix && \
	echo 'pwcheck_method: saslauthd' >> /etc/postfix/sasl/smtpd.conf && \
	echo 'mech_list: plain login' >> /etc/postfix/sasl/smtpd.conf && \
	sed '/^#*START=.*/d' /etc/default/saslauthd | \
	sed '/^#*MECHANISMS=.*/d' | \
	sed '/^#*MECH_OPTIONS=.*/d' | \
	sed '/^#*OPTIONS=.*/d' > /etc/default/saslauthd-postfix && \
	echo 'START=yes' >> /etc/default/saslauthd-postfix && \
	echo 'MECHANISMS="rimap"' >> /etc/default/saslauthd-postfix && \
	echo 'MECH_OPTIONS="localhost"' >> /etc/default/saslauthd-postfix && \
	echo 'OPTIONS="-c -m /var/spool/postfix/var/run/saslauthd"' >> /etc/default/saslauthd-postfix

# *** IMAP(S) ***
# see also https://help.ubuntu.com/community/PostfixCompleteVirtualMailSystemHowto

ARG MAIL_USER=vmail

ENV VMAIL_GID=5000 VMAIL_UID=5000 PF_VIRTUAL_MAILBOX_MAPS=hash:/home/$MAIL_USER/vmaps

RUN groupadd -g $VMAIL_GID vmail && useradd -m -u $VMAIL_UID -g $VMAIL_GID -s /bin/bash $MAIL_USER

# setting up virtual mailboxes
# see http://www.postfix.org/VIRTUAL_README.html
RUN postconf -e 'virtual_mailbox_domains = /etc/postfix/vhosts' && \
	postconf -e "virtual_mailbox_base = /home/$MAIL_USER" && \
	postconf -e "virtual_mailbox_maps = $PF_VIRTUAL_MAILBOX_MAPS" && \
	postconf -e "virtual_minimum_uid = $VMAIL_UID" && \
	postconf -e "virtual_uid_maps = static:$VMAIL_UID" && \
	postconf -e "virtual_gid_maps = static:$VMAIL_GID"

RUN echo tzdata tzdata/Areas select "Europe" | debconf-set-selections && \
	echo tzdata tzdata/Zones/Etc select "UTC" | debconf-set-selections && \
	echo tzdata tzdata/Zones/Europe select "Berlin" | debconf-set-selections && \
	echo tzdata tzdata/Areas seen true | debconf-set-selections && \
	echo tzdata tzdata/Zones/Etc seen true | debconf-set-selections && \
	echo tzdata tzdata/Zones/Europe seen true | debconf-set-selections && \
	echo courier-base courier-base/webadmin-configmode select true | debconf-set-selections && \
	echo courier-base courier-base/webadmin-configmode seen true | debconf-set-selections && \
	echo courier-base courier-base/maildirpath select "$MAILDIR_PATH" | debconf-set-selections && \
	echo courier-base courier-base/maildirpath seen true | debconf-set-selections && \
	echo courier-base courier-base/maildir select Maildir | debconf-set-selections && \
	echo courier-base courier-base/maildir seen true | debconf-set-selections && \
# courier-base seems to not respect dpkg excludes in /etc/dpkg/dpkg.cfg.d/excludes
	mkdir -p /usr/share/man/man8/ && \
	touch /usr/share/man/man8/deliverquota.courier.8.gz && touch /usr/share/man/man5/maildir.courier.5.gz && touch /usr/share/man/man7/maildirquota.courier.7.gz && \
	apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata gamin courier-base courier-imap && \
	apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* ~/.cache ~/.npm

# we need to turn off IMAP_TLS_REQUIRED because the `rimap` authentication module of postfix requires plaintext IMAP
RUN mkdir "/mnt/courier-data" && mkdir "/home/$MAIL_USER/$MAILDIR_PATH" && chown "$VMAIL_UID:$VMAIL_GID" "/home/$MAIL_USER/$MAILDIR_PATH" && \
	sed -i "s/^MAILDIRPATH=.*/MAILDIRPATH=$MAILDIR_PATH/" /etc/courier/imapd-ssl && \
	#sed -i 's/^IMAP_TLS_REQUIRED=.*/IMAP_TLS_REQUIRED=1/' /etc/courier/imapd-ssl && \
	sed -i 's/^#*authmodulelist=.*/authmodulelist="authuserdb"/' /etc/courier/authdaemonrc

COPY entry.sh add_mailbox.sh add_user.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/entry.sh"]

