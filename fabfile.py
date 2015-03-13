import json
from fabric.api import env, run, path

tables_options = {
    'lineitem' : 'L',
    'customers' : 'c',
    'nation' : 'n',
    'orders' : 'O',
    'parts' : 'P',
    'region' : 'r',
    'suppliers' : 's',
    'partsupp' : 'S'
}

def dbgen(sf, table):
    if not table:
       table = tables_options[table]
    chunks = len(env.hosts)
    if chunks > 0:
        chunk = env.hosts.index(env.host)
    else: chunk = 0
    print "Scale Factor = ", sf
    print "Chunks = ", chunks
    print "Chunk = ", chunk
    print "Table = ", table
    with path("~/tpch-kit/tpch/tpch_2_17_0/dbgen"):
        dbgen_cmd = "./dbgen -f -s % -C % -S % -T %" % (sf, chunks, chunk, table)
        run("dbgen -h")


def install():
    with path(" cd ~/"):
        run("git clone https://github.com/alexpap/tpch-kit.git")

