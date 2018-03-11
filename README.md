# Taskidy

Taskidy is a task runner written in bash. It's a replacement for what I generally use `make` for nowadays.

## Installation

### Requirements

* Linux
* Bash 4.x

`$ wget https://raw.githubusercontent.com/kdar/taskidy/master/taskidy.sh`

## Usage

Put this in a file (like `taskfile`)

```bash
#!/usr/bin/env bash

cd "$( dirname "${BASH_SOURCE[0]}" )" || exit
source ./taskidy.sh

# short description
# Some long
# description
task:hello() {  
  echo "YAY!" "$@"
}

# the default task
# The task that is execute if no task is
# provided on the CLI.
task:default() {
  echo "default" "$@"
}
```

```bash
./taskfile hello
```

```bash
./taskfile help  
Usage:
  ./taskfile <task> [args...]

Available tasks:
  hello      short description
  default    the default task  

Use ./taskfile help [task] for more information about a task.
```

## Public functions

### taskidy.print_help [task]

Prints the help as if you were to type `./taskfile help`.

### taskidy.timestamp_depend <inputs> <outputs>

This allows you to have dependencies like make. It takes an array of inputs and an array of outputs, and if any inputs' modified timestamp is later than any of the outputs' modified timestamp, it returns 0 (true).

```
task:depend-on() {
  local -a inputs=(testdata/depend/src/*.{c,h})
  local -a outputs=(testdata/depend/dist/main)
  if taskidy.timestamp_depend inputs outputs; then
    echo "Recompiling..."
    gcc -o testdata/depend/dist/main testdata/depend/src/main.c
    echo "Done"
  fi
}
```

### taskidy.parallel [func...]

Run functions/cmds in parallel, returning 0 if successful and >0 for how many of them failed.

```
parallel1() {
  sleep 2
  echo "parallel1: done"
}

parallel2() {
  sleep 3
  echo "parallel2: done"
  # return 1
}

task:parallel() {
  if taskidy.parallel parallel1 parallel2; then
    echo "All exited successfully"
  else
    echo "There was an error!"
  fi
}
```

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate.

## License

[MIT](https://choosealicense.com/licenses/mit/)
