//----------------------------------------------------------------------------
// CPSC 355 - Protected Mode Assembly Program Harness
// Author:  Sonny Chan
// Date:    May 16, 2001
//
// Uses DJGPP/DPMI to provide a protected mode interface the user's assembly
// language program.
//----------------------------------------------------------------------------

#include <go32.h>
#include <dpmi.h>
#include <stdio.h>

// extern symbols defined in mouse.asm
extern void myMouseInt(void);
extern int myMouseInt_Size;
extern int mouseVal;
extern int mouseCount;

// function contained within the assembly language module, portal.asm
extern void go(unsigned long selector, unsigned long buffer, int argc, char **argv);

// create seginfo structs
_go32_dpmi_seginfo OldHandler, NewHandler;

void mouse_int_install() {
   // retrieve the current (old) mouseboard handler
   _go32_dpmi_get_protected_mode_interrupt_vector(0x74, &OldHandler);

   // lock code and data from being paged
   _go32_dpmi_lock_code(myMouseInt, (long)myMouseInt_Size);
   _go32_dpmi_lock_data(&mouseVal, (long)sizeof(mouseVal));
   _go32_dpmi_lock_data(&mouseCount, (long)sizeof(mouseCount));
   // establish new seginfo struct
   NewHandler.pm_offset = (long)myMouseInt;
   NewHandler.pm_selector = _go32_my_cs();

   // allocate the IRET wrapper
   _go32_dpmi_allocate_iret_wrapper(&NewHandler);

   // install the new mouseboard ISR
   _go32_dpmi_set_protected_mode_interrupt_vector(0x74, &NewHandler);

   printf("new mouse ISR installed\n");
}

void mouse_int_remove() {
   // revert to old mouseboard ISR
   _go32_dpmi_set_protected_mode_interrupt_vector(0x74, &OldHandler);

   // free the iret wrapper
   _go32_dpmi_free_iret_wrapper(&NewHandler);

   printf("old mouse ISR installed\n");
}

int main(int argc, char **argv)
{
   mouse_int_install();

   // call the ASM module with real mode addressing info and command line
   go(_dos_ds, __tb, argc, argv);
   
   mouse_int_remove();

   return 0;
}
