#!/bin/bash

#
# This script is used to add the transports from the list to the import queue and or import them.
# run as <sid>adm
#

# ############
# Adopt vars 
# ############


File="transports.txt"
Import="Y" # Y or N
SID="SID"	 # <SID> where you want to import
Client="500"	# <SAP Client>
Profile="TP_DOMAIN_SID.PFL"  # <SID> for domain system
AddMode="u1"  # e.g. u1
ImportMode="" # e.g. u26
Project=""

if [ -s "$File" ] # File is/not empty
then
    if ! ( $Project );then Project="${Project}_"; fi
    mkdir ./scriptlog
    Logfile="./scriptlog/${SID}_${Project}$(date +%F_%H-%M-%S).log"
    timestamp() {
        date +%F_%T # current time
    }
    
    Red="\e[3;31m"
    Cyan="\e[3;96m"
    Green="\e[3;32m"
    Yellow="\e[3;93m"
    Magenta="\e[3;95m"
    ColorEnd="\e[0m"
    
    
    function addtobuffer() {
        tp addtobuffer "$Transport" $SID client=$Client pf=/usr/sap/trans/bin/$Profile $AddMode "$@" | tee -a "$Logfile"
        RC=${PIPESTATUS[0]}
        if [ "$RC" -ne 0 ]; then
            echo -e "${Red}$Transport: Code $RC: Attaching error!$ColorEnd" | tee -a "$Logfile"
            echo -en "${Magenta}"
            read -rp "Unconditional Mode set for this transport (z.B. u1) or (B) break, (R) repeat or (C) continue and skip this?" InputAddMode </dev/tty
            echo -en "${ColorEnd}"
            
            if [ "${InputAddMode,,}" == "b" ]; then
                echo -e "User (B) break!" | tee -a "$Logfile"
                exit
                
                elif [ "${InputAddMode,,}" == "c" ]; then
                echo -e "${Red}$Transport: Was due to failure $RC: skipped when attaching.$ColorEnd" | tee -a "$Logfile"
                # Delete transport from list to skip it.
                sed -i "/$Transport/d" "$File"
                continue
                
                elif [ "${InputAddMode,,}" == "r" ]; then
                addtobuffer
                
                elif [[ "${InputAddMode,,}" == u* ]]; then
                echo -e "Try unconditional mode $InputAddMode:" | tee -a "$Logfile"
                PrevAddMode=$AddMode
                AddMode=$InputAddMode
                addtobuffer "$@"
                AddMode=$PrevAddMode
                
            else
                echo -e "${Red}No entry is made, it is canceled.$ColorEnd" | tee -a "$Logfile"
                exit
            fi
            
        else
            echo -e "${Green}$Transport: Code $RC: Appended successfully.$ColorEnd" | tee -a "$Logfile"
        fi
    } # function addtobuffer()
    
    function import() {
        tp import "$Transport" $SID client=$Client pf=/usr/sap/trans/bin/$Profile $ImportMode "$@" | tee -a "$Logfile"
        RC=${PIPESTATUS[0]}
        if [ "$RC" -gt 4 ]; then
            echo -e "${Red}$Transport: Code $RC: Import error!$ColorEnd" | tee -a "$Logfile"
            echo -en "${Magenta}"
            read -rp "Set unconditional mode for this transport (e.g. u2) or break (B) or continue (C) and skip this? " InputImportMode </dev/tty
            echo -en "${ColorEnd}"
            
            if [ "${InputImportMode,,}" == "b" ]; then
                echo -e "User (B) break!" | tee -a "$Logfile"
                exit
                
                elif [ "${InputImportMode,,}" == "c" ]; then
                echo -e "${Red}$Transport: Was due to failure $RC: skipped$ColorEnd" | tee -a "$Logfile"
                # Delete transport from list to skip it.
                sed -i "/$Transport/d" "$File"
                
                elif [[ ${InputImportMode,,} == u* ]]; then
                echo -e "Try unconditional mode $InputImportMode:" | tee -a "$Logfile"
                PrevImportMode=$ImportMode
                ImportMode=$InputImportMode
                import "$@"
                ImportMode=$PrevImportMode
                
            else
                echo -e "${Red}No entry is made, it is canceled.$ColorEnd" | tee -a "$Logfile"
                exit
            fi
            
            elif [ "$RC" -eq 4 ]; then
            echo -e "${Yellow}$Transport: Code $RC: imported with warning.$ColorEnd" | tee -a "$Logfile"
            # Delete transport from list after successful import.
            sed -i "/$Transport/d" "$File"
            
        else
            echo -e "${Green}$Transport: Code $RC: Successfully imported.$ColorEnd" | tee -a "$Logfile"
            # Delete transport from list after successful import.
            sed -i "/$Transport/d" "$File"
        fi
    } # function import()
    
    
    echo -e "SID=${SID}\nClient=${Client}\nProfile=${Profile}\nAdd Mode=${AddMode}\nImport Mode=${ImportMode}\n" | tee -a "$Logfile"
    
    # Looping over transports
    while IFS= read -r Transport; do
        Transport=$(echo -e "${Transport}" | tr -d "[:blank:]") # Trim whitespace
        
        echo -e "${Cyan}----------$ColorEnd" | tee -a "$Logfile"
        echo -e "${Cyan}$Transport:$ColorEnd" | tee -a "$Logfile"
        
        if [[ $Transport == "Pause" ]];then
            while : ; do
                echo -en "${Magenta}"
                read -rp "Discovered a break, please continue with (C) or break (B)?" InputPause </dev/tty
                echo -en "${ColorEnd}"
                
                if [ "${InputPause,,}" == "c" ]; then
                    # Delete first occurrence of "Pause" from list.
                    sed -i "0,/$Transport/d" "$File"
                    continue 2
                    elif [[ "${InputPause,,}" == "b"  ]]; then
                    echo -e "${Red}Run was canceled during a break.$ColorEnd" | tee -a "$Logfile"
                    exit
                else
                    echo "Please press c or b!"
                fi
            done
        fi
        
        addtobuffer "$@"
        
        if [ "$Import" == "Y" ]; then
            import "$@"
        fi
        
    done <$File
    
else # File is empty
    Red="\e[3;31m"
    ColorEnd="\e[0m"
    
    echo -e "${Red}$File does not contain any transports!$ColorEnd"
    exit
fi
