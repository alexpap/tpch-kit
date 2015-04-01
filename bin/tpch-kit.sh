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
# Generates all tpch tables based on sf, chunk, chunks
# moves and compress generated tables
kit_dbgen() {
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
    return 0
}

####
# clean generated tables
function kit_clean() {
    rm $TPCH_KIT_HOME/datasets/*tbl*
    rm $TPCH_HOME/dbgen/*tbl*
    return 0
}

####
# list generated tables
function kit_list() {
    cd  $TPCH_KIT_HOME/datasets/
    ls -lh
}

####
# installs kit to workers
function kit_install() {
    for NODE in $TPCH_KIT_WORKERS; do
    rsync -aqvzhe ssh --delete    \
            --exclude='datasets/*'                          \
            --exclude='$TPCH_HOME/dbgen/*tbl*'                  \
            $TPCH_KIT_HOME/ $USER@$TPCH_KIT_MASTER:$TPCH_KIT_HOME/ &
    done
    return 0
}

#####
# uninstalls kit from workers
function kit_uninstall(){
    rm -rf $TPCH_KIT_HOME
    return 0
}

kit_install
