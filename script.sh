#!/usr/bin/env bash

if [ $(id -u) -eq 0 ]; then
	read -p "Enter username : " username
	read -s -p "Enter password : " password
	egrep "^$username" /etc/passwd >/dev/null
	if [ $? -eq 0 ]; then
		echo "$username exists!"
		exit 1
	else
        if [[ -z "$username" ]] || [[ -z "$password" ]]; then
            echo "No username or password set"
        else
            pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
            useradd -m -p "$pass" "$username"
            [ $? -eq 0 ] && echo "User has been added to system!" || echo "Failed to add a user!"
            echo "Adding User to sudoers"
            adduser "$username" sudo
            [ $? -eq 0 ] && echo "User has been added to sudo!" || echo "Failed to add user to sudo"
            echo "Removing password prompt for $username"
            echo -n "$username ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/010_$username-nopasswd"
            [ $? -eq 0 ] && echo "Successfully removed password prompt" || echo "Failed to remove password prompt"
        fi
	fi

    read -p "Enter Static private IP address: (192.168.0.0/24) " ip_address
    if [[ $ip_address =~ ^192\.168\.0\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip_address)
        IFS=$OIFS
        if [[ ${ip[3]} -le 255 ]]; then
            cat <<EOF >> /etc/dhcpcd.conf
interface wlan0
static ip_address=$ip_address
static routers=192.168.0.1
static domain_name_servers=8.8.8.8
EOF
            [ $? -eq 0 ] && echo "IP address set: $ip_address" || echo "Failed to set ip address"
        else
            echo "IP address not set"
        fi
    else
        echo "Invalid IP address "
	fi

else
	echo "Only root may add a user to the system."
	# exit 1
fi
