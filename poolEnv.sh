#!/bin/bash

#LOGFILE="DockerRunThis"  
#exec  >  >(tee -a "$LOGFILE")  2>&1  
#set  -o xtrace



function usage() {
        echo -e
        echo -e "Usage:"
        echo -e "\t$0 [OPTION]"
        echo -e
        echo -e "\t-N Name for containers. ( Defaults = pg)"
        echo -e "\t-n number of of containers. (default = 1)"
        echo -e "\t-s First 3 octets of subnet to use. Example  172.28.100 "
        echo -e "\t-t Name for docker network to create (default = pgnet)"
        echo -e "\t-c Create the netork. Otherwise, just use the existing network"
        echo -e "\t-m Setup postgres environment to use md5 password_encription"
        echo -e
        exit
}


function createNetwork() {
echo -e "
docker network create \
--driver bridge \
--subnet $subnet \
--gateway $gateway \
$netName
"
} >> $dockerRunFile


function createNode() {
echo -e "
docker run \
-p $pgPortMap:5432 \
-p $poolPortMap:9999 \
--env=PGPASSWORD=postgres \
-v ${nodeName}-pgdata:/pgdata \
--hostname=$nodeName \
--network=$netName \
--name=$nodeName \
--privileged \
--ip $nodeIp \
$md5 \
-dt rocky9_pg17_pgpool
" >> $dockerRunFile
}


function getPgPorts() {
   lastPgUsed=""
   lastPgUsed=$(docker ps --format "{{.Ports}}" | grep 5432 |  sed -n 's/.*0\.0\.0\.0:\([0-9]*\)->5432\/tcp.*/\1/p' | sort | tail -1);
}

function getPoolPorts() {
   lastPoolUsed=""
   lastPoolUsed=$(docker ps --format "{{.Ports}}" | grep 9999 |  sed -n 's/.*0\.0\.0\.0:\([0-9]*\)->9999\/tcp.*/\1/p' | sort | tail -1);
}


function checkExistingContainers() {
   containerNameList=$(docker ps -a --format "{{.Names}}")
   tempNameList=$(echo "$containerNameList" | tr -d '0-9')
   containerNameList=$(echo $containerNameList | tr \n " ")

   if [[ "$tempNameList" =~ "$nodeName" ]]; then
      echo -e
      echo -e "Container conflict: \"$nodeName\" already exists in the list of docker containers on this host \"$containerNameList\" "
      echo -e
      exit
   fi
}

function checkNumber() {
   num=$1
   var=$2
   valid=0
   regexp='^[0-9]+$'
   if ! [[ $num =~ $regexp ]] ; then
      echo -e
      echo -e "Invalid format: Only numbers are allowed. \"$num\" entered for \"$var\". Please correct and try again"
      echo -e
      exit
   fi
}



function checkAlpha() {
   str=$1
   var=$2
   valid=0
   regexp='^[a-z]+$'
   if ! [[ $str =~ $regexp ]] ; then
      echo -e
      echo -e "Invalid format: Only lower case letters are allowed. No special characters. \"$str\" entered for \"$var\". Please correct and try again"
      echo -e
      exit
   fi
}
  

function checkSubnet() {
   str=$1
   var=$2
   valid=0
   # Regex for three octets: nnn.nnn.nnn where nnn is 0–255
   if [[ "$sub" =~ ^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$ ]]; then
     # Validate each octet is <= 255
     if (( ${BASH_REMATCH[1]} <= 255 && ${BASH_REMATCH[2]} <= 255 && ${BASH_REMATCH[3]} <= 255 )); then
        return
     else
        echo -e
        echo -e "Invalid subnet: One or more octet is > 255 \"$sub\" entered for \"$var\". Please correct and try again"
        echo -e
        exit
     fi
   else
     echo -e
     echo -e "Invalid format: \"$sub\" entered for \"$var\". Please correct and try again"
     echo -e
     exit
   fi
}



# --- Set some default values
numNodes=1
nodeName="pg"
md5=""
dockerImage="rocky9_pg17_pgpool"
dockerCreateNetwork=0


imageExists=$(docker images | grep -w $dockerImage | wc -l)

if [ $imageExists -eq 0 ]; then
   echo -e
   echo -e "The necessary docker image \"$dockerImage\" does not exist. Please clone from the repo and run \"docker build -t rocky9_pg17_pgpool .\" from within the folder containing the docker files"
   echo -e
   exit
fi

while getopts n:N:s:t:mc name
do      
   case $name in
      N) nodeName="$OPTARG";;
      n) numNodes="$OPTARG";; 
      s) sub="$OPTARG";; 
      t) netName="$OPTARG";; 
      m) md5="--env=MD5=1";; 
      c) dockerCreateNetwork=1;;
      *) usage;;
      ?) usage;;
   esac 
done    
shift $(($OPTIND - 1))

if [ -z "$sub" ] || [ -z "$netName" ]; then
   usage
fi



checkAlpha  $nodeName "-N"
checkNumber $numNodes "-n"
checkAlpha $netName "-t"
checkSubnet $sub "-s"

checkExistingContainers

networkExists=$(docker network ls | grep -w $netName | wc -l)

if [[ $networkExists -ge 1 && $dockerCreateNetwork -eq 1 ]]; then
   echo -e
   echo -e "The network \"$netName\" already exist. run without -c option"
   echo -e
   exit
fi 


dockerRunFile="DockerRunThis.${nodeName}"
echo -e "" > $dockerRunFile

tempNodeName=$nodeName
subnet="${sub}.0/24"
gateway="${sub}.1"


# --- Lets see port mappings used by docker for 5432 ( postgres ) then use next available
getPgPorts

if [ -n "$lastPgUsed" ]; then 
   nextPgPort=$(( lastPgUsed + 1 ))
else 
   nextPgPort="6431"
fi

# --- Lets see port mappings used by docker for 9999 ( pgpool ) then use next available
getPoolPorts

if [ -n "$lastPoolUsed" ]; then 
   nextPoolPort=$(( lastPoolUsed + 1 ))
else 
   nextPoolPort="9991"
fi



if [ $dockerCreateNetwork -eq 1 ]; then
   createNetwork
fi

for (( i=1; i<=$numNodes; i++ )); do
   # Dont start with one for ip address since that s reserver for the gateway
   nextIp=$(( i + 10 ))
   nodeName="${tempNodeName}${i}"
   nodeIp="${sub}.${nextIp}"
   pgPortMap=$(( nextPgPort + $i ))
   poolPortMap=$(( nextPoolPort + $i ))
   createNode
done

chmod 700 $dockerRunFile

echo 
echo "The following file: ${dockerRunFile},  contains the needed docker run commands"
echo 



