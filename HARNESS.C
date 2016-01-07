//----------------------------------------------------------------------------
// CPSC 355 - Protected Mode Assembly Program Harness
// Author:  Sonny Chan
// Date:    May 16, 2001
//
// Uses DJGPP/DPMI to provide a protected mode interface the user's assembly
// language program.
//----------------------------------------------------------------------------

#include <go32.h>

// function contained within the assembly language module, portal.asm
extern void go(unsigned long selector, unsigned long buffer, int argc, char **argv);

int main(int argc, char **argv)
{
   // call the ASM module with real mode addressing info and command line
   go(_dos_ds, __tb, argc, argv);
   
   return 0;
}
