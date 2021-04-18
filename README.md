# SAP-Automation-Scripts
## SAP Transport Import Scripts 

### [copy_sap_transports.sh](copy_sap_transports.sh)

This script will copy transport files (data/cofiles) from other SAP systems. 
In this version, it is necessary to mount the other trans directory under /opt and the SID.
The transports are entered per line in the transports.txt. Attention! Remove the line break from the file "transport.txt"
The script uses the SID in the transport number to check which system the transport comes from and copies it and sets the corresponding permissions.
TODO: In future add ssh/scp copy method. 

### [import_sap_transports.sh](import_sap_transports.sh)

This script will import SAP Transports from the list "transports.txt" to the import queue and or import them to your SAP system.
It checks for errors when adding and/or importing and, if necessary, the current transport can be restarted with a different unconditional mode or cancelled.

It's also possible to add the word "Pause" to the list, to let the import pause at certain position until you press a certain key.

Everything is written into a log file.

You have to create a file with transport requests: "transport.txt" with content: 


TR1

...

TRN 

Attention! Remove the last line break/new line character from the file "transport.txt"
