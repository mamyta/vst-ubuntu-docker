#!/bin/bash



function ctrl_c() {
clear
echo
echo "Exiting script..."
echo
tput sgr0
stty echo
exit 0

}

function showhelp()
{
echo "- Available switches:"
echo "./hma-openvpn.sh -h = Show help"
echo "./hma-openvpn.sh -d = Daemonize OpenVPN"
echo
tput bold
echo "- This script requires the following packages:"
echo "  curl, openvpn, wget, dialog, sudo"
echo "  e.g.: yum install curl openvpn wget dialog sudo"
echo "    or: apt-get install curl openvpn wget dialog sudo"
echo
tput sgr0
}

while getopts "dh" parm
do
        case $parm in
        d)
                daemonize=1
                ;;
        ?)      echo
		echo "HMA-OpenVPN Script"
		echo "=================="
		echo
		showhelp
		exit 0
		;;
        esac
done


showtitle() {
clear
green="\e[36;5;82m"
stdcol="\e[0m"
echo
echo -e "$green =============================="
echo " |     __  ____  ______    __ |"
echo " |    / / / /  |/  /   |  / / |"
echo " |   / /_/ / /|_/ / /| | / /  |"
echo " |  / __  / /  / / ___ |/_/   |"
echo " | /_/ /_/_/  /_/_/  |_(_)    |"
echo " |                            |"
echo " |  HMA! OpenVPN Script v0.2  |"
echo " =============================="
echo
echo "-> https://hidemyass.com/vpn"
echo -e "-> https://support.hidemyass.com$stdcol"
echo
}

showtitle
showhelp

function checkpackage() {
if [[ $(which $1) == "" ]] ; then
read -p "Package '$1' missing! Proceed anyway? (y/n) " prompt
if [[ $prompt =~ [nN](o)* ]] ; then
echo
exit
fi
fi
}

checkpackage curl
checkpackage wget
checkpackage openvpn
checkpackage dialog

sleep 5
echo "- Getting HMA! Pro VPN serverlist..."
sleep 1

curl -s https://www.hidemyass.com/vpn-config/l2tp/ > /tmp/serverlist.txt
LINES=$(cat /tmp/serverlist.txt | awk -F'\t' '{ print $2,"\t",$1 }')


IFS=$'\n\t'
dialog --backtitle "HMA! OpenVPN Script" \
--title "Select a server" \
--menu "Select a server" 17 90 15 $LINES 2>/tmp/server

response=$?
if [ $response == 255 ] || [ $response = 1 ]; then
ctrl_c
fi

unset IFS

clear
hmaservername=$(cat /tmp/server | sed 's/ *$//')
hmaserverip=$(grep "$hmaservername" /tmp/serverlist.txt | awk '{ print $1 }')

sleep 1
clear

dialog --backtitle "HMA! OpenVPN Script" \
--title "Select OpenVPN protocol to use" \
--yes-label "UDP" --no-label "TCP" --yesno "Which protocol do you want to use?" 6 40
response=$?
case $response in
0) echo "udp" > /tmp/hma-proto ;;
1) echo "tcp" > /tmp/hma-proto ;;
255) ctrl_c ;;
esac

sleep 1
clear

showtitle
hmaproto=`cat /tmp/hma-proto | tr '[:upper:]' '[:lower:]'`
echo "- Getting .ovpn template..."
echo
sleep 1
wget -O /tmp/hma-template.ovpn http://zdcdn.hidemyass.com/other/hma-template.ovpn

echo "proto $hmaproto" >> /tmp/hma-template.ovpn

if [ "$hmaproto" == "udp" ]; then
echo "remote $hmaserverip 53" >> /tmp/hma-template.ovpn
hmaport=53
fi
if [ "$hmaproto" == "tcp" ]; then
echo "remote $hmaserverip 443" >> /tmp/hma-template.ovpn
hmaport=443
fi

showtitle

function checkip()
{
ip=""
attempt=0
while [ "$ip" = "" ]; do
        attempt=$(($attempt+1))
        ip=`curl http://geoip.hidemyass.com/ip/ 2>/dev/null`
        if [ "$ip" != "" ]; then
                echo "- Your current IP is: $ip"
        fi
        if [ $attempt -gt 3 ]; then
                echo "- Failed to check current IP address."
                exit
        fi
done
}

checkip
sleep 1

echo
echo "- Starting OpenVPN connection to:"
echo "  $hmaservername - $hmaserverip : $hmaport ($hmaproto) ..."
echo "  (Please enter your HMA! Pro VPN account username and password when asked)"

sleep 1
echo

if [ "$daemonize" == "1" ]; then
sudo openvpn --daemon --script-security 3 --config /tmp/hma-template.ovpn
echo
echo "Waiting 10 seconds for doing IP-check..."
sleep 10
echo
checkip
echo
echo "Disconnect via: sudo killall openvpn"
echo
else
sudo openvpn --script-security 3 --config /tmp/hma-template.ovpn
fi


ctrl_c

