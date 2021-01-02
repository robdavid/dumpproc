Simple utility to create an unstructured memory dump of one or more Linux processes.
## Usage
```
Usage dumpproc [-o OUTPUT] [pids...]
    -o OUTPUT, --output OUTPUT       Send all output to specified file, - for stdout
    -q, --quiet                      Reduce output noise
    -h, --help                       Display this help

```

## Building on Ubuntu 20.04
### Install Crystal compiler
```
$ sudo snap install crystal --classic
$ sudo apt-get update -y
$ sudo apt-get install -y gcc pkg-config git tzdata \
                          libpcre3-dev libevent-dev libyaml-dev \
                          libgmp-dev libssl-dev libxml2-dev
```
### Build the executable
```
$ shards build
```
or 
```
$ shards build --release
```
For slightly faster runtime performance at the expense of longer build time.

This will create a binary in bin/dumpproc
### Install
Copy the binary to a location in the path, e.g.
```
$ sudo cp bin/dumpproc /usr/local/bin/
```
