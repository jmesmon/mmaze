#! /bin/sh

: ${CROSS_COMPILER:=arm-none-eabi-}
: ${CC:=${CROSS_COMPILER}gcc}
: ${OBJCOPY:=${CROSS_COMPILER}objcopy}

: ${WARN_FLAGS:=-Wall -Wextra}
: ${CFLAGS:=-Os -flto -ggdb3 -fvar-tracking-assignments -fmerge-all-constants -ffast-math}
: ${LDFLAGS:=${CFLAGS} -fuse-linker-plugin -fwhole-program -Wl,--relax}
CPPFLAGS="-I. -Iinclude ${CPPFLAGS}"
CFLAGS="-std=gnu11 -Wno-main ${CFLAGS} ${WARN_FLAGS}"
LDFLAGS="-nostartfiles ${LDFLAGS}"

exec >build.ninja

cat <<EOF
cc = $CC
objcopy = $OBJCOPY
cflags = -Wall $CFLAGS
cppflags = $CPPFLAGS
ldflags = $LDFLAGS \$cflags

rule cc
  command = \$cc \$cppflags \$cflags -MMD -MF \$out.d -MT \$out  -c \$in -o \$out
  depfile = \$out.d

rule ccld
  command = \$cc \$ldflags -o \$out \$in

rule cpp_lds
  command = \$cc \$cppflags -g0 -E -MMD -MF \$out.d -MT \$out -P -o \$out \$in
  depfile = \$out.d
rule hex
  command = \$objcopy -O ihex \$in \$out
rule bin
  command = \$objcopy -O binary \$in \$out
EOF

to_out () {
  for i in "$@"; do
    printf "%s " ".build-$out/$i"
  done
}

to_obj () {
	for i in "$@"; do
		printf "%s " ".build-$out/$i.o"
	done
}

to_lds () {
  for i in "$@"; do
    printf "%s " ".build-$out/$(dirname "$i")/$(basename "$i" .S)"
  done
}

_ev () {
	eval echo "\${$1}"
}

bin () {
	out="$1"
	shift
	out_var="${out/./_}"

	for s in "$@"; do
		echo build $(to_obj "$s"): cc $s
		echo "  cflags = \$cflags $(_ev cflags_${out_var})"
		echo "  cppflags = \$cppflags $(_ev cppflags_${out_var})"
	done
	for i in ld/*.lds.S; do
	  echo "build $(to_lds "$i") : cpp_lds $i"
	  echo "  cflags = \$cflags $(_ev cflags_${out_var})"
	  echo "  cppflags = \$cppflags $(_ev cppflags_${out_var})"
	done

	cat <<EOF
build $out : ccld $(to_obj "$@") | $(to_lds ld/*.lds.S)
  ldflags = -L.build-$out/ld \$ldflags $(_ev ldflags_${out_var}) $(_ev cflags_${out_var})
build $out.hex : hex $out
build $out.bin : bin $out
default $out $out.hex $out.bin
EOF
}


cppflags_lm3s_elf="-DLM3S3748=1 -include config/lm3s.h"
cflags_lm3s_elf="-mcpu=cortex-m3 -mthumb"
ldflags_lm3s_elf="-T armv7m.lds"
bin lm3s.elf init_vector.c init.c lm3s/adc.c main.c

cppflags_main_elf="-include config/k20dx128vlh5.h"
cflags_main_elf="-mcpu=cortex-m4 -mthumb"
ldflags_main_elf="-T armv7m.lds"
bin main.elf init_vector.c init.c main_teensy.c

cppflags_flutter_elf="-include config/atsam3s1a.h"
cflags_flutter_elf="-mcpu=cortex-m3 -mthumb"
ldflags_flutter_elf="-T armv7m.lds"
bin flutter.elf init_vector.c init.c main_flutter.c


cat <<EOF
rule ninja_gen
  command = $0
  generator = yes
build build.ninja : ninja_gen $0
EOF
