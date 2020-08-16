#!/bin/sh

if [ -z "$TUNROAM_EXEC_DEBUG_PATH" ]; then
  TUNROAM_EXEC_DEBUG_PATH=/dev/null
fi

if [ -z "$1" ]; then
  echo "USAGE: $0 User-Name"
  exit 1
fi

/usr/local/bin/validate_anonid.py "$1" >> $TUNROAM_EXEC_DEBUG_PATH
exit $?
