#!/bin/bash
set -e
# https://www.duosecurity.com/docs/duounix
# This script adds support for duosecurity.com two factor security for
# ssh logins
#
#==============================================| Get Script Dir
SOURCE="${BASH_SOURCE[0]}"
DIR="$( dirname "$SOURCE" )"
while [ -h "$SOURCE" ]
do
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
  DIR="$( cd -P "$( dirname "$SOURCE"  )" && pwd )"
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
#==============================================| Import Variables
source "$DIR/00-config.ini"

#==============================================| Tests
# Check root privileges
if [[ $EUID -ne 0 ]]; then
  echo "Usage: run this program with escalated root privileges."
  exit 1
fi

#==============================================| SSH Server must be installed
if [ ! -f "/etc/ssh/sshd_config" ]
then 
  echo "Open SSH Server is not installed, exiting."
  exit 1
fi
#==============================================| Download Dependencies
if [ ! -f "/usr/sbin/login_duo" ]
then
  apt-get install dialog
  apt-get install libssl-dev # openssl
  apt-get install make 
fi
#==============================================| Download Duo Login
if [ ! -f "/usr/sbin/login_duo" ]
then 
  cd /tmp
  wget https://dl.duosecurity.com/duo_unix-latest.tar.gz
  tar -zxvf duo_unix-latest.tar.gz
  cd duo_unix*
  ./configure --prefix=/usr && make && sudo make install 
fi
#==============================================| Get Integration Key
# from http://linuxgazette.net/101/sunil.html
DIALOG=${DIALOG=dialog}
tempfile=`tempfile 2>/dev/null` || tempfile=/tmp/test$$
trap "rm -f $tempfile" 0 1 2 5 15

$DIALOG --title "Duo Security Two Factor Authentication" --clear \
        --inputbox "Please Enter Integration Key:" 16 51 2> $tempfile

retval=$?

case $retval in
  0)
    integration_key="`cat $tempfile`"
    ;;
  1)
    echo "Cancel pressed."
    echo "Exiting program."
    exit 1
    ;;
  255)
    if test -s $tempfile ; then
      cat $tempfile
    else
      echo "ESC pressed."
      echo "Exiting program."
      exit 1
    fi
    ;;
esac
#==============================================| Get Secret Key
# from http://linuxgazette.net/101/sunil.html
DIALOG=${DIALOG=dialog}
tempfile=`tempfile 2>/dev/null` || tempfile=/tmp/test$$
trap "rm -f $tempfile" 0 1 2 5 15

$DIALOG --title "Duo Security Two Factor Authentication" --clear \
        --inputbox "Please Enter Secret Key:" 16 51 2> $tempfile

retval=$?

case $retval in
  0)
    secret_key="`cat $tempfile`"
    ;;
  1)
    echo "Cancel pressed."
    echo "Exiting program."
    exit 1
    ;;
  255)
    if test -s $tempfile ; then
      cat $tempfile
    else
      echo "ESC pressed."
      echo "Exiting program."
      exit 1
    fi
    ;;
esac
#==============================================| Get API HOST
# from http://linuxgazette.net/101/sunil.html
DIALOG=${DIALOG=dialog}
tempfile=`tempfile 2>/dev/null` || tempfile=/tmp/test$$
trap "rm -f $tempfile" 0 1 2 5 15

$DIALOG --title "Duo Security Two Factor Authentication" --clear \
        --inputbox "Please Enter API Host:" 16 51 2> $tempfile

retval=$?

case $retval in
  0)
    api_host="`cat $tempfile`"
    ;;
  1)
    echo "Cancel pressed."
    echo "Exiting program."
    exit 1
    ;;
  255)
    if test -s $tempfile ; then
      cat $tempfile
    else
      echo "ESC pressed."
      echo "Exiting program."
      exit 1
    fi
    ;;
esac
#==============================================| Replace the keys
if [ -f /etc/duo/login_duo.conf ]
then 
  sudo sed -i "s/ikey =/ikey=$integration_key/g" /etc/duo/login_duo.conf
  sudo sed -i "s/skey =/skey=$secret_key/g" /etc/duo/login_duo.conf
  sudo sed -i "s/host =/host=$api_host/g" /etc/duo/login_duo.conf
fi

#==============================================| Add values to sshd_config
if [ -f "/etc/ssh/sshd_config" ]
then 
  echo " " >> /etc/ssh/sshd_config
  echo "# Duo Two Factor Security" >> /etc/ssh/sshd_config
  echo "ForceCommand /usr/sbin/login_duo" >> /etc/ssh/sshd_config
  echo "PermitTunnel no" >> /etc/ssh/sshd_config
  echo "AllowTcpForwarding no" >> /etc/ssh/sshd_config
fi

#==============================================| Restart sshd
DIALOG=${DIALOG=dialog}

$DIALOG --title " Installation Completed" --clear \
        --yesno "Restart the OpenSSH Daemon?  This could affect existing ssh connections." 10 30

case $? in
  0)
    echo "Yes chosen."
    /etc/init.d/ssh restart
    ;;
  1)
    echo "No chosen, exiting program."
    ;;
  255)
    echo "ESC pressed, exiting program."
    ;;
esac
exit

