#!/bin/bash
# OpenLDAP Installation Script
# Date: 16th of June, 2014
# Version 1.0
#
# Author: John McCarthy
# Email: midactsmystery@gmail.com
# <http://www.midactstech.blogspot.com> <https://www.github.com/Midacts>
#
# To God only wise, be glory through Jesus Christ forever. Amen.
# Romans 16:27, I Corinthians 15:1-4
#---------------------------------------------------------------
######## VARIABLES ########
version=2.4.39
prefix=/usr/local/etc/openldap
dbdirectory=/usr/local/var/openldap-data/
function install_openldap(){
	# Install prerequisite software
		echo
		echo -e '\e[01;34m+++ Installing the prerequisite software...\e[0m'
		apt-get update
		apt-get -y install build-essential libsasl2-2 libsasl2-dev libssl-dev libltdl-dev openssl
		echo -e '\e[01;37;42mThe prerequisite software has been successfully installed!\e[0m'

	# Create your OpenLDAP user and group
		echo
		echo -e '\e[01;34m+++ Creating the openldap user and group...\e[0m'
		groupadd openldap
		useradd -c "OpenLDAP User" -s /bin/false -g openldap openldap
		echo -e '\e[01;37;42mThe openldap user and group has been successfully created!\e[0m'

	# Download the latest OpenLDAP Files
		echo
		echo -e '\e[01;34m+++ Downloading the latest OpenLDAP software...\e[0m'
		cd
		wget ftp://ftp.openldap.org/pub/OpenLDAP/openldap-release/openldap-$version.tgz

	# Untar the openldap file
		tar xzf openldap-$version.tgz

	# Change to the openldap directory
		cd openldap-$version/
		echo -e '\e[01;37;42mThe latest OpenLDAP software has been successfully downloaded!\e[0m'

	# Install OpenLDAP
		echo
		echo -e '\e[01;34m+++ Installing OpenLDAP...\e[0m'
		./configure --disable-bdb  --disable-hdb --enable-debug=yes --enable-dynacl --enable-mdb --enable-modules --enable-monitor  --enable-overlays --enable-rewrite --enable-rlookups --enable-slapd  --enable-spasswd  --enable-syslog --with-cyrus-sasl --with-threads --with-tls=openssl
		make depend
		make
		make install
		echo -e '\e[01;37;42mOpenLDAP has been successfully installed!\e[0m'
}
function setup_slapd.d(){
	# Change to Openldap director
		echo
		echo -e '\e[01;34m+++ Creating the slapd.d directory...\e[0m'
		cd $prefix

	# Create the slapd.d directory
		mkdir -p slapd.d

	# Create the admin password
		echo -e '\e[33mPlease type in the password you wish your admin user to use\e[0m'
		read pass
		passwd=$(slappasswd -s "$pass")

	# Creates the slapd.conf file
		cat << EOB > $prefix/slapd.conf
#######################################################################
# Config database definitions
#######################################################################
pidfile         /usr/local/var/run/slapd.pid
argsfile        /usr/local/var/run/slapd.args
database        config
rootdn          cn=admin,cn=config
rootpw          $passwd

# Schemas
include         /usr/local/etc/openldap/schema/core.schema
include         /usr/local/etc/openldap/schema/collective.schema
include         /usr/local/etc/openldap/schema/corba.schema
include         /usr/local/etc/openldap/schema/cosine.schema
include         /usr/local/etc/openldap/schema/duaconf.schema
include         /usr/local/etc/openldap/schema/dyngroup.schema
include         /usr/local/etc/openldap/schema/inetorgperson.schema
include         /usr/local/etc/openldap/schema/java.schema
include         /usr/local/etc/openldap/schema/misc.schema
include         /usr/local/etc/openldap/schema/nis.schema
include         /usr/local/etc/openldap/schema/openldap.schema
include         /usr/local/etc/openldap/schema/pmi.schema
include         /usr/local/etc/openldap/schema/ppolicy.schema
EOB

	# Creates the OpenLDAP database
		slaptest -f $prefix/slapd.conf -F $prefix/slapd.d

	# Sets permissions
		chown openldap:openldap -R $prefix
		chmod 770 -R $prefix

		 mkdir -p $dbdirectory
		chown openldap:openldap -R $dbdirectory
		chmod 770 -R $dbdirectory

		chown openldap:openldap -R /usr/local/var/run/
		chmod 770 -R /usr/local/var/run/
		echo -e '\e[01;37;42mThe slapd.d directory has been successfully created!\e[0m'
}
function setup_ldap(){
	# Checks if the $suffix variable is set
		echo
		echo -e '\e[01;34m+++ Editing the ldap.conf file...\e[0m'
		if [[ -z "$suffix" ]]; then
			echo -e '\e[33mWhat is the root suffix of the domain you would like to create ?\e[0m'
			echo
			echo -e '\e[31m        Please put a space beteen each word in the suffix\e[0m'
			echo
			echo -e '\e[33;01mFor Example:  "example com"  for dc=example,dc=com\e[0m'
			read -ra suffix
		fi

	# Reads the ldap server's listening IP or FQDN
		ipaddr=`hostname -I`
		ipaddr=$(echo "$ipaddr" | tr -d ' ')
		fqdn=`hostname -f`
		echo
		echo -e '\e[33mWould you like your OpenLDAP server to listen using its IP address or FQDN ?\e[0m'
		echo -e '\e[33;01mFor Example:  Type "\e[33;01;4mip\e[0m\e[33;01m" to use its IP address\e[0m'
		echo -e '\e[33;01mor\e[0m'
		echo -e '\e[33;01mFor Example:  Type "\e[33;01;4mfqdn\e[0m\e[33;01m" to use its FQDN\e[0m'

	# Read user's input for the listen variable
		read listen

	# If the user types "ip", the uri variable is set to the $ipaddr variable
		if [ "$listen" = "ip" ]; then
			uri=$ipaddr

	# If the user types "fqdn", the uri variable is set to the $fqdn variable
		elif [ "$listen" = "fqdn" ]; then
			uri=$fqdn

	# If the user types in anything other than "ip" or "fqdn", this will recall the check_listen function
		elif [ "$yesno" != "ip" ] && [ "$yesno" != "fqdn" ]; then
			clear
			setup_ldap
			return 0
		fi

	# Edits the ldap.conf file
		sed -i "s/#BASE/BASE/g" $prefix/ldap.conf
		sed -i "s/dc=example,dc=com/dc=${suffix[0]},dc=${suffix[1]}/g" $prefix/ldap.conf
		sed -i "s/#URI/URI/g" $prefix/ldap.conf
		sed -i "s@ldap://ldap.example.com ldap://ldap-master.example.com:666@ldap://$uri@g" $prefix/ldap.conf
		echo -e '\e[01;37;42mThe ldap.conf file has been successfully edited!\e[0m'
}
function setup_mdb(){
	# Checks if the $suffix variable is set
		echo
		echo -e '\e[01;34m+++ Creating the MDB Database...\e[0m'
		if [[ -z "$suffix" ]]; then
			echo -e '\e[33mWhat is the root suffix of the domain you would like to create ?\e[0m'
			echo
			echo -e '\e[31m        Please put a space beteen each word in the suffix\e[0m'
			echo -e '\e[33;01m       For Example:  "example com"  for dc=example,dc=com\e[0m'
			read -ra suffix
		fi

	# Creates the ldif directory
		mkdir -p ldif

	# Creates DIT ldif file
		cat << EOC > $prefix/ldif/directory.ldif
#######################################################################
# MDB database definitions
#######################################################################
#
dn: olcDatabase=mdb,cn=config
changetype: add
objectClass: olcDatabaseConfig
objectClass: olcMdbConfig
olcDatabase: mdb
olcSuffix: dc=john,dc=com
olcRootDN: cn=admin,dc=${suffix[0]},dc=${suffix[1]}
olcRootPW: $passwd
olcDbDirectory: $dbdirectory
olcDbIndex: objectClass eq
olcAccess: to attrs=userPassword by dn="cn=admin,dc=${suffix[0]},dc=${suffix[1]}" write
  by anonymous auth
  by self write by * none
olcAccess: to attrs=shadowLastChange by self write
  by * read
olcAccess: to dn.base="" by * read
olcAccess: to * by dn="cn=admin,dc=${suffix[0]},dc=${suffix[1]}" write
  by * read
olcDbMaxReaders: 0
olcDbMode: 0600
olcDbSearchStack: 16
olcDbMaxSize: 4294967296
olcAddContentAcl: FALSE
olcLastMod: TRUE
olcMaxDerefDepth: 15
olcReadOnly: FALSE
olcSyncUseSubentry: FALSE
olcMonitoring: TRUE
olcDbNoSync: FALSE
olcDbEnvFlags: writemap
olcDbEnvFlags: nometasync
EOC

	# Starts the slapd daemon
		echo
		echo -e '\e[01;34m+++ Starting the slapd daemon...\e[0m'
		echo
		/usr/local/libexec/slapd -u openldap -g openldap -F $prefix/slapd.d -h ldap:///
		echo -e '\e[01;37;42mThe slapd daemon has been successfully started!\e[0m'

	# Adds the DIT to your openldap database
		sleep 2
		echo
		ldapadd -D cn=admin,cn=config -w "$pass" -f $prefix/ldif/directory.ldif
		echo -e '\e[01;37;42mThe MDB database has been successfully created!\e[0m'
}
function setup_structure(){
	# Checks if the $suffix variable is set
		echo
		echo -e '\e[01;34m+++ Creating the DIT structure of your domain...\e[0m'
		if [[ -z "$suffix" ]]; then
			echo -e '\e[33mWhat is the root suffix of the domain you would like to create ?\e[0m'
			echo
			echo -e '\e[31m        Please put a space beteen each word in the suffix\e[0m'
			echo -e '\e[33;01m       For Example:  "example com"  for dc=example,dc=com\e[0m'
			read -ra suffix
		fi

	# Gets the description of your domain
		echo
		echo -e '\e[33mWhat would you like to use as the description of your domain ?\e[0m'
		echo -e "\e[33;01mFor Example:  Midacts' Domain\e[0m"
		read desc

	# Create the structure.ldif file
		cat << EOD > $prefix/ldif/structure.ldif
# Organization for ${suffix[0]^} Domain
dn: dc=${suffix[0]},dc=${suffix[1]}
objectClass: top
objectClass: dcObject
objectclass: organization
o: ${suffix[0]^} Domain
dc: ${suffix[0]}
description: $desc


# Organizational Role for Domain Admin
dn: cn=admin,dc=${suffix[0]},dc=${suffix[1]}
objectClass: organizationalRole
cn: admin
description: Domain Admin
EOD

	# Adds the structure.ldif file to the database
		echo
		ldapadd -H ldap://localhost -D cn=admin,dc=${suffix[0]},dc=${suffix[1]} -w "$pass" -f $prefix/ldif/structure.ldif
		echo -e '\e[01;37;42mThe DIT structure of your domain has been successfully created!\e[0m'
}
function setup_frontend(){
	# Creates the frontend.ldif file
		echo
		echo -e '\e[01;34m+++ Creating the Frontend Database...\e[0m'
		cat << EOE > $prefix/ldif/frontend.ldif
dn: olcDatabase={-1}frontend,cn=config
changetype: modify
replace: olcAccess
olcAccess: to dn.base="" by * read
olcAccess: to dn.base="cn=Subschema" by * read
olcAccess: to * by self write by users read by anonymous auth
EOE

	# Adds the frontend.ldif file to the database
		echo
		ldapmodify -D cn=admin,cn=config -w "$pass" -f $prefix/ldif/frontend.ldif
		echo -e '\e[01;37;42mThe frontend database has been successfully created!\e[0m'
}
function setup_monitor(){
	# Checks if the $suffix variable is set
		echo
		echo -e '\e[01;34m+++ Creting the DIT structure of your domain...\e[0m'
		if [[ -z "$suffix" ]]; then
			echo -e '\e[33mWhat is the root suffix of the domain you would like to create ?\e[0m'
			echo
			echo -e '\e[31m        Please put a space beteen each word in the suffix\e[0m'
			echo -e '\e[33;01m       For Example:  "example com"  for dc=example,dc=com\e[0m'
			read -ra suffix
		fi

	# Creates the monitor.ldif file
		echo
		echo -e '\e[01;34m+++ Creating the Monitor Database...\e[0m'
		cat << EOF > $prefix/ldif/monitor.ldif
dn: olcDatabase={3}Monitor,cn=config
objectClass: olcDatabaseConfig
objectClass: olcMonitorConfig
olcDatabase: {3}Monitor
olcAccess: {0}to * by dn="cn=admin,${suffix[0]},dc=${suffix[1]}" read
EOF

	# Adds the monitor.ldif file to the database
		ldapadd -x -D cn=admin,cn=config -w "$pass" -f $prefix/ldif/monitor.ldif
		echo -e '\e[01;37;42mThe monitor database has been successfully created!\e[0m'

}
function setup_access(){
	# Creates the access.ldif file
		echo
		echo -e '\e[01;34m+++ Creating the Access Database...\e[0m'
		cat << EOG > $prefix/ldif/access.ldif
dn: olcDatabase={2}mdb,cn=config
objectClass: olcDatabaseConfig
objectClass: olcMdbConfig
olcDatabase: {2}mdb
olcDbDirectory: $dbdirectory
olcSuffix: cn=log
olcDbIndex: reqStart eq
olcDbMaxSize: 1073741824
olcDbMode: 0600
olcAccess: {1}to * by dn="cn=admin,dc=${suffix[0]},dc=${suffix[1]}" read

dn: olcOverlay={1}accesslog,olcDatabase={3}mdb,cn=config
objectClass: olcOverlayConfig
objectClass: olcAccessLogConfig
olcOverlay: {1}accesslog
olcAccessLogDB: cn=log
olcAccessLogOps: all
olcAccessLogPurge: 7+00:00 1+00:00
olcAccessLogSuccess: TRUE
olcAccessLogOld: (objectclass=idnsRecord)
EOG

	# Creates the access directory
		mkdir -p $dbdirectory/access

	# Adds access.ldif to the database
	# http://serverfault.com/questions/272125/how-do-i-install-a-new-schema-for-openldap-on-debian-5-with-dynamic-config-cn-ba
		#ldapmodify -x -H ldap://localhost -f $prefix/ldif/access.ldif -D cn=admin,cn=config -w "$pass"
		ldapadd -x -D cn=admin,cn=config -w "$pass" -f ldif/access.ldif
		echo -e '\e[01;37;42mThe access database has been successfully created!\e[0m'

	# Creates the audit.ldif file
		echo
		echo -e '\e[01;34m+++ Creating the Audit Log Database...\e[0m'
		cat << EOH > $prefix/ldif/audit.ldif
dn: olcOverlay={0}auditlog,olcDatabase={0}config,cn=config
objectClass: olcOverlayConfig
objectClass: olcAuditlogConfig
olcOverlay: {0}auditlog
olcAuditlogFile: $dbdirectory/access/auditlog-config.ldif

dn: olcOverlay={0}auditlog,olcDatabase={1}mdb,cn=config
objectClass: olcOverlayConfig
objectClass: olcAuditlogConfig
olcOverlay: {0}auditlog
olcAuditlogFile: $dbdirectory/access/auditlog-mdb.ldif
EOH


	# Adds the audit.ldif to the database
		echo
		ldapadd -x -D cn=admin,cn=config -w "$pass" -f ldif/audit.ldif
		echo -e '\e[01;37;42mThe audit log database has been successfully created!\e[0m'
}
function setup_tls(){
	# Create the ssl directory to house your ssl certificates
		echo
		echo -e '\e[01;34m+++ Setting up StartTLS...\e[0m'
		mkdir -p $prefix/ssl/

	# Change to your ssl directory
		cd $prefix/ssl/

	# Creates the CA certificate and key
		echo
		echo -e '\e[01;34m+++ Creating your CA certificate and key...\e[0m'
		openssl genrsa -out ca.key 2048
		openssl req -new -x509 -days 3650 -key ca.key -out ca.crt
		echo -e '\e[01;37;42mThe ca certificate and key have been successfully created!\e[0m'

	# Creates the openldap cert and key
		echo
		echo -e '\e[01;34m+++ Creating your openldap certificate and key...\e[0m'
		openssl genrsa -out openldap.key 2048
		openssl req -new -key openldap.key -out openldap.csr
		echo -e '\e[01;37;42mThe openldap certificate and key have been successfully created!\e[0m'

	# Signs the openldap csr
		echo
		echo -e '\e[01;34m+++ Signing your openldap certificate...\e[0m'
		openssl x509 -req -in openldap.csr -out openldap.crt -CA ca.crt -CAkey ca.key -CAcreateserial -days 365
		echo -e '\e[01;37;42mThe openldap certificate has been successfully signed!\e[0m'

	# Set permissions on the the openldap and ssl directories
		echo
		echo -e '\e[01;34m+++ Adding your SSL certificates to your cn=config configuration...\e[0m'
		echo
		chown openldap:openldap -R $prefix
		chmod 770 -R $prefix

	# Creates the cert.ldif file
		cat << EOI > $prefix/ldif/cert.ldif
dn: cn=config
add: olcTLSCACertificateFile
olcTLSCACertificateFile: $prefix/ssl/ca.crt
-
add: olcTLSCertificateFile
olcTLSCertificateFile: $prefix/ssl/openldap.crt
-
add: olcTLSCertificateKeyFile
olcTLSCertificateKeyFile: $prefix/ssl/openldap.key
EOI

	# Adds the cert.ldif file to the database
		ldapmodify -x -H ldap://localhost -f $prefix/ldif/cert.ldif -D cn=admin,cn=config -w "$pass"
		echo -e '\e[01;37;42mThe openldap certificates have been successfully added to your cn=config!\e[0m'

	# Copies your ca.crt to the ca-certificates directory so it can be trusted by your server
		echo
		echo -e '\e[01;34m+++ Adding your new CA certificate to your list of trusted CAs...\e[0m'
		cp $prefix/ssl/ca.crt /usr/local/share/ca-certificates
		update-ca-certificates
		echo -e '\e[01;37;42mThe openldap CA has been successfully added to your list of trusted CAs!\e[0m'

		echo
		echo -e '\e[01;34m+++ Adding your OpenLDAP certificates to your ldap.conf file...\e[0m'
		cat << EOJ >> $prefix/ldap.conf

TLS_REQCERT             allow
TLSCertificateFile      $prefix/ssl/openldap.crt
TLSCertificateKeyFile   $prefix/ssl/openldap.key
TLSCACertificateFile    $prefix/ssl/ca.crt
EOJ
		echo -e '\e[01;37;42mStartTLS has been successfully setup!\e[0m'
}
function setup_sec(){
	# Creates the sec.ldif file
		echo
		echo -e '\e[01;34m+++ Forcing StartTLS and requiring authentication and binding...\e[0m'
		cat << EOK > $prefix/ldif/security.ldif
dn: cn=config
changetype: modify
add: olcRequires
olcRequires: bind
-
add: olcDisallows
olcDisallows: bind_anon
-
add: olcSecurity
olcSecurity: tls=1
EOK

	# Adds the security.ldif
		echo
		ldapadd -D cn=admin,cn=config -w "$pass" -f $prefix/ldif/security.ldif
		echo -e '\e[01;37;42mSecurity on your OpenLDAP server has been successfully tightened!\e[0m'
}
function cron_slapd(){
	# Creates the slapd.sh script
		echo
		echo -e '\e[01;34m+++ Creating the slapd.sh script...\e[0m'
		cat <<'EOL'> $prefix/slapd.sh
#!/bin/bash
# Slapd Daemon Init Script
# Date: 16th of June, 2014
# Version 1.0
#
# Author: John McCarthy
# Email: midactsmystery@gmail.com
# <http://www.midactstech.blogspot.com> <https://www.github.com/Midacts>
#
# To God only wise, be glory through Jesus Christ forever. Amen.
# Romans 16:27, I Corinthians 15:1-4
#---------------------------------------------------------------
######## VARIABLES ########
prefix=/usr/local/etc/openldap
daemon=$( ps -A | grep -E '(^|\s)slapd($|\s)' )

# Starts slapd if it is not running
        if [ -z "$daemon" ]; then
                /usr/local/libexec/slapd -u openldap -g openldap -F $prefix/slapd.d -h ldap:///
        else
                exit 0
        fi
EOL

	# Makes the slapd.sh script executable
		chmod +x $prefix/slapd.sh
		echo
		echo -e '\e[1;37;42mThe slapd.sh script has been successfully created!\e[0m'

	# Creates a cron job to automatically start the slapd daemon
		echo
		echo -e '\e[01;34m+++ Editing the Crontab file...\e[0m'
		echo '# Script to make sure the slapd daemon is running' >> /var/spool/cron/crontabs/root
		echo '0,15 * * * * /usr/local/etc/openldap/slapd.sh' >> /var/spool/cron/crontabs/root
		echo
		echo -e '\e[1;37;42mThe Crontab file has been successfully edited!\e[0m'
}
function doAll(){
	# Calls Function 'install_openldap'
		echo
		echo
		echo -e "\e[33m=== Install OpenLDAP ? (y/n)\e[0m"
		read yesno
		if [ "$yesno" = "y" ]; then
			install_openldap
		fi

	# Calls Function 'setup_slapd.d'
		echo
		echo -e "\e[33m=== Setup slapd.d ? (y/n)\e[0m"
		read yesno
		if [ "$yesno" = "y" ]; then
			setup_slapd.d
		fi

	# Calls Function 'setup_ldap'
		echo
		echo -e "\e[33m=== Setup ldap.conf ? (y/n)\e[0m"
		read yesno
		if [ "$yesno" = "y" ]; then
			setup_ldap
		fi

	# Calls Function 'setup_mdb'
		echo
		echo -e "\e[33m=== Setup the MDB Database ? (y/n)\e[0m"
		read yesno
		if [ "$yesno" = "y" ]; then
			setup_mdb
		fi

	# Calls Function 'setup_structure'
		echo
		echo -e "\e[33m=== Setup the DIT Structure of your Domain ? (y/n)\e[0m"
		read yesno
		if [ "$yesno" = "y" ]; then
			setup_structure
		fi

	# Calls Function 'setup_frontend'
		echo
		echo -e "\e[33m=== Setup the Frontend Database ? (y/n)\e[0m"
		read yesno
		if [ "$yesno" = "y" ]; then
			setup_frontend
		fi

	# Calls Function 'setup_access'
		echo
		echo -e "\e[33m=== Setup the Access and Audit log Databases ? (y/n)\e[0m"
		read yesno
		if [ "$yesno" = "y" ]; then
			setup_access
		fi

	# Calls Function 'setup_tls'
		echo
		echo -e "\e[33m=== Setup StartTLS ? (y/n)\e[0m"
		read yesno
		if [ "$yesno" = "y" ]; then
			setup_tls
		fi

	# Calls Function 'setup_sec'
		echo
		echo -e "\e[33m=== Tighten up Security on your OpenLDAP Server ? (y/n)\e[0m"
		read yesno
		if [ "$yesno" = "y" ]; then
			setup_sec
		fi

	# Calls Function 'cron_slapd'
		echo
		echo -e "\e[33m=== Add a cron job to start the slapd daemon ? (y/n)\e[0m"
		read yesno
		if [ "$yesno" = "y" ]; then
			cron_slapd
		fi

	# End of Script Congratulations, Farewell and Additional Information
		clear
		farewell=$(cat << EOZ


          \e[01;37;42mWell done! You have successfully setup your OpenLDAP server! \e[0m



  \e[30;01mCheckout similar material at midactstech.blogspot.com and github.com/Midacts\e[0m

                            \e[01;37m########################\e[0m
                            \e[01;37m#\e[0m \e[31mI Corinthians 15:1-4\e[0m \e[01;37m#\e[0m
                            \e[01;37m########################\e[0m
EOZ
)

		#Calls the End of Script variable
		echo -e "$farewell"
		echo
		echo
		exit 0
}

# Check privileges
	[ $(whoami) == "root" ] || die "You need to run this script as root."

# Welcome to the script
	clear
	welcome=$(cat << EOA


           \e[01;37;42mWelcome to Midacts Mystery's OpenLDAP Installation Script!\e[0m


EOA
)

# Calls the welcome variable
	echo -e "$welcome"

# Calls the doAll function
	case "$go" in
		* )
			doAll ;;
	esac

exit 0
