#!/usr/bin/env bash
#
# install |  uninstall
# dbgen | clean | list

export TPCH_KIT_HOME="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../" && pwd )"
export TPCH_HOME="$TPCH_KIT_HOME/tpch/tpch_2_17_0"
export TPCH_KIT_MASTER=($(< "$TPCH_KIT_HOME/conf/master"))
export TPCH_KIT_WORKERS=($(< "$TPCH_KIT_HOME/conf/workers"))
export TPCH_KIT_NODES=($(cat "$TPCH_KIT_HOME/conf/master" "$TPCH_KIT_HOME/conf/workers"))
export TPCH_SF=$(< "$TPCH_KIT_HOME/conf/sf")
export TPCH_KIT_CHUNKS="${#TPCH_KIT_NODES[@]}"

#
#echo " TPCH_KIT_HOME   : $TPCH_KIT_HOME"
#echo " TPCH_HOME       : $TPCH_HOME"
#echo " TPCH_SF         : $TPCH_SF"
#echo " TPCH_KIT_CHUNKS : $TPCH_KIT_CHUNKS"
#
#
#exit 0
########################################################################################################################
# help message
########################################################################################################################
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

########################################################################################################################
# Generates all tpch tables (based on sf, chunks), moves and compress tables.
########################################################################################################################
kit_dbgen() {
COUNTER=0
for NODE in ${TPCH_KIT_NODES[*]}; do

COUNTER=$((COUNTER+1))

echo "Generating tabls for $NODE/$COUNTER"

RUN=$( cat << EOF
  cd "$TPCH_HOME/dbgen"
  if (( $TPCH_KIT_CHUNKS < 2 )); then
    ./dbgen -f -q -s "$TPCH_SF"
  else
    ./dbgen -f -q -s "$TPCH_SF" -C "$TPCH_KIT_CHUNKS" -S "$COUNTER"
  fi
  mkdir -p $TPCH_KIT_HOME/datasets/
  mv -f *.tbl* $TPCH_KIT_HOME/datasets/
  cd  $TPCH_KIT_HOME/datasets/
  gzip -f *.tbl*
EOF
)

ssh -n $USER@$NODE """$RUN""" &


done

return 0
}

########################################################################################################################
# clean generated tables
########################################################################################################################
kit_clean() {

  for NODE in ${TPCH_KIT_NODES[*]}; do
        echo "Cleaning tables on $NODE"
        ssh -n $USER@$NODE "rm $TPCH_KIT_HOME/datasets/*tbl* 2> /dev/null" &
    done
    return 0
}

########################################################################################################################
# list generated tables
########################################################################################################################
kit_list() {
  for NODE in ${TPCH_KIT_NODES[*]}; do
        echo "Listing tables on $NODE"
        ssh -n $USER@$NODE "ls -lh $TPCH_KIT_HOME/datasets 2> /dev/null"
    done
    return 0
}

########################################################################################################################
# installs kit to workers
########################################################################################################################
kit_install() {
  for NODE in ${TPCH_KIT_WORKERS[*]}; do
        echo "Installing kit on $NODE."
        rsync -aqvzhe ssh --delete              \
            --exclude='datasets/*'              \
            --exclude="$TPCH_HOME/dbgen/*tbl*"  \
            $TPCH_KIT_HOME/ $USER@$NODE:$TPCH_KIT_HOME/ &
    done
    return 0
}

########################################################################################################################
# uninstalls kit from workers
########################################################################################################################
kit_uninstall(){
  for NODE in ${TPCH_KIT_WORKERS[*]}; do
        echo "Uninstalling kit from $NODE"
        ssh -n  $USER@$NODE "rm -rf $TPCH_KIT_HOME"
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

RUN="kit_$RUN"
$RUN

