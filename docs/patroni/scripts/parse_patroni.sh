
#!/bin/bash 

###functions 
quit () { exit; }
help () {
               echo "Script for check ERROR patroni's logs " 
               echo "sh parse_patroni.sh  -f log_patroni_file"
               echo "options"
               echo " file: -f log_patroni_file"
           
               quit
           }


 
while getopts f:h option 
do 
 case "${option}" 
 in 
 f) log_file=${OPTARG};; #file 
 h) help
 esac 
done 
 
if test -f "$log_file"; then

echo "* WARNINGS"
awk '{ $1="";print}' $log_file | grep "WARNING:" | awk '{ $1=""; $2=""; $3=""; $4="";print}' | awk -F '^' '{print $1}' |  awk -F '^' '{arr[$1]++} END {for (a in arr) print a "->" arr[a]}'

echo "* ERRORS"
awk '{ $1="";print}' $log_file | grep "ERROR:" | awk '{ $1=""; $2=""; $3=""; $4="";print}' | awk -F '^' '{print $1}' |  awk -F '^' '{arr[$1]++} END {for (a in arr) print a "->" arr[a]}'
quit
fi
help 









