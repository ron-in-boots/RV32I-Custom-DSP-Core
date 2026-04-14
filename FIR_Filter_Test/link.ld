OUTPUT_ARCH( "riscv" )
ENTRY( _start )

SECTIONS
{
  /* Force the code to start at address 0x00000000 */
  . = 0x00000000;
  
  .text : {
    *(.text)
  }
  
  /* Discard everything else we don't need for a simple bare-metal run */
  /DISCARD/ : {
    *(.data)
    *(.bss)
    *(.comment)
  }
}