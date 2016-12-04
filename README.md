# RISCV64 QEMU GUIDE
## Attention
I recommend to build this project following the order of how this README is organized.
## gnu-toolchain
### Attention
This part will take a long time, both git clone and compilation. If you have a prebuilt one, I suggest you use it. For example, our team have one located in `/home/RV64A/tools/riscv`. To specify your own prebuilt one, change `CROSS_RISCV64`.

Also, if you want to specify another install location, change `CROSS_RISCV64`.

We use the commit here: [riscv-toolchain](https://github.com/riscv/riscv-gnu-toolchain/tree/7e4859465ef8b38fb8369971c1449270ae7a19a1)
### Prerequisite
`$ sudo apt-get install autoconf automake autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc`

### Clone and Make
1. `make toolchain-new`
2. `make toolchain-make`

## qemu
### Prerequisite
`$ sudo apt-get install gcc libc6-dev pkg-config bridge-utils uml-utilities zlib1g-dev libglib2.0-dev autoconf automake libtool libsdl1.2-dev`

### Clone and Make
1. `make qemu-new`
2. `make qemu-make`

## busybox
### Make
1. `make busybox`

## strace
### Attention
To specify another repo, change `RISCV_PK_REPO`
For more about the port of strace, see:
- [fedora-riscv](https://github.com/rwmjones/fedora-riscv)
- [Status of strace](https://groups.google.com/a/groups.riscv.org/forum/#!searchin/sw-dev/strace/sw-dev/5_rKwrRzT4I/T4Y1k0ImCwAJ)

### Clone and Make
1. `make strace-new`
2. `make strace-make`

## helloworld
### Make
1. `make helloworld-make`

## linux
### Attention
We use [riscv-linux priv-1.9](https://github.com/riscv/riscv-linux/tree/priv-1.9). For convenience, we provide a patch to update from v4.6 to it.

### Clone and Make
1. `make linux-new`
2. `make linux-initramfs`
3. `make linux-make`

## riscv-pk(bbl)
### Clone and Make
1. `make riscv-pk-new`
2. `make riscv-pk-make`

## softmmu mode
`make qemu-softmmu`

## linux-user mode
`make qemu-linux-user`
