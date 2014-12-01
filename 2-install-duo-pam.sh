#!/bin/bash
set -e
# https://www.duosecurity.com/docs/duounix
# This script adds support for duosecurity.com two factor security for 
# ssh logins and pam framework compatible linux programs (like sudo, su, etc)
#
# Warning: running this script will rename your existing 
# /etc/pam.d/common-auth file and then replace it with one
# that is properly configured for duo two factor authentication
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
if [ ! -f "/etc/duo/pam_duo.conf" ]
then
  apt-get install dialog
  apt-get install libssl-dev
  apt-get install libpam-dev
  apt-get install make 
fi
#==============================================| Download Duo Login
if [ ! -f "/etc/duo/pam_duo.conf" ]
then 
  cd /tmp
  wget https://dl.duosecurity.com/duo_unix-latest.tar.gz
  tar -zxvf duo_unix-latest.tar.gz
  cd duo_unix*
  ./configure --with-pam --prefix=/usr && make && sudo make install
fi
#==============================================| Download Duo Login
if [ ! -f "/etc/duo/pam_duo.conf" ]
then
  echo "Warning login_duo did not compile properly. Exiting program."
  exit 1
fi

#==============================================| Create Symbolic link for 64bit version (bug)
if [ -f "/lib64/security/pam_duo.so" ]
then
   # if directory /lib/security doesn't exist, create it
   if [ ! -d "/lib/security" ] 
   then 
     mkdir -p /lib/security
   fi
  
   # Create a symbolic link so that the pam_duo.so file is found where it is expected
   # This seems to be a bug that we need to work around 
   if [ ! -f "/lib/security/pam_duo.so" ]
   then 
     ln -s /lib64/security/pam_duo.so /lib/security/pam_duo.so
   fi
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
if [ -f /etc/duo/pam_duo.conf ]
then 
  sudo sed -i "s/ikey =/ikey=$integration_key/g" /etc/duo/pam_duo.conf
  sudo sed -i "s/skey =/skey=$secret_key/g" /etc/duo/pam_duo.conf
  sudo sed -i "s/host =/host=$api_host/g" /etc/duo/pam_duo.conf
fi

#==============================================| Configure pam configuration
# Test to see if we have the old or new pam configuration file format and copy accordingly
mv /etc/pam.d/common-auth /etc/pam.d/common-auth.org
if grep -q pam_permit.so "/etc/pam.d/common-auth.org"; then
  cp $DIR/templates/pam/common-auth-ubuntu-new /etc/pam.d/common-auth
else
  cp $DIR/templates/pam/common-auth /etc/pam.d/common-auth
fi
#==============================================| Add values to sshd_config
sed -i "s/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/g" /etc/ssh/sshd_config
echo "UseDNS no" >> /etc/ssh/sshd_config
#==============================================| Add values to /etc/pam.d/sshd
if grep -q pam_permit.so "/etc/pam.d/common-auth.org"; then
  sed -i "s/@include common-auth/auth    required pam_duo.so/g" /etc/pam.d/sshd
fi
#==============================================| Restart sshd
DIALOG=${DIALOG=dialog}

$DIALOG --title "Installation Completed" --clear \
        --yesno "Restart the OpenSSH Daemon?  This could affect existing ssh connections." 10 30

case $? in
  0)
    #echo "Yes chosen."
    service ssh restart
    ;;
  1)
    #echo "No chosen, exiting program."
    exit 1
    ;;
  255)
    #echo "ESC pressed, exiting program."
    exit 1
    ;;
esac
#==============================================| Display Troubleshooting message 
DIALOG=${DIALOG=dialog}

$DIALOG --title "Installation Completed" --clear \
        --yesno "Set your integration profile to Require Enrollment for 1st time setup of new users. Check /var/log/auth.log for errors." 10 30

case $? in
  0)
    exit 1
    ;;
  1)
    #echo "No chosen, exiting program."
    exit 1
    ;;
  255)
    #echo "ESC pressed, exiting program."
    exit 1
    ;;
esac

exit
