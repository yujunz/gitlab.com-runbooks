
#!/bin/bash 

###functions 
quit () { exit; }
help () {
               echo "Script for check ERROR consul's logs " 
               echo "sh parse_consul.sh  -f log_consul_file"
               echo "options"
               echo " file: -f log_consul_file"
           
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


echo "* ERRORS"
awk '{ $1="";print}' $log_file | grep "\[ERR\]" | awk '{ $1=""; $2=""; $3=""; $4=""; $5="";$6="" ;print}' | awk -F '^' '{print $1}' |  awk -F '^' '{arr[$1]++} END {for (a in arr) print a "->" arr[a]}'

quit
fi
help 









