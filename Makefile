default: esp32/bin/xtensa-esp108-elf-gcc

TOPDIR:=$(abspath $(dir $(lastword $(MAKEFILE_LIST))))

Q?=@

build/esp108/bootstrap:
	$Qcd build && git clone -b esp108-1.21.0 git://github.com/jcmvbkbc/crosstool-NG.git esp108
	@touch $@

build/esp108/Makefile: build/esp108/bootstrap
	$Qcd "$(dir $@)" && ./bootstrap && ./configure --prefix="`pwd`"

build/esp108/ct-ng: build/esp108/Makefile
	$Qcd "$(dir $@)" && $(MAKE) MAKELEVEL=0 && $(MAKE) MAKELEVEL=0 install

build/esp108/.config: build/esp108/ct-ng
	$Qcd "$(dir $@)" && ./ct-ng xtensa-esp108-elf
	$Qsed -i 's,^CT_PREFIX_DIR=.*$$,CT_PREFIX_DIR="$${CT_TOP_DIR}/../../local",' $@

esp32/bin/xtensa-esp108-elf-gcc: build/esp108/.config
	$Qcd "$(dir $<)" && ./ct-ng build


.PHONY:clean
clean:
	-rm -rf build/esp108

.SUFFIXES:
%: %,v
%: RCS/%,v
%: RCS/%
%: s.%
%: SCCS/s.%

