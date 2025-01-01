MEMORY
{
    BRAM (rwx) : ORIGIN = 0x0, LENGTH = 64K
}

SECTIONS
{
    .text : { *(.text*) } > BRAM
    .data : { *(.data*) } > BRAM
    .bss  : { *(.bss*)  } > BRAM
}

ENTRY(start)
