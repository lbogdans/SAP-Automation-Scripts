#!/bin/bash

#
# This script is for copying transport files from other systems to this one. 
#

# ############
# Adopt vars 
# ############

SIDADM="sidadm" #<sid> == your SAP SID 
SIDGroup="sapsys" #standard group
File="transports.txt"

Red="\e[3;31m"
Green="\e[3;32m"
ColorEnd="\e[0m"

while IFS= read -r Transport; do
    echo -e "${Green}--------------$ColorEnd"
    echo -e "${Green}$Transport:$ColorEnd"
    SID=${Transport:0:3}
    SIDlow=${SID,,}
    Number=${Transport:4:6}

    cd /opt/$SIDlow/trans/cofiles || { echo -e "${Red}Directory could not be opened$ColorEnd"; exit 1; }
    cp K$Number.$SID /usr/sap/trans/cofiles
    if [ $? -ne 0 ]; then
        echo -e "${Red}cofile file not found$ColorEnd"
        exit
    else
        chown $SIDADM:$SIDGroup /usr/sap/trans/cofiles/K$Number.$SID
        chmod 777 /usr/sap/trans/cofiles/K$Number.$SID
        echo -e "${Green}cofile copied$ColorEnd"
    fi

    cd /opt/$SIDlow/trans/data || { echo -e "${Red}Directory could not be opened$ColorEnd"; exit 1; }
    cp R$Number.$SID /usr/sap/trans/data
    if [ $? -ne 0 ]; then
        echo -e "${Red}data file not found$ColorEnd"
        exit
    else
        chown $SIDADM:$SIDGroup /usr/sap/trans/data/R$Number.$SID
        chmod 777 /usr/sap/trans/data/R$Number.$SID
        echo -e "${Green}data copied$ColorEnd"
    fi

    cd /usr/sap/trans || { echo -e "${Red}Directory could not be opened$ColorEnd"; exit 1; }
done <$File
