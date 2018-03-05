#!/usr/bin/env bash

if [ ".$0" == ".$BASH_SOURCE" ]; then
  echo "Please source this script instead of running it."
  exit
fi

TASK_FILE="${BASH_SOURCE[1]}"
declare -a tasksh_args=($@)
declare -a TASK_FILE_SRC

IFS=', ' read -r -a colors <<< $(echo -e '\e[30m,\e[31m,\e[32m,\e[33m,\e[34m,\e[35m,\e[36m,\e[37m,\e[90m,\e[91m,\e[92m,\e[93m,\e[94m,\e[95m,\e[96m,\e[97m,\e[0m')
fg_black=${colors[0]}
fg_red=${colors[1]}
fg_green=${colors[2]}
fg_yellow=${colors[3]}
fg_blue=${colors[4]}
fg_purple=${colors[5]}
fg_cyan=${colors[6]}
fg_light_gray=${colors[7]}
fg_gray=${colors[8]}
fg_light_red=${colors[9]}
fg_light_green=${colors[10]}
fg_light_yellow=${colors[11]}
fg_light_blue=${colors[12]}
fg_light_purple=${colors[13]}
fg_light_cyan=${colors[14]}
fg_white=${colors[15]}
color_reset=${colors[16]}

trap '[[ ${?} -eq 0 ]] && tasksh.init' EXIT

tasksh.is_defined() {
  hash "${@}" 2> /dev/null
}

# tasksh.print_tasks() {
#   local SAVEIFS=$IFS
#   IFS=$'\n'
#   for x in $(declare -F); do
#     if [[ "$x" == "declare -f task:"* ]]; then 
#       echo ${x:16}
#     fi
#   done
#   IFS=$SAVEIFS
# }

tasksh.extract_help() {
  if [ $# -eq 0 ]; then 
    echo "usage: tasksh.extract_help <return var> <function>"
    return
  fi

  if ! tasksh.is_defined $2; then    
    return 1
  fi

  if [ ${#TASK_FILE_SRC} -eq 0 ]; then
    readarray -t TASK_FILE_SRC < "$TASK_FILE"
  fi

  declare -n var=$1

  shopt -s extdebug
  IFS=', ' read -r -a func_info <<< "$(declare -F $2)"
  shopt -u extdebug
  
  var[0]=""
  var[1]=""

  local i=$(expr ${func_info[1]} - 2)
  while [ $i -gt 0 ]; do
    if [[ ${TASK_FILE_SRC[$i]} == \#+* ]]; then
      var[1]="${TASK_FILE_SRC[$i]:3}\n${var[1]}"
    elif [[ ${TASK_FILE_SRC[$i]} == \#-* ]]; then
      var[0]="${TASK_FILE_SRC[$i]:3}\n${var[0]}"
    else
      break
    fi
    i=$(expr $i - 1)
  done
  
  if [ ${#var[0]} -gt 0 ]; then
    var[0]="${var[0]::-2}"
  fi
  if [ ${#var[1]} -gt 0 ]; then
    var[1]="${var[1]::-2}"
  fi
}

tasksh.print_help() {
  if [ ${#} -gt 0 ]; then
    tasksh.extract_help result task:$1
    if [ $? -ne 0 ]; then
      echo -e "${fg_red}Error${color_reset}: Unknown task: $1"
      tasksh.print_help
      return
    fi

    if [ ${#result[1]} -gt 0 ]; then
      echo -e "${result[1]}"
    else
      echo "No description"
    fi
    return
  fi

  echo "Usage:"
  echo "  ${TASK_FILE} <task> [args...]"
  echo ""

  echo "Available tasks:"
  local output=""
  local SAVEIFS=$IFS
  IFS=$'\n'
  for x in $(declare -F); do
    if [[ "$x" == "declare -f task:"* ]]; then 
      tasksh.extract_help result ${x:11}
      local newout=$(echo -e "${fg_yellow}${x:16}${color_reset} \035 ${result[0]}")
      output="$output\n$newout\n"
    fi
  done
  IFS=$SAVEIFS

  echo -ne $output |column -t -s $(echo -e "\035") | sed 's/^/  /'

  echo ""
  echo Use "${TASK_FILE} help [task]" for more information about a task.
}

tasksh.init() {
  trap - EXIT
  
  if [[ ${#tasksh_args[@]} -gt 0 ]]; then
    if tasksh.is_defined "task:${tasksh_args[0]}"; then
      task:${tasksh_args[0]} ${tasksh_args[@]:1}
    elif [ "${tasksh_args[0]}" = "help" ]; then
      tasksh.print_help ${tasksh_args[@]:1}
    else
      echo "Unknown task \"${tasksh_args[0]}\""
      tasksh.print_help
    fi

    return
  fi

  if tasksh.is_defined "task:default"; then
    task:default ${tasksh_args[@]}
  fi
}
