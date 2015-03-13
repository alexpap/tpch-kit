from fabric.api import env, run, cd

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
    # configure
    table_opt=tables_options[table]
    chunks = len(env.hosts)
    if chunks > 0:
        chunk = env.hosts.index(env.host) + 1
    else: chunk = 1
    # generate
    with cd("~/tpch-kit/tpch/tpch_2_17_0/dbgen"):
        dbgen_exec = "./dbgen -f -s {sf} -C {chunks} -S {chunk} " \
                     "-T {tbl_opt}".format(sf=sf, chunks=chunks, chunk=chunk, tbl_opt=table_opt)
        run(dbgen_exec)
        run("mkdir -p ~/tpch-kit-datasets")
        run("for file in $(ls *.tbl*); "
            "do "
            "mv $(basename $file) ~/tpch-kit-datasets/;"
            "done")
    # compress
    with cd("~/tpch-kit-datasets"):
        run("for file in $(ls *.tbl*); "
            "do "
            "mv $file ${file%.*};"
            "gzip ${file%.*};"
            "done")

def list():
    with cd("~/tpch-kit-datasets"):
        run("ls -lh .")

def clean():
    with cd("~/tpch-kit-datasets"):
        run("rm -f *")

def install():
    with cd("~/"):
        run("if [ ! -d tpch-kit ];"
            "then git clone https://github.com/alexpap/tpch-kit.git;"
            "else git pull;"
            "fi")

def uninstall():
    with cd("~/"):
        run("rm -rf tpch-kit tpch-kit-datasets")

