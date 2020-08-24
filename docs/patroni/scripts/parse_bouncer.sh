
#!/bin/bash 

###functions 
quit () { exit; }
help () {
               echo "Script for check pgbouncer's logs " 
               echo "sh parse_bouncer.sh  -f log_pgbouncer_file"
               echo "options"
               echo " mode: -f log_pgbouncer_file"
           
               quit
           }


 
while getopts f:h option 
do 
 case "${option}" 
 in 
 f) log_file=${OPTARG};; #mode check/generate
 h) help
 esac 
done 
 
if test -f "$log_file"; then
echo  "* AVG Number of queries/sec by pgbouncer"
awk '{ $1="";print}' $log_file | grep "] LOG stats:" | awk '{ $1="";print}' | awk '{ print $1 ","  $2 " " $3 "," $10 "," $13 "," $16 "," $22 }' | awk -F ',' '{a[$1] += $3 ; n++} END{for (i in a) print i, a[i]/(n/3)}'

echo  "* AVG of queries times(us) by pgbouncer"
awk '{ $1="";print}' $log_file | grep "] LOG stats:" | awk '{ $1="";print}' | awk '{ print $1 ","  $2 " " $3 "," $10 "," $13 "," $16 "," $22 }' | awk -F ',' '{a[$1] += $6; n++} END{for (i in a) print i, a[i]/(n/3)}'

echo  "* AVG of KB in by pgbouncer"
awk '{ $1="";print}' $log_file | grep "] LOG stats:" | awk '{ $1="";print}' | awk '{ print $1 ","  $2 " " $3 "," $10 "," $13 "," $16 "," $22 }' | awk -F ',' '{a[$1] += $4 ; n++} END{for (i in a) print i, (a[i]/(n/3))/1000}'

echo  "* AVG of KB out by pgbouncer"
awk '{ $1="";print}' $log_file | grep "] LOG stats:" | awk '{ $1="";print}' | awk '{ print $1 ","  $2 " " $3 "," $10 "," $13 "," $16 "," $22 }' | awk -F ',' '{a[$1] += $5; n++} END{for (i in a) print i, (a[i]/(n/3))/1000}'

echo  "* Conexions by pgbouncer"
awk '{ $1="";print}' $log_file | grep "] LOG" | grep "closing because:" | awk '{ $1="";print}' | awk '{ print $1 ","  $2 " " $3 "," $8 "," $14 }' | awk -F ',' '{ print $1 ","  $2 "," $3 "," gsub(/[A-Za-z=()]/,"",$4); print $1 "," $2 "," $3 "," $4 "," "my_l1n3" }' | grep "my_l1n3" | awk -F ',' '{arr[$1]++} END {for (a in arr) print a, arr[a]}'


echo  "* AVG of conexions time(s) by bouncer" 
awk '{ $1="";print}' $log_file | grep "] LOG" | grep "closing because:" | awk '{ $1="";print}' | awk '{ print $1 ","  $2 " " $3 "," $8 "," $14 }' | awk -F ',' '{ print $1 ","  $2 "," $3 "," gsub(/[A-Za-z=()]/,"",$4); print $1 "," $2 "," $3 "," $4 "," "my_l1n3" }' | grep "my_l1n3" | awk -F ',' '{a[$1] += $4 ; n++} END{for (i in a) print i, a[i]/(n/3)}'


echo "* Conexions by IP"
awk '{ $1="";print}' $log_file | grep "] LOG" | grep "closing because:" | awk '{ $1="";print}' | awk '{ print $1 ","  $2 " " $3 "," $8 "," $14 }' | awk -F ',' '{ print $1 ","  $2 "," $3 "," gsub(/[A-Za-z=()]/,"",$4); print $1 "," $2 "," $3 "," $4 "," "my_l1n3" }' | grep "my_l1n3" | awk -F ',' '{ print $3}' | awk -F ':' '{print $1}' | awk -F '@' '{print $2}' | awk '{arr[$1]++} END {for (a in arr) print a ": " arr[a]}'


echo "* Conexions by users"
awk '{ $1="";print}' $log_file | grep "] LOG" | grep "closing because:" | awk '{ $1="";print}' | awk '{ print $1 ","  $2 " " $3 "," $8 "," $14 }' | awk -F ',' '{ print $1 ","  $2 "," $3 "," gsub(/[A-Za-z=()]/,"",$4); print $1 "," $2 "," $3 "," $4 "," "my_l1n3" }' | grep "my_l1n3" | awk -F ',' '{ print $3}' | awk -F ':' '{print $1}' | awk -F '@' '{print $1}' | awk -F '/' '{print $1}' | awk '{arr[$1]++} END {for (a in arr) print a "->" arr[a]}'


echo "* Conexions by DB"
 awk '{ $1="";print}' $log_file | grep "] LOG" | grep "closing because:" | awk '{ $1="";print}' | awk '{ print $1 ","  $2 " " $3 "," $8 "," $14 }' | awk -F ',' '{ print $1 ","  $2 "," $3 "," gsub(/[A-Za-z=()]/,"",$4); print $1 "," $2 "," $3 "," $4 "," "my_l1n3" }' | grep "my_l1n3" | awk -F ',' '{ print $3}' | awk -F ':' '{print $1}' | awk -F '@' '{print $1}' | awk -F '/' '{print $2}' | awk '{arr[$1]++} END {for (a in arr) print a "->" arr[a]}'
fi


echo "* Error by type"
awk '{ $1="";print}' $log_file | grep "WARNING" | grep "pooler error" | awk '{ $1="";print}' | awk -F ':' '{print $1 "->"$5 "," $7}'| awk -F ',' '{print $1 "," $2}' | awk -F ','  '{arr[$2]++} END {for (a in arr) print a ": " arr[a]}'

echo "* Error by pgbouncer/IP"
awk '{ $1="";print}' $log_file | grep "WARNING" | grep "pooler error" | awk '{ $1="";print}' | awk -F ':' '{print $1 "->"$5 "," $7}'| awk -F ',' '{print $1 "," $2}' | awk -F ','  '{arr[$1]++} END {for (a in arr) print a ": " arr[a]}'
quit

help 





