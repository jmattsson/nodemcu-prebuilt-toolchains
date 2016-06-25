default: esp108 lx106

TOPDIR:=$(abspath $(dir $(lastword $(MAKEFILE_LIST))))

Q?=@

# It's unfortunately not possible to have the two toolchains share a top dir,
# as they step on each others toes in some areas (e.g. linker scripts).
#
.PHONY: esp32 esp8266
esp108: esp32/bin/xtensa-esp108-elf-gcc
lx106:  esp8266/bin/xtensa-lx106-elf-gcc

build/lx106/Makefile:
	$Qcd build && git clone --recursive https://github.com/pfalcon/esp-open-sdk.git lx106

esp8266/bin/xtensa-lx106-elf-gcc: build/lx106/Makefile
	$Qecho CT_STATIC_TOOLCHAIN=y >> $(dir $<)/crosstool-config-overrides
	$Qcd "$(dir $<)" && $(MAKE) STANDALONE=n TOOLCHAIN="$(TOPDIR)/esp8266" toolchain libhal


build/esp108/bootstrap:
	$Qcd build && git clone -b esp108-1.21.0 http://github.com/jcmvbkbc/crosstool-NG.git esp108
	@touch $@

build/esp108/Makefile: build/esp108/bootstrap
	$Qcd "$(dir $@)" && ./bootstrap && ./configure --prefix="`pwd`"

build/esp108/ct-ng: build/esp108/Makefile
	$Qcd "$(dir $@)" && $(MAKE) MAKELEVEL=0 && $(MAKE) MAKELEVEL=0 install

build/esp108/.config: build/esp108/ct-ng
	$Qcd "$(dir $@)" && ./ct-ng xtensa-esp108-elf
	$Qsed -i 's,^CT_PREFIX_DIR=.*$$,CT_PREFIX_DIR="$${CT_TOP_DIR}/../../esp32",' $@
	$Qecho CT_STATIC_TOOLCHAIN=y >> $@

esp32/bin/xtensa-esp108-elf-gcc: build/esp108/.config
	$Qcd "$(dir $<)" && ./ct-ng build


.PHONY:clean
clean:
	-rm -rf build/esp108 build/lx106

.SUFFIXES:
%: %,v
%: RCS/%,v
%: RCS/%
%: s.%
%: SCCS/s.%

