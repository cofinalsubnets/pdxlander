pd_sdk=$(PLAYDATE_SDK_PATH)
pd_src=$(wildcard *.c)
pd_gcc=arm-none-eabi-gcc
pd_cc=$(pd_gcc) -g3
pd_as=$(pd_gcc) -x assembler-with-cpp
pd_opt=-O2 -falign-functions=16 -fomit-frame-pointer
pd_lds=$(patsubst ~%,$(HOME)%,$(pd_sdk)/C_API/buildsupport/link_map.ld)
pd_fpu=-mfloat-abi=hard -mfpu=fpv5-sp-d16 -D__FPU_USED=1
pd_incdir=$(patsubst %,-I %, $(pd_sdk)/C_API)
pd_defs =-DTARGET_PLAYDATE=1 -DTARGET_EXTENSION=1 -Dg_tco=0
pd_src +=$(pd_sdk)/C_API/buildsupport/setup.c
pd_o=$(pd_src:.c=.o)
pd_mcflags=-mthumb -mcpu=cortex-m7 $(pd_fpu)
pd_cpflags=\
	$(pd_mcflags) $(pd_opt) $(pd_defs)\
 	-gdwarf-2 -Wall -Wno-unused -Wstrict-prototypes -Wno-unknown-pragmas\
 	-fverbose-asm -Wdouble-promotion -mword-relocations -fno-common\
  -ffunction-sections -fdata-sections -Wa,-ahlms=$(notdir $(<:.c=.lst))
pd_ldflags=\
	-nostartfiles $(pd_mcflags) -T$(pd_lds)\
 	-Wl,-Map=pdex.map,--cref,--gc-sections,--no-warn-mismatch,--emit-relocs
pd_asflags=$(pd_mcflags) $(pd_opt) -g3 -gdwarf-2 -Wa,-amhls=$(<:.s=.lst)\
  -D__HEAP_SIZE=8388208 \
 	-D__STACK_SIZE=4194304

n=pdxlander
$n.pdx: Source/pdex.elf Source/pdex.so
	$(pd_sdk)/bin/pdc -sdkpath $(pd_sdk) Source $@

%.o : %.c
	mkdir -p $(dir $@)
	$(pd_cc) -c $(pd_cpflags) $(pd_incdir) $< -o $@

Source/pdex.elf: $(pd_o) $(pd_lds)
	mkdir -p $(dir $@)
	$(pd_cc) $(pd_o) $(pd_ldflags) -o $@

Source/pdex.so: $(pd_src)
	mkdir -p $(dir $@)
	gcc -g -shared -fPIC -lm -Dg_tco=0 -DTARGET_SIMULATOR=1 -DTARGET_EXTENSION=1 $(pd_incdir) -o $@ $(pd_src)

.PHONY: clean
clean:
	rm -rf `git check-ignore * Source/*`
