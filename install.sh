#!/bin/sh

# Main entry point.
main() {
	if [ "$1" = "--uninstall" ]; then
		set -x
		uninstall
		exit 0
	fi

	set -x
	install
}


#
# 1. Changes config directory password.
# 2. Changes database domain to dc=povilasb,dc=com.
# 3. Creates entries for sample unix users.
#
install() {
	admin_password="admin"

	apt-get install slapd

	sed -i "/olcRootPW/d" \
		/etc/ldap/slapd.d/cn\=config/olcDatabase\=\{0\}config.ldif
	echo "olcRootPW: ${admin_password}" \
		>> /etc/ldap/slapd.d/cn\=config/olcDatabase\=\{0\}config.ldif

	sed -i "/olcRootPW/d" \
		/etc/ldap/slapd.d/cn\=config/olcDatabase\=\{1\}hdb.ldif
	echo "olcRootPW: ${admin_password}" \
		>> /etc/ldap/slapd.d/cn\=config/olcDatabase\=\{1\}hdb.ldif

	service slapd restart
	ldapadd -x -D "cn=admin,cn=config" -w ${admin_password} \
		-f data/change_domain.ldif
	ldapadd -x -D "cn=admin,dc=povilasb,dc=com" -w ${admin_password} \
		-f data/setup_unix_users.ldif
	ldapadd -x -D "cn=admin,cn=config" -w ${admin_password} \
		-f data/change_log_level.ldif
}


uninstall() {
	apt-get purge slapd
}


# Execute main entry point.
main "$@"
