#!/bin/bash

# reste à faire :
# effectuer les tâches décrites dans les 3 "après test", c'est a dire :
#   lancer la comande mongo
#   envoyer en sftp
#   rendre effective la suppression des fichiers supérieur à N jours


function show_help {
    echo "Two option are availables"
    echo "Only one of these options can be used at the same time"
    echo "  -k|--keep : delete older export than a date (in day)"
    echo "  -kn|--keepnumber : delete older export than a limit (in number)"

}


# Check if the environment variable AXWAY_LOGIN AXWAY_PASSWORD and AXWAY_URL are set inside the environment variables
onEnvirVariableError=false
if [[ -z "${AXWAY_LOGIN}" ]]; then
    echo "AXWAY_LOGIN should be set into environnement variable"
    onEnvirVariableError=true
fi
if [[ -z "${AXWAY_PASSWORD}" ]]; then
    echo "AXWAY_PASSWORD should be set into environnement variable"
    onEnvirVariableError=true
fi
if [[ -z "${AXWAY_URL}" ]]; then
    echo "AXWAY_URL should be set into environnement variable"
    onEnvirVariableError=true
fi

if [ $onEnvirVariableError = true ]; then
    exit 1 
fi

nbDay=-1
nbExport=-1
# Check options 
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|-\?|--help)
            show_help    # Display a usage.
            exit
            ;;
        -k|--keep)       # Takes an option argument; ensure it has been specified.
            if [ "$2" ]; then
                nbDay=$2
                shift
            else
                echo 'ERROR: "--keep" requires a non-empty option argument.'
                exit 1
            fi
            ;;
        -kn|--keepnumber)       # Takes an option argument; ensure it has been specified.
            if [ "$2" ]; then
                nbExport=$2
                shift
            else
                echo 'ERROR: "--keepnumber" requires a non-empty option argument.'
                exit 1
            fi
            ;;
        *)               # Default case: No more options, so break out of the loop.
            echo "ERROR:  Unknown option "$1
            show_help
            exit 1
    esac
    shift
done

if [ $nbDay -gt -1  ] && [ $nbExport -gt -1  ]; then
    echo "keep et keepnumber can't be used in the same time"
    exit 1
fi


# write the export file
todayDate=`date +%Y%m%d_%H%M%S`
filePrefixName=SML_BDF_HOME_
fileName=${filePrefixName}${todayDate}.json
localPath="/tmp"
########
### après test, supprimer la ligne echo truc, décommenter la ligne mongo
########
echo "truc" > $localPath/$fileName
#mongo smartuxdb -u mongouser -p mongopassword --quiet hubdata-export.js > $localPath/$fileName
gzip $localPath/$fileName


# send the export file
########
### après test, décomenter la lgine suivante
########
#lftp sftp://${AXWAY_LOGIN}:${AXWAY_PASSWORD}@${AXWAY_URL} -e "set net:max-retries 2;put $localPath/$fileName.gz ;bye"


# clean
if [ $nbDay -gt -1  ]; then
    echo "Delete all file older than $nbDay days"
    echo "the fallowings files are deleted : "
########
### après test, décomenter -exec rm -f
########
    find $localPath/ -name "${filePrefixName}*gz" -ctime +$nbDay #-exec rm -f {} \
fi

if [ $nbExport -gt -1  ]; then    
    nbFileConcerned=`ls -t $localPath/${filePrefixName}*gz | awk "NR>$nbExport"| wc -l`
    echo "keep the last ${nbExport} files, delete the others"
    if [ $nbFileConcerned -gt 0 ]; then
        echo "the fallowings files are deleted : "
        ls -t $localPath/${filePrefixName}*gz | awk "NR>$nbExport"
        rm `ls -t $localPath/${filePrefixName}*gz | awk "NR>$nbExport"`
    else 
        echo "no files deleted" 
    fi
fi

