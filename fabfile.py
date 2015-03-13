import json
from fabric.api import env, run, parallel, task

# -T c   -- generate cutomers ONLY
# -T l   -- generate nation/region ONLY
# -T L   -- generate lineitem ONLY
# -T n   -- generate nation ONLY
# -T o   -- generate orders/lineitem ONLY
# -T O   -- generate orders ONLY
# -T p   -- generate parts/partsupp ONLY
# -T P   -- generate parts ONLY
# -T r   -- generate region ONLY
# -T s   -- generate suppliers ONLY
# -T S   -- generate partsupp ONLY

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

def dbgen(sf=1, table=""):
    table = tables_options[table]
    chunks = len(env.hosts)
    if chunks > 0:
        chunk = env.hosts.index(env.host)

    print "Scale Factor = ", sf
    print "Chunks = ", chunks
    print "Chunk = ", chunk
    print "Table = ", table


