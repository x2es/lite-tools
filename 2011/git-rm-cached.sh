#!/bin/bash

#
# Performs git rm --cached for deleted files which marked as "deleted:" in git status output
#

SCRIPT=$0

if [ "${ACT}" == "yes" ]; then
  git status | grep deleted | cut -f 5 -d " " | while read file; do git rm --cached $file; done
  echo "Changes applied!"
else
  echo "This files will be removed by 'git rm --cached' command:"
  git status | grep deleted | cut -f 5 -d " " | while read file; do echo git rm --cached $file; done
  echo
  echo "This is dummy output for previw."
  echo "Use command 'ACT=yes ${SCRIPT}' for apply changes."
fi
