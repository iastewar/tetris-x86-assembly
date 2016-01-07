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

// extern symbols defined in key.asm
extern void myKeyInt(void);
extern int myKeyInt_Size;
extern int keyVal;

// function contained within the assembly language module, portal.asm
extern void go(unsigned long selector, unsigned long buffer, int argc, char **argv);

// create seginfo structs
_go32_dpmi_seginfo OldHandler, NewHandler;

void keyboard_int_install() {
   // retrieve the current (old) keyboard handler
   _go32_dpmi_get_protected_mode_interrupt_vector(9, &OldHandler);

   // lock code and data from being paged
   _go32_dpmi_lock_code(myKeyInt, (long)myKeyInt_Size);
   _go32_dpmi_lock_data(&keyVal, (long)sizeof(keyVal));

   // establish new seginfo struct
   NewHandler.pm_offset = (long)myKeyInt;
   NewHandler.pm_selector = _go32_my_cs();

   // allocate the IRET wrapper
   _go32_dpmi_allocate_iret_wrapper(&NewHandler);

   // install the new keyboard ISR
   _go32_dpmi_set_protected_mode_interrupt_vector(9, &NewHandler);

   printf("new keyboard ISR installed\n");
}

void keyboard_int_remove() {
   // revert to old keyboard ISR
   _go32_dpmi_set_protected_mode_interrupt_vector(9, &OldHandler);

   // free the iret wrapper
   _go32_dpmi_free_iret_wrapper(&NewHandler);

   printf("old keyboard ISR installed\n");
}

int main(int argc, char **argv)
{
   keyboard_int_install();

   // call the ASM module with real mode addressing info and command line
   go(_dos_ds, __tb, argc, argv);
   
   keyboard_int_remove();

   return 0;
}
