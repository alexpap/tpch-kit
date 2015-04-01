#!/usr/bin/env bash
#
# install | update | uninstall
# dbgen | clean | list

export TPCH_KIT_HOME="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../" && pwd )"
export TPCH_KIT_MASTER=$(< "$TPCH_KIT_HOME/conf/master")
export TPCH_KIT_WORKERS=$(< "$TPCH_KIT_HOME/conf/workers")
export TPCH_HOME="$TPCH_KIT_HOME/tpch/tpch_2_17_0"
export TPCH_SF=2
export TPCH_KIT_CHUNKS="${#TPCH_KIT_NODES[@]}"
export TPCH_KIT_CHUNK=1

echo "TPCH_KIT_HOME : $TPCH_KIT_HOME"
echo "TPCH_KIT_NODES : $TPCH_KIT_NODES"
echo "TPCH_HOME : $TPCH_HOME"
echo "TPCH_KIT_CHUNKS : $TPCH_KIT_CHUNKS"
echo "TPCH_KIT_CHUNK : $TPCH_KIT_CHUNK"

####
# help message
SCRIPT_NAME=$(basename $0)
function usage(){
    cat << EOF
    NAME
        "${SCRIPT_NAME}" - exareme administration script.

    SYNOPSIS
        "${SCRIPT_NAME}" OPTIONS [OPTIONS_PARAMETERS]

    OPTIONS [OPTIONS_PARAMETERS]

        --dbgen                         - runs dbgen
        --clean                         - remove generated tables
        --list                          - list generated tables

        --install                       - installs kit on each worker
        --uninstall                     - uninstalls kit on each worker
EOF
}
####
# Generates all tpch tables based on sf, chunk, chunks
# moves and compress generated tables
# TODO provide explicit table name
kit_dbgen() {
    for NODE in $TPCH_KIT_WORKERS; do
        echo "Generating tables on $NODE"
        ssh $USER@$NODE << EOF
            cd "$TPCH_HOME/dbgen"
            if [[ $TPCH_KIT_CHUNKS < 2 ]]; then
                ./dbgen -f -q -s "$TPCH_SF"
            else
                ./dbgen -f -q -s "$TPCH_SF" -C "$TPCH_KIT_CHUNKS" -S "$TPCH_KIT_CHUNK"
            fi

            mkdir -p $TPCH_KIT_HOME/datasets/
            mv -f *.tbl* $TPCH_KIT_HOME/datasets/
            cd  $TPCH_KIT_HOME/datasets/
            gzip -f *.tbl*
EOF
     done
    return 0
}

####
# clean generated tables
function kit_clean() {

    for NODE in $TPCH_KIT_WORKERS; do
        echo "Cleaning tables on $NODE"
        ssh $USER@$NODE << EOF
            rm $TPCH_KIT_HOME/datasets/*tbl*
            rm $TPCH_HOME/dbgen/*tbl*
        EOF
    done
    return 0
}

####
# list generated tables
function kit_list() {
    for NODE in $TPCH_KIT_WORKERS; do
        echo "Listing tables on $NODE"
        ssh $USER@$NODE << EOF
            cd  $TPCH_KIT_HOME/datasets/
            ls -lh
EOF
    done
    return 0
}

####
# installs kit to workers
function kit_install() {
    for NODE in $TPCH_KIT_WORKERS; do
        echo "Installing kit on $NODE."
        rsync -aqvzhe ssh --delete              \
            --exclude='datasets/*'              \
            --exclude='$TPCH_HOME/dbgen/*tbl*'  \
            $TPCH_KIT_HOME/ $USER@$NODE:$TPCH_KIT_HOME/ &
    done
    return 0
}

#####
# uninstalls kit from workers
function kit_uninstall(){
    for NODE in $TPCH_KIT_WORKERS; do
        echo "Uninstalling kit from $NODE"
        ssh $USER@$NODE "rm -rf $TPCH_KIT_HOME"
    done
    return 0
}

TEMP=`getopt --options h \
             --long dbgen,list,clean,install,uninstall,help \
             -n $(basename "$0") -- "$@"`

if [ $? != 0 ]; then echo "Terminating..." >&2; exit 1; fi

eval set -- "$TEMP"
RUN=""

while true; do
   case "$1" in
        --install|--uninstall|--dbgen|--list|--clean)
            RUN="${1:2}";
            ;;
        -h|--help)
              usage
            exit 0 ;;
        --) shift
            break
            ;;
        *)
            echo "Internal error!"
            exit 1
            ;;
    esac
    shift;
done

if [ -n "$1" ]; then echo -e "Unresolved arguments:\n--> $1" ; exit 1; fi
if [ ! $RUN ]; then echo -e "Please provide an argument "; exit 1; fi

kit_$RUN
exit 0
