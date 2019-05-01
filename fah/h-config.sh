#!/usr/bin/env bash

local team=`head -n 1 <<< "$CUSTOM_URL"`

echo "<config>" > $CUSTOM_CONFIG_FILENAME
echo "  <!-- Client Control -->" >> $CUSTOM_CONFIG_FILENAME
echo "  <fold-anon v='true'/>" >> $CUSTOM_CONFIG_FILENAME

echo "  <!-- Slot Control -->" >> $CUSTOM_CONFIG_FILENAME
echo "  <power v='full'/>" >> $CUSTOM_CONFIG_FILENAME

echo "  <!-- User Information -->" >> $CUSTOM_CONFIG_FILENAME

[[ ! -z $team ]] && echo "  <team v='$team'/>" >> $CUSTOM_CONFIG_FILENAME
[[ ! -z ${CUSTOM_TEMPLATE} ]] && echo "  <user v='${CUSTOM_TEMPLATE}'/>" >> $CUSTOM_CONFIG_FILENAME
[[ ! -z $CUSTOM_PASS ]] && echo "  <passkey v='$CUSTOM_PASS'/>" >> $CUSTOM_CONFIG_FILENAME

echo "  <!-- Folding Slots -->" >> $CUSTOM_CONFIG_FILENAME
if [[ ! -z $CUSTOM_USER_CONFIG ]]; then
  while read -r line; do
    [[ -z $line ]] && continue
    echo $line >> $CUSTOM_CONFIG_FILENAME
  done <<< "$CUSTOM_USER_CONFIG"
else
  #echo "  <slot id='0' type='CPU'/>" >> $CUSTOM_CONFIG_FILENAME

  j=0

  for (( i=0; i < $(gpu-detect NVIDIA); i++ )); do
    echo "  <slot id='$j' type='GPU'/>" >> $CUSTOM_CONFIG_FILENAME
    ((j++))
  done

  for (( i=0; i < $(gpu-detect AMD); i++ )); do
    echo "  <slot id='$j' type='GPU'/>" >> $CUSTOM_CONFIG_FILENAME
    ((j++))
  done
fi

echo "</config>" >> $CUSTOM_CONFIG_FILENAME