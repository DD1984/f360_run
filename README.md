Execute this scpript to run "wine fusion360" under sandbox using firejail
it prevent unclear exit when fusion360 crash

additonally with cmd option "-newif" script create new net-iface (need root privilege)
this help to sniff fusion360 traffic using wireshark

additonally there is possibility (by editing script) to change gnutls and winedbug optons for debug 
#### install:
place this script to the same folder as Fusion360.exe  
execute ```chmod +x run.sh``` to make this script executable

