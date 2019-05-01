#!/usr/bin/env bash

#######################
# Functions
#######################


get_cards_hashes(){
  local all_bus_num_array=(`echo "$gpu_detect_json" | jq -r '[ . | to_entries[] | select(.value) | .value.busid [0:2] ] | .[]'`)
  local t_temp=$(jq '.temp' <<< $gpu_stats)
  local t_fan=$(jq '.fan' <<< $gpu_stats)
  a_fan=
  a_temp=
  local failed_gpus=
  for (( i=0; i < `echo $slots | jq length`; i++ )); do
    local slot_id=`echo $slots | jq -r '.['$i'].id'`
#echo $slot_id
    [[ `echo $slots | jq -r '.['$i'].status'` != "RUNNING" ]] && failed_gpus+=`echo $slots | jq -r '.['$i'].description' | cut -f 2 -d ":"`" "
#echo $slots | jq -r '.['$i'].status'
    ppd=`echo $queue | jq -r 'to_entries[] | select(.value.slot=="'$slot_id'") | .value.ppd'`
#echo $ppd
    if [[ `echo $slots | jq -r '.['$i'].description' | cut -f 1 -d ":"` == "gpu" ]]; then
      local gpu_num=`echo $slots | jq -r '.['$i'].description' | cut -f 2 -d ":"`

      local bus_num=`echo $fah_info | jq -c 'to_entries[].value' | grep '"GPU '$gpu_num'"' | cut -f 2 -d "," | cut -f 1 -d " " | cut -f 2 -d ":"`
      for ((k = 0; k < ${#all_bus_num_array[@]}; k++)); do
        if [[ "$(( 0x${all_bus_num_array[$k]} ))" -eq "$bus_num" ]]; then
          a_fan+=$(jq -r .[$k] <<< $t_fan)" "
          a_temp+=$(jq -r .[$k] <<< $t_temp)" "
          break
        fi
      done
    else
      bus_num=$((40 + $i))
      a_fan+="0 "
      a_temp+="0 "
    fi

    local s_ppd=0
    for t_ppd in $ppd; do
      let "s_ppd = s_ppd + t_ppd"
    done
#echo $s_ppd
    hs+="$s_ppd "
    bus_numbers+="$bus_num "
    #khs=$(($khs + $ppd))
    let "khs = khs + s_ppd"
  done


  if [[ ! -z $failed_gpus ]]; then
    khs=0
    echo " Failed GPU(s) #: $failed_gpus"
  else
    #for i in $hs; do
    #  let "khs = khs + i"
    #done
    khs=`echo $khs | awk '{print $1/1000}'`
    #khs=$(($khs / 1000))
  fi
}

get_miner_uptime(){
  local a=0
  let a=`stat --format='%Y' $log_name`-`stat --format='%Y' $conf_name`
  echo $a
}

get_log_time_diff(){
  local a=0
  let a=`date +%s`-`stat --format='%Y' $log_name`
  echo $a
}

get_stats_json(){
  [[ uptime -lt 60 || ! -f $info_name ]] && echo 'info' | nc -w $API_TIMEOUT localhost ${MINER_API_PORT} | tail -n +4 | head -n -2 | jq '.[2]' > $info_name

  slots=`echo 'slot-info' | nc -w $API_TIMEOUT localhost ${MINER_API_PORT} | tail -n +4 | head -n -2 | sed 's/False/"False"/' | sed 's/True/"True/'`
  queue=`echo 'queue-info' | nc -w $API_TIMEOUT localhost ${MINER_API_PORT} | tail -n +4 | head -n -2`
  fah_info=`cat $info_name`
}

#######################
# MAIN script body
#######################

. /hive/miners/custom/$CUSTOM_MINER/h-manifest.conf
local log_name="$CUSTOM_LOG_BASENAME.log"
local conf_name="/hive/miners/custom/$CUSTOM_MINER/config.xml"
local slot_name="/tmp/fah_slot_info"
local info_name="/tmp/fah_info"
local queue_name="/tmp/fah_queue"

khs=0
hs=""
bus_numbers=""

# Calc log freshness
local diffTime=$(get_log_time_diff)
local maxDelay=320

# If log is fresh the calc miner stats or set to null if not
if [ "$diffTime" -lt "$maxDelay" ]; then
  local uptime=$(get_miner_uptime) # miner uptime
  get_stats_json $uptime
  get_cards_hashes # hashes array
  local hs_units='hs' # hashes utits

# make JSON
  stats=$(jq -nc \
        --argjson hs "`echo ${hs[@]} | tr " " "\n" | jq -cs '.'`" \
        --arg hs_units "$hs_units" \
        --argjson temp "`echo ${a_temp[@]} | tr " " "\n" | jq -cs '.'`" \
        --argjson fan "`echo ${a_fan[@]} | tr " " "\n" | jq -cs '.'`" \
        --arg ver "$CUSTOM_VERSION" \
        --argjson bus_numbers "`echo ${bus_numbers[@]} | tr " " "\n" | jq -cs '.'`" \
        --arg algo "$CUSTOM_ALGO" \
        '{$hs, $hs_units, $bus_numbers, $temp, $fan, uptime: '$uptime', $ver, $algo}')
else
  stats=""
  khs=0
fi

# debug output
#echo hs:  $hs
#echo temp:  $temp
#echo fan:   $fan
#echo stats: $stats
#echo khs:   $khs
#echo uptime: $uptime
