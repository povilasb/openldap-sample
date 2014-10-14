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
# 4. Enables SSL support.
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

	setup_ssl
}


setup_ssl() {
	ssl_key_dir=/etc/ldap/ssl
	ssl_key_file=${ssl_key_dir}/server.pem

	if [ ! -f ${ssl_key_file} ]; then
		mkdir -p ${ssl_key_dir}
		openssl req -newkey rsa:1024 -x509 -nodes \
			-out ${ssl_key_file} -keyout ${ssl_key_file} -days 3650
	fi

	ldap_unix_user=openldap
	ldap_unix_group=openldap
	chown -R ${ldap_unix_user}:${ldap_unix_group} ${ssl_key_dir}

	modify_slapd_defaults

	ldapadd -x -D "cn=admin,cn=config" -w ${admin_password} \
		-f data/setup_ssl.ldif
	service slapd restart
}


modify_slapd_defaults() {
	slapd_services="ldap\:\/\/\/ ldaps\:\/\/\/ ldapi\:\/\/\/"
	sed -i "s/^SLAPD_SERVICES.*/SLAPD_SERVICES=\"${slapd_services}\"/g" \
		/etc/default/slapd
}


uninstall() {
	apt-get purge slapd
}


# Execute main entry point.
main "$@"
