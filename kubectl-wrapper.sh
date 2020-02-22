#!/bin/bash
set -e
set -x

export KUBECONFIG=${KUBE_CONFIG}

if [ -n "$RESOURCE_DATA" ]
then
  data=$(mktemp)
  echo "${RESOURCE_DATA}" > "${data}"
  cat ${data}
  kubectl apply -f "${data}"
  ret=$?
  #rm -f -- "${data}"
elif [ -n "$COMMAND" ]
then
  if [ -n "$SLEEP" ]
  then
    sleep "$SLEEP"
  fi
  kubectl "$COMMAND"
  ret=$?
else
  kubectl apply -f "$1"
  ret=$?
fi
exit $ret