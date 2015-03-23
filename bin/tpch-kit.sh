#!/usr/bin/env bash
#
# install | update | uninstall
# dbgen | clean | list

TPCH_KIT_HOME="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../" && pwd )"
TPCH_HOME="$TPCH_KIT_HOME/tpch/tpch_2_17_0"
SCALE_FACTOR=1
TABLE='n'
CHUNKS=2
CHUNK=1

function gen() {
    # dbgen
    cd "$TPCH_HOME/dbgen"
    if [[ $CHUNKS < 2 ]]; then
        ./dbgen -f -q -s "$SCALE_FACTOR" -T "$TABLE"
    else
        ./dbgen -f -q -s "$SCALE_FACTOR" -T "$TABLE" -C "$CHUNKS" -S "$CHUNK"
    fi

    # compress
    mv -f *.tbl* $TPCH_KIT_HOME/datasets/
    cd  $TPCH_KIT_HOME/datasets/
    gzip -f *.tbl*

    return 0
}

function clean() {
    rm $TPCH_KIT_HOME/datasets/*
}

function list() {
    cd  $TPCH_KIT_HOME/datasets/
    ls -lh
}


function install() {

    for NODE in $TPCH_KIT_WORKERS; do
        ssh $USER@$NODE << EOF
            if [ ! -d $TPCH_KIT_HOME ]; then
                git clone https://github.com/alexpap/tpch-kit.git
            else
                cd $TPCH_KIT_HOME
                git pull
            fi
        EOF
    done
}

function uninstall(){
    rm -rf $TPCH_KIT_HOME
}

clean
gen
list
