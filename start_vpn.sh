#!/bin/bash

function checkip()
{
ip=""
attempt=0
while [ "$ip" = "" ]; do
        attempt=$(($attempt+1))
        ip=$(wget geoip.hidemyass.com/ip/ -q -O -)
        if [ "$ip" != "" ]; then
                echo "- Your current IP is: $ip"
        fi
        if [ $attempt -gt 3 ]; then
                echo "- Failed to check current IP address."
                exit
        fi
done
}

wget -O /tmp/hma-template.ovpn http://zdcdn.hidemyass.com/other/hma-template.ovpn
echo "proto tcp" >> /tmp/hma-template.ovpn
echo "remote 184.75.217.2 443" >> /tmp/hma-template.ovpn
sed -i 's/auth-user-pass/auth-user-pass /tmp/login-vpn.conf/g' /tmp/hma-template.ovpn

sudo openvpn --daemon --script-security 3 --config /tmp/hma-template.ovpn
sleep 10
checkip