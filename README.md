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
  default    the default task
  hello      short description

Use ./taskfile help [task] for more information about a task.
```

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate.

## License

[MIT](https://choosealicense.com/licenses/mit/)
