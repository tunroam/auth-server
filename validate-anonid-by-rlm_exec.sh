#!/bin/bash

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
  echo "valid_anonid"
else
  echo "$result_msg"
fi
exit $result_code
