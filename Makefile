DIR_RISCV64	:= $(wildcard ~/RISCV64-A)
DIR_WORKING	:= $(DIR_RISCV64)/working

CROSS_RISCV64	:= /home/RV64A/tools/riscv 
CROSS_COMPILE	:= $(CROSS_RISCV64)/bin/riscv64-unknown-linux-gnu-
CROSS_PREFIX	:= riscv64-unknown-linux-gnu-

BUSYBOX_BUILDLOG:= $(DIR_WORKING)/busybox-build.log
BUSYBOX_CONFIG	:= $(DIR_RISCV64)/config/busybox_1.26_defconfig

QEMU_GITREPO	:= /pub/git/riscv-qemu.git
QEMU_TARGETS	:= riscv64-softmmu,riscv64-linux-user
QEMU_BUILDLOG	:= $(DIR_WORKING)/qemu-build.log
QEMU_TRACELOG	:= $(DIR_WORKING)/qemu-run.log

RISCV_PK_REPO	:= /pub/git/riscv-pk.git
RISCV_PK_COMMIT	:= f73dee6f2cc37cafc4b6949dac9ac2d71cf84d10

STRACE_REPO	:= /home/RV64A/pub/strace.git
STRACE_COMMIT	:= 4b69c4736cb9b44e0bd7bef16f7f8602b5d2f113

TOOLCHAIN_REPO	:= https://github.com/riscv/riscv-gnu-toolchain.git
TOOLCHAIN_COMMIT:= 7e4859465ef8b38fb8369971c1449270ae7a19a1

PATCHES_DIR     := $(DIR_RISCV64)/patches

PATH		:= $(CROSS_RISCV64)/bin:$(PATH)

include Makefile.linux

qemu-new:
	@test -d $(DIR_WORKING)/riscv-qemu || mkdir -p $(DIR_WORKING)/riscv-qemu
	@echo "Remove old qemu repo ..."
	@rm -rf $(DIR_WORKING)/qemu
	@cd $(DIR_WORKING); git clone $(QEMU_GITREPO) qemu
	@cd $(DIR_WORKING)/qemu; git branch riscv64; git checkout riscv64

qemu-make:
	@echo "Configure qemu ..."
	@cd $(DIR_WORKING)/qemu; ./configure			\
		--target-list=$(QEMU_TARGETS)			\
		--enable-debug					\
		--disable-sdl					\
		--interp-prefix=$(DIR_GNU_RISCV)		\
		--prefix=$(DIR_WORKING)/riscv-qemu		\
		>> $(QEMU_BUILDLOG) 2>&1
	@echo "Make qemu and make install ..."
	@make -C $(DIR_WORKING)/qemu -j4 >> $(QEMU_BUILDLOG) 2>&1
	@make -C $(DIR_WORKING)/qemu install >> $(QEMU_BUILDLOG) 2>&1

toolchain-new:
	@echo "Remove old toolchain ..."
	@test -d $(DIR_WORKING) || mkdir -p $(DIR_WORKING)
	@rm -rf $(DIR_WORKING)/riscv-toolchain
	@cd $(DIR_WORKING); git clone $(TOOLCHAIN_REPO) riscv-toolchain
	@cd $(DIR_WORKING)/riscv-toolchain;			\
		git checkout $(TOOLCHAIN_COMMIT) -b priv-1.9;	\
		git submodule update --init --recursive

toolchain-make:
	@echo "Build gnu toolchain ..."
	@cd $(DIR_WORKING)/riscv-toolchain;			\
		./configure --prefix=$(CROSS_RISCV64);			\
		make -j4 linux

busybox:
	@echo "Remove old busybox ..."
	@test -d $(DIR_WORKING) || mkdir -p $(DIR_WORKING)
	@rm -rf $(DIR_WORKING)/busybox*
	@cd $(DIR_WORKING); cp -R $(DIR_RISCV64)/busybox-1.25.1 ./busybox
	@echo "Configure and make busybox ..."
	@cp $(BUSYBOX_CONFIG) $(DIR_WORKING)/busybox/.config
	@yes "" | make -C $(DIR_WORKING)/busybox oldconfig > $(BUSYBOX_BUILDLOG) 2>&1
	@make -C $(DIR_WORKING)/busybox -j4 >> $(BUSYBOX_BUILDLOG) 2>&1

riscv-pk-new:
	@echo "Remove old riscv-pk repo ..."
	@test -d $(DIR_WORKING) || mkdir -p $(DIR_WORKING)
	@rm -rf $(DIR_WORKING)/riscv-pk
	@cd $(DIR_WORKING); git clone $(RISCV_PK_REPO) riscv-pk
	@cd $(DIR_WORKING)/riscv-pk; 				\
		git checkout $(RISCV_PK_COMMIT) -b priv-1.9

riscv-pk-make:
	@echo "Set up build directory ..."
	@rm -rf $(DIR_WORKING)/riscv-pk/build
	@mkdir $(DIR_WORKING)/riscv-pk/build
	@cd $(DIR_WORKING)/riscv-pk/build;									\
		../configure --host=riscv64-unknown-linux-gnu --with-payload=$(DIR_WORKING)/linux/vmlinux;	\
		make -j4

strace-new:
	@echo "Remove old strace repo ..."
	@test -d $(DIR_WORKING) || mkdir -p $(DIR_WORKING)
	@rm -rf $(DIR_WORKING)/strace
	@cd $(DIR_WORKING); git clone $(STRACE_REPO) strace
	@cd $(DIR_WORKING)/strace; 				\	
		git checkout $(STRACE_COMMIT) -b riscv-strace;	\
		git apply $(PATCHES_DIR)/strace-riscv-patch.txt;\
		git add -A;					\
		git commit -m "strace port to riscv-linux"	\

strace-make:
	@echo "Build strace ..."
	@cd $(DIR_WORKING)/strace;				\
		./bootstrap;					\
		./configure --host=riscv64-unknown-linux-gnu;	\
		make CFLAGS=-static -j4

helloworld-make:
	@echo "Compile helloworld ..."
	@test -d $(DIR_WORKING) || mkdir -p $(DIR_WORKING)
	@rm -rf $(DIR_WORKING)/helloworld
	@cp -R $(DIR_RISCV64)/helloworld $(DIR_WORKING)
	@cd $(DIR_WORKING)/helloworld;				\
		$(CROSS_PREFIX)gcc -static helloworld.c -o helloworld

qemu-softmmu:
	@echo "Start softmmu mode ..."
	@rm -rf $(QEMU_TRACELOG)
	@$(DIR_WORKING)/riscv-qemu/bin/qemu-system-riscv64	\
		-kernel $(DIR_WORKING)/riscv-pk/build/bbl	\
		-nographic					\
		2>$(QEMU_TRACELOG)

qemu-linux-user:
	@echo "Start linux-user mode ..."
	@rm -rf $(QEMU_TRACELOG)
	@echo "Run helloworld program ..."
	@cd $(DIR_WORKING);					\
		./riscv-qemu/bin/qemu-riscv64 ./helloworld/helloworld	\
		2>$(QEMU_TRACELOG) 			
	@echo "Run strace helloworld ..."
	@$(DIR_WORKING)/riscv-qemu/bin/qemu-riscv64             \
		-strace						\
		$(DIR_WORKING)/helloworld/helloworld		\
