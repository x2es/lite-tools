#!/bin/bash

#
# Keeps empty dirs by adding .keep file. Useful for git.
#

SCRIPT=$0

if [ -z $1 ]; then
  ROOT_DIR=.
else
  ROOT_DIR=$1
fi

if [ "${ACT}" == "yes" ]; then
  find ${ROOT_DIR} -type d -empty -not -path "./.git*" -exec echo "touching {}/.keep" \; -exec touch {}/.keep \;
  echo "Changes applied!"
else
  echo "NO: ${ROOT_DIR}"
  find ${ROOT_DIR} -type d -empty -not -path "./.git*" -exec echo "touching {}/.keep" \;
  echo
  echo "This is dummy output for previw."
  echo "Use command 'ACT=yes ${SCRIPT} [<params>]' for apply changes."
fi

#find ${ROOT_DIR} -type d -empty -not -path "./.git*" -exec echo "touching {}/.keep" \; -exec touch {}/.keep \;
