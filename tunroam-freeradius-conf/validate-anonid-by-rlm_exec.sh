#!/bin/bash

# This is a wrapper around our Python3 script.
# We use rlm_exec to call this bash script.

# History:
# Initially we used rlm_python(2) as a wrapper
# to call our Python3 script, but due to errors
# we use rlm_exec now.
# https://stackoverflow.com/questions/45371531/failed-to-link-to-module-rlm-python-rlm-python-so
# Rlm_exec is slower, but since we test ports to
# an external VPN in our Python3 script,
# we reason that the slowness of rlm_exec has no impact.
# src: https://networkradius.com/doc/current/raddb/mods-available/exec.html

if [ -z "$TUNROAM_EXEC_DEBUG_PATH" ]; then
  TUNROAM_EXEC_DEBUG_PATH=/dev/null
fi

if [ -z "$1" ]; then
  echo "USAGE: $0 User-Name"
  exit 1
fi

result_msg=`/usr/local/bin/validate_anonid.py "$1"`
result_code=$?

echo "$result_msg" >> $TUNROAM_EXEC_DEBUG_PATH

if [[ "$result_code" == "0" ]]; then
  # Valid anonymous identity in EAP
  # and matching VPN endpoint is listening
  echo "valid_anonid"
else
  echo "$result_msg"
fi
exit $result_code
