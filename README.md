# Postfix / Courier SMTP and IMAP Image

Email server in Docker based on Postfix and Courier.

This image provides an email server, serving IMAPS and SMTP(S) endpoints. SSL configuration is **mandatory**.

Authentication is handled by Courier's [userdb](http://www.courier-mta.org/authlib/README_authlib.html#authuserdb). Postfix refers to users configured in Courier via the `rimap` option.

## Configuration

You must provide an environment variable `MAIL_DOMAIN` containing your domain name, e. g. `example.org`.

All postfix configuration parameters of `main.cf` (see [Postfix Configuration Parameters](http://www.postfix.org/postconf.5.html)) may be provided via environment variables prefixed by `PF_`, e.g. for `2bounce_notice_recipient` provide `PF_2BOUNCE_NOTICE_RECIPIENT=example.org`.

Similarily, Courier's configuration (stored in `/etc/courier/imapd-ssl`) can be altered through `CO_`-prefixed environment variables.

On startup, an account named *postmaster* with password *changeme* is created. On first startup, you **must** change it:
```shell
docker exec -it mycontainer bash
$ userdbpw -md5 | userdb default/postmaster set systempw
```

## Persistent Data (Volumes)

Emails are stored in *Maildir* format below `/home/vmail`. Users are stored below `/etc/courier/userdb/`. You probably want to add volumes for these two folders.

## Basic Setup

Here is a sample compose file using Let's Encrypt certificates from your host:

```yaml
version: '2'

services:
  mail:
    image: postfix-courier-mail:0.1
    environment:
    - MAIL_DOMAIN=example.org
    - PF_MYDOMAIN=example.org
    - PF_MYHOSTNAME=example.org
    - PF_SMTP_TLS_CERT_FILE=/etc/letsencrypt/live/example.org/fullchain.pem
    - PF_SMTP_TLS_KEY_FILE=/etc/letsencrypt/live/example.org/privkey.pem
    - PF_SMTPD_TLS_CERT_FILE=/etc/letsencrypt/live/example.org/fullchain.pem
    - PF_SMTPD_TLS_KEY_FILE=/etc/letsencrypt/live/example.org/privkey.pem
    volumes:
    - "maildir:/home/vmail"
    - "userdb:/etc/courier/userdb/"
    - "/etc/letsencrypt/:/etc/letsencrypt/:ro"

    ports:
      # imaps
      - 993:993/tcp
      # smtp
      - 25:25/tcp

volumes:
  maildir:
  userdb:

```
## Notes

This project is licensed under the terms of the MIT license.
