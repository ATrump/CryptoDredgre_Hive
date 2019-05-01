#!/usr/bin/env bash

cd `dirname $0`

[ -t 1 ] && . colors

. h-manifest.conf

[[ `ps aux | grep "./FAHClient" | grep -v grep | wc -l` != 0 ]] &&
  echo -e "${RED}$MINER_NAME miner is already running${NOCOLOR}" &&
  exit 1

CUSTOM_LOG_BASEDIR=`dirname "$CUSTOM_LOG_BASENAME"`
[[ ! -d $CUSTOM_LOG_BASEDIR ]] && mkdir -p $CUSTOM_LOG_BASEDIR

./FAHClient 2>&1 | tee $CUSTOM_LOG_BASENAME.log
