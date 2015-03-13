__author__ = 'alex'
from fabric.api import env, run

env.hosts = [
    '192.168.0.79',
    '192.168.0.99',
    '192.168.0.100'
    ]

def uptime():
    run('uptime')

