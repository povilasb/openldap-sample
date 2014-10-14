=====
About
=====

This is a basic sample of `OpenLDAP` server installation and setup with
TLS/SSL support. Initially LDAP is propogated with Unix user directory used
for LDAP authentification. All tests were run on Debian 7.

To install and setup `LDAP` server invoke `./install.sh` script with root
privileges. It also has `--uninstall` option.

To check if `LDAP` was setup properly invoke `ldapsearch -x -D
"cn=admin,dc=povilasb,dc=com" -w admin` - this command should print Unix users
stored in `LDAP` directory.
