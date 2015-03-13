import json
from fabric.api import env, run, parallel, task

def dbgen(sf=1):
    chunks = len(env.hosts)
    chunk = env.hosts.index(env.host)
    print "Scale Factor = ", sf
    print "Chunks = ", chunks
    print "Chunk = ", chunk


