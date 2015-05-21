#!/bin/bash

function checkip()
{
ip=""
attempt=0
while [ "$ip" = "" ]; do
        attempt=$(($attempt+1))
        ip=$(wget geoip.hidemyass.com/ip/-q -O -)
        #ip=`curl http://geoip.hidemyass.com/ip/ 2>/dev/null`
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