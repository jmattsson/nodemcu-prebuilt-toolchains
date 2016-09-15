default: esp32 lx106

TOPDIR:=$(abspath $(dir $(lastword $(MAKEFILE_LIST))))

Q?=@

# It's unfortunately not possible to have the two toolchains share a top dir,
# as they step on each others toes in some areas (e.g. linker scripts).
#
.PHONY: esp32 esp8266
esp32: esp32/bin/xtensa-esp32-elf-gcc
lx106:  esp8266/bin/xtensa-lx106-elf-gcc

build/lx106/Makefile:
	$Qcd build && git clone --recursive https://github.com/pfalcon/esp-open-sdk.git lx106

esp8266/bin/xtensa-lx106-elf-gcc: build/lx106/Makefile
	$Qecho CT_STATIC_TOOLCHAIN=y >> $(dir $<)/crosstool-config-overrides
	$Qcd "$(dir $<)" && $(MAKE) STANDALONE=n TOOLCHAIN="$(TOPDIR)/esp8266" toolchain libhal


build/esp32/bootstrap:
	$Qcd build && git clone -b xtensa-1.22.x https://github.com/espressif/crosstool-NG.git esp32
	@touch $@

build/esp32/Makefile: build/esp32/bootstrap
	$Qcd "$(dir $@)" && ./bootstrap && ./configure --prefix="`pwd`"

build/esp32/ct-ng: build/esp32/Makefile
	$Qcd "$(dir $@)" && $(MAKE) MAKELEVEL=0 && $(MAKE) MAKELEVEL=0 install

build/esp32/.config: build/esp32/ct-ng
	$Qcd "$(dir $@)" && ./ct-ng xtensa-esp32-elf
	$Qsed -i 's,^CT_PREFIX_DIR=.*$$,CT_PREFIX_DIR="$${CT_TOP_DIR}/../../esp32",' $@
	$Qecho CT_STATIC_TOOLCHAIN=y >> $@

esp32/bin/xtensa-esp32-elf-gcc: build/esp32/.config
	$Qcd "$(dir $<)" && ./ct-ng build


.PHONY:clean
clean:
	-rm -rf build/esp32 build/lx106

.SUFFIXES:
%: %,v
%: RCS/%,v
%: RCS/%
%: s.%
%: SCCS/s.%

