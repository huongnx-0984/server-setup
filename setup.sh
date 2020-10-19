#!/bin/bash
# -------------------------------------------------------------------------
# Nguyen Xuan Huong -  Automated server configuration script
# -------------------------------------------------------------------------
# Website:       https://zhuongnx.github.io
# GitHub:        https://github.com/huongnx-0984/server-setup
# Copyright (c) 2018 nguyen.xuan.huong <xuan.huong.humg@gmail.com>
# This script is licensed under M.I.T
# -------------------------------------------------------------------------
# Currently in progress, not ready to be used in production yet
# -------------------------------------------------------------------------


CSI='\033['
CEND="${CSI}0m"
#CRED="${CSI}1;31m"
CGREEN="${CSI}1;32m"

##################################
# Variables
##################################

EXTPLORER_VER="2.1.10"

##################################
# Check if user is root
##################################

if [ "$(id -u)" != "0" ]; then
    echo "Error: You must be root to run this script, please use the root user to install the software."
    echo ""
    echo "Use 'sudo su - root' to login as root"
    exit 1
fi

### Set Bins Path ###
RM=/bin/rm
CP=/bin/cp
TAR=/bin/tar
GZIP=/bin/gzip

clear

##################################
# Welcome
##################################

echo ""
echo "Welcome to setup script."
echo ""

if [ -d /etc/nginx ]; then
    echo "Nginx install detected"
    NGINX_PREVIOUS_INSTALL=1
fi

if [ -d $HOME/.ssh ]; then
    rsa_keys_check=$(grep "ssh-rsa" -r $HOME/.ssh)
    if [ -z "$rsa_keys_check" ]; then
        echo "This script require to use ssh keys authentification. Please make sure you have properly added your public ssh keys into .ssh/authorized_keys"
        exit 1
    fi
else
        echo "This script require to use ssh keys authentification. Please make sure you have properly added your public ssh keys into .ssh/authorized_keys"
    exit 1
fi

##################################
# Menu
##################################
echo "#####################################"
echo "             Warning                 "
echo "#####################################"
echo "This script will only allow ssh connection with ssh-keys"
echo "Make sure you have properly installed your public key in $HOME/.ssh/authorized_keys"
echo "#####################################"
sleep 1
echo ""
echo "#####################################"
echo "PHP"
echo "#####################################"
if [ ! -f /etc/php/7.1/fpm/php.ini ]; then
    echo "Do you want php7.1-fpm ? (y/n)"
    while [[ $phpfpm71_install != "y" && $phpfpm71_install != "n" ]]; do
        read -p "Select an option [y/n]: " phpfpm71_install
    done
    echo ""
fi
if [ ! -f /etc/php/7.2/fpm/php.ini ]; then
    echo "Do you want php7.2-fpm ? (y/n)"
    while [[ $phpfpm72_install != "y" && $phpfpm72_install != "n" ]]; do
        read -p "Select an option [y/n]: " phpfpm72_install
    done
fi

echo ""
echo "#####################################"
echo "Starting server setup in 5 seconds"
echo "use CTRL + C if you want to cancel installation"
echo "#####################################"
sleep 5

##################################
# Update packages
##################################

echo "##########################################"
echo " Updating Packages"
echo "##########################################"

sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get autoremove -y --purge
sudo apt-get autoclean -y

##################################
# Useful packages
##################################

echo "##########################################"
echo " Installing useful packages"
echo "##########################################"

sudo apt-get install curl git unzip zip tar gzip wget pigz tree mycli -y composer 

sudo apt -y install curl dirmngr apt-transport-https lsb-release ca-certificates
curl -sL https://deb.nodesource.com/setup_10.x | sudo bash
sudo apt-get install nodejs

# increase history size
export HISTSIZE=10000

echo "##########################################"
echo " Checking required executable path"
echo "##########################################"

### Make Sure Bins Exists ###
verify_bins() {
    [ ! -x $GZIP ] && {
        echo "Executable $GZIP does not exists. Make sure correct path is set in $0."
        exit 0
    }
    [ ! -x $TAR ] && {
        echo "Executable $TAR does not exists. Make sure correct path is set in $0."
        exit 0
    }
    [ ! -x $RM ] && {
        echo "File $RM does not exists. Make sure correct path is set in $0."
        exit 0
    }
    [ ! -x $CP ] && {
        echo "File $CP does not exists. Make sure correct path is set in $0."
        exit 0
    }
    [ ! -x $MKDIR ] && {
        echo "File $MKDIR does not exists. Make sure correct path is set in $0."
        exit 0
    }
    [ ! -x $GREP ] && {
        echo "File $GREP does not exists. Make sure correct path is set in $0."
        exit 0
    }
    [ ! -x $FIND ] && {
        echo "File $GREP does not exists. Make sure correct path is set in $0."
        exit 0
    }
}

verify_bins

##################################
# Install php7.1-fpm
##################################

if [ "$phpfpm71_install" = "y" ]; then

    echo "##########################################"
    echo " Installing php7.1-fpm"
    echo "##########################################"

    sudo apt-get install php7.1-fpm php7.1-cli php7.1-zip php7.1-opcache php7.1-mysql php7.1-mcrypt php7.1-mbstring php7.1-json php7.1-intl \
    php7.1-gd php7.1-curl php7.1-bz2 php7.1-xml php7.1-tidy php7.1-soap php7.1-bcmath -y php7.1-xsl -y

    # copy php7.1 config files
    sudo cp -rf $HOME/ubuntu-nginx-web-server/etc/php/7.1/* /etc/php/7.1/
    sudo service php7.1-fpm restart

        # commit changes
    git -C /etc/php/ add /etc/php/ && git -C /etc/php/ commit -m "add php7.1 configuration"

fi

##################################
# Install php7.2-fpm
##################################

if [ "$phpfpm72_install" = "y" ]; then
    echo "##########################################"
    echo " Installing php7.2-fpm"
    echo "##########################################"

    sudo apt-get install php7.2-fpm php7.2-xml php7.2-bz2 php7.2-zip php7.2-mysql php7.2-intl php7.2-gd \
    php7.2-curl php7.2-soap php7.2-mbstring php7.2-xsl php7.2-bcmath -y

    # copy php7.2 config files
    sudo cp -rf $HOME/ubuntu-nginx-web-server/etc/php/7.2/* /etc/php/7.2/
    sudo service php7.2-fpm restart

    # commit changes
    git -C /etc/php/ add /etc/php/ && git -C /etc/php/ commit -m "add php7.2 configuration"

fi

##################################
# Install nginx
##################################

sudo apt install nginx -y

VERIFY_NGINX_CONFIG=$(nginx -t 2>&1 | grep failed)
echo "##########################################"
echo "Checking Nginx configuration"
echo "##########################################"
if [ -z "$VERIFY_NGINX_CONFIG" ]; then
    echo "##########################################"
    echo "Reloading Nginx"
    echo "##########################################"
    sudo service nginx reload
else
    echo "##########################################"
    echo "Nginx configuration is not correct"
    echo "##########################################"
fi
