#!/usr/bin/env bash

if [ ".$0" == ".${BASH_SOURCE[0]}" ]; then
  echo "Please source this script instead of running it."
  exit
fi

TASK_FILE="${BASH_SOURCE[1]}"
declare -a taskidy_args=("$@")
declare -a TASK_FILE_SRC

IFS=', ' read -r -a colors <<< "$(echo -e '\e[30m,\e[31m,\e[32m,\e[33m,\e[34m,\e[35m,\e[36m,\e[37m,\e[90m,\e[91m,\e[92m,\e[93m,\e[94m,\e[95m,\e[96m,\e[97m,\e[0m')"
declare -A taskidy_colors
export taskidy_colors
taskidy_colors[fg_black]=${colors[0]}
taskidy_colors[fg_red]=${colors[1]}
taskidy_colors[fg_green]=${colors[2]}
taskidy_colors[fg_yellow]=${colors[3]}
taskidy_colors[fg_blue]=${colors[4]}
taskidy_colors[fg_purple]=${colors[5]}
taskidy_colors[fg_cyan]=${colors[6]}
taskidy_colors[fg_light_gray]=${colors[7]}
taskidy_colors[fg_gray]=${colors[8]}
taskidy_colors[fg_light_red]=${colors[9]}
taskidy_colors[fg_light_green]=${colors[10]}
taskidy_colors[fg_light_yellow]=${colors[11]}
taskidy_colors[fg_light_blue]=${colors[12]}
taskidy_colors[fg_light_purple]=${colors[13]}
taskidy_colors[fg_light_cyan]=${colors[14]}
taskidy_colors[fg_white]=${colors[15]}
taskidy_colors[reset]=${colors[16]}

trap '[[ ${?} -eq 0 ]] && taskidy.__main' EXIT

taskidy.__is_defined() {
  hash "${@}" 2> /dev/null
}

# taskidy.print_tasks() {
#   local SAVEIFS=$IFS
#   IFS=$'\n'
#   for x in $(declare -F); do
#     if [[ "$x" == "declare -f task:"* ]]; then 
#       echo ${x:16}
#     fi
#   done
#   IFS=$SAVEIFS
# }

taskidy.__trim() {
  local var=$*
  # remove leading whitespace characters
  var="${var#"${var%%[![:space:]]*}"}"
  # remove trailing whitespace characters
  var="${var%"${var##*[![:space:]]}"}"   
  echo -n "$var"
}

taskidy.__extract_help() {
  if [ $# -eq 0 ]; then 
    echo "usage: taskidy.extract_help <return var> <function>"
    return
  fi

  if ! taskidy.__is_defined "$2"; then    
    return 1
  fi

  if [ ${#TASK_FILE_SRC} -eq 0 ]; then
    readarray -t TASK_FILE_SRC < "$TASK_FILE"
  fi

  local var
  declare -n var=$1

  shopt -s extdebug
  IFS=', ' read -r -a func_info <<< "$(declare -F "$2")"
  shopt -u extdebug
  
  var[0]=""
  var[1]=""

  local i
  i=$((func_info[1] - 2))
  local end=$i
  local found_comment=0
  while [ $i -gt 0 ]; do
    if [[ ${TASK_FILE_SRC[$i]} == \#* ]]; then
      found_comment=1
    else
      break
    fi
    i=$((i - 1))
  done

  if [ $found_comment -eq 0 ]; then
    return 1
  fi

  i=$((i + 1))
  local start=$i
  while [ $i -le $end ]; do
    if [ $i -eq $start ]; then
      var[0]="${TASK_FILE_SRC[$i]:2}"      
    else
      var[1]="${var[1]}\\n${TASK_FILE_SRC[$i]:2}"
    fi
    i=$((i + 1))
  done
  
  # var[0]=$(taskidy.__trim "${var[0]}")
  var[1]=$(taskidy.__trim "$(echo -e "${var[1]}")")
}

taskidy.__sorted_tasks() {
  local var
  declare -n var=$1

  local SAVEIFS=$IFS
  IFS=$'\n'
  for x in $(declare -F); do
    if [[ "$x" == "declare -f task:"* ]]; then
      shopt -s extdebug
      IFS=', ' read -r -a func_info <<< "$(declare -F "${x:11}")"
      shopt -u extdebug
      var[func_info[1]]="${x:16}"
    fi
  done
  IFS=$SAVEIFS
}

taskidy.print_help() {
  if [ ${#} -gt 0 ]; then
    declare -a result    
    if ! taskidy.__extract_help result "task:$1"; then
      echo -e "${taskidy_colors[fg_red]}Error${taskidy_colors[reset]}: Unknown task: $1"
      taskidy.print_help
      return
    fi

    if [ ${#result[1]} -gt 0 ]; then
      echo -e "${result[1]}"
    else
      echo "No description"
    fi

    # echo ""
    # echo "Usage:"
    # echo "  ${TASK_FILE} $1 [args...]"
    return
  fi

  echo "Usage:"
  echo "  ${TASK_FILE} <task> [args...]"
  echo ""

  echo "Available tasks:"
  local output=""
  declare -a result
  taskidy.__sorted_tasks result
  for x in "${result[@]}"; do
    taskidy.__extract_help result "${x}"
    local newout
    newout=$(echo -e "${taskidy_colors[fg_yellow]}${x}${taskidy_colors[reset]} \\035 ${result[0]}")
    output="$output\\n$newout\\n"
  done

  echo -ne "$output" |column -t -s "$(echo -e '\035')" | sed 's/^/  /'

  echo ""
  echo Use "${TASK_FILE} help [task]" for more information about a task.
}

taskidy.timestamp_depend() {
  local -n _inputs=$1
  local -n _outputs=$2
  local min_timestamp=0
  for i in "${_outputs[@]}"; do
    local cur
    cur=$(stat -c %Y "$i" 2>/dev/null || echo 0)
    if [ "$min_timestamp" -eq 0 ] || [ "$cur" -lt "$min_timestamp" ]; then
      min_timestamp=$cur
    fi
  done
  for i in "${_inputs[@]}"; do
    local cur
    cur=$(stat -c %Y "$i")
    if [ "$cur" -gt "$min_timestamp" ]; then
      return 0
    fi
  done
  return 1
}

taskidy.__completion() {
  if [ "${taskidy_args[0]}" = "--completions" ]; then
    # From: https://github.com/rbenv/rbenv
    shell="$(ps -p "$PPID" -o 'args=' 2>/dev/null || true)"
    shell="${shell%% *}"
    shell="${shell##-}"
    shell="${shell:-$SHELL}"
    shell="${shell##*/}"

    if [ "$shell" = "zsh" ]; then
      cat <<EOF
      _taskidy_completion() {
        local -a subcmds
        #subcmds=('hey:description for c command' 'there:description for d command')
        subcmds="\$($TASK_FILE --cmplt "\${word}")"
        subcmds=(\${(ps:\\n:)subcmds})
        _describe 'command' subcmds
      }

      compdef _taskidy_completion example

      # _taskidy_complete() {
      #   local word completions
      #   word="\$1"
      #   completions="\$($TASK_FILE --cmplt "\${word}")"
      #   reply=( "\${(ps:\\n:)completions}" )
      # }

      # compctl -f -K _taskidy_complete $TASK_FILE
EOF
    # elif [ "$shell" = "bash" ]; then
    #   echo "Bash"
    # fi

    exit 0
  elif [ "${taskidy_args[0]}" = "--cmplt" ]; then
    taskidy.__sorted_tasks result
    for x in "${result[@]}"; do
      echo "$x"
    done

    exit 0
  fi
}

taskidy.__main() {
  trap - EXIT

  taskidy.__completion
  
  if [[ ${#taskidy_args[@]} -gt 0 ]]; then
    if taskidy.__is_defined "task:${taskidy_args[0]}"; then
      "task:${taskidy_args[0]}" "${taskidy_args[@]:1}"
    elif [ "${taskidy_args[0]}" = "help" ]; then
      taskidy.print_help "${taskidy_args[@]:1}"
    else
      echo "Unknown task \"${taskidy_args[0]}\""
      taskidy.print_help
    fi

    return
  fi

  if taskidy.__is_defined "task:default"; then
    task:default "${taskidy_args[@]}"
  fi
}
