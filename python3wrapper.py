#! /usr/bin/env python

# This script is an ugly hack
# the latest release of freeradius contains python2
# not python3. It also does not allow us to update
# the incoming request.
# Therefore we do not have not tried to get IPv6
# or proxying up and running.
# Let's implement that when Python3 is working
# in the new release of freeradius.


import radiusd
import sys

# for some reason, the python in FreeRADIUS is missing subprocess
#import subprocess
#import commands
# thus we use a workaround, found here:
# https://docs.openstack.org/bandit/1.4.0/plugins/start_process_with_a_shell.html
import os


def authorize(p):
  print "Entering Python2 authorize"
  print p
  reply = ( ('Reply-Message', 'reply from freeradius to hostapd'), )
  config = ( ('Cleartext-Password', 'password'), ) # The hardcode password as in spec.

  for t in p:
    if t[0] == 'User-Name':
      anonid = t[1]
  if not anonid:
    return radiusd.RLM_MODULE_FAIL

  cmd = "validate_anonid.py " + anonid
#  proc = subprocess.Popen(cmd, stdout=PIPE, shell=True)
#  stdout = proc.communicate()[0]
#  proc.stdout.close()
  stdout = os.popen(cmd).read()
  print stdout
  if "error" in stdout.lower():
    reply = ( ('Reply-Message', stdout), )
    exitcode = radiusd.RLM_MODULE_REJECTED
  else:
    exitcode = radiusd.RLM_MODULE_OK

  # TODO The following source:
  # https://github.com/FreeRADIUS/freeradius-server/blob/v3.0.x/src/modules/rlm_python/example.py#L79
  # tells us that we can't update the request in this old version
  # therefore we do not support proxying for now
  return exitcode, reply, config


# https://github.com/FreeRADIUS/freeradius-server/blob/v3.0.x/src/modules/rlm_python/prepaid.py
# https://github.com/FreeRADIUS/freeradius-server/blob/v3.0.x/raddb/sites-available/default#L279
# https://serverfault.com/questions/611639/using-python-in-freeradius
# https://github.com/FreeRADIUS/freeradius-server/blob/dc886b3208a405f736441eead7e537fc505e6cc2/raddb/mods-available/always#L29
