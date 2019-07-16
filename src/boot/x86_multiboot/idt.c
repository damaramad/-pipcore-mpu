/*******************************************************************************/
/*  © Université Lille 1, The Pip Development Team (2015-2018)                 */
/*                                                                             */
/*  This software is a computer program whose purpose is to run a minimal,     */
/*  hypervisor relying on proven properties such as memory isolation.          */
/*                                                                             */
/*  This software is governed by the CeCILL license under French law and       */
/*  abiding by the rules of distribution of free software.  You can  use,      */
/*  modify and/ or redistribute the software under the terms of the CeCILL     */
/*  license as circulated by CEA, CNRS and INRIA at the following URL          */
/*  "http://www.cecill.info".                                                  */
/*                                                                             */
/*  As a counterpart to the access to the source code and  rights to copy,     */
/*  modify and redistribute granted by the license, users are provided only    */
/*  with a limited warranty  and the software's author,  the holder of the     */
/*  economic rights,  and the successive licensors  have only  limited         */
/*  liability.                                                                 */
/*                                                                             */
/*  In this respect, the user's attention is drawn to the risks associated     */
/*  with loading,  using,  modifying and/or developing or reproducing the      */
/*  software by the user in light of its specific status of free software,     */
/*  that may mean  that it is complicated to manipulate,  and  that  also      */
/*  therefore means  that it is reserved for developers  and  experienced      */
/*  professionals having in-depth computer knowledge. Users are therefore      */
/*  encouraged to load and test the software's suitability as regards their    */
/*  requirements in conditions enabling the security of their systems and/or   */
/*  data to be ensured and,  more generally, to use and operate it in the      */
/*  same conditions as regards security.                                       */
/*                                                                             */
/*  The fact that you are presently reading this means that you have had       */
/*  knowledge of the CeCILL license and that you accept its terms.             */
/*******************************************************************************/

#include "idt.h"
#include "port.h"
#include "pic8259.h"
#include "debug.h"
#include "libc.h"


/**
 * \brief IDT entry initializer
 * \seealso idt_entry_t
 */
#define IDT_ENTRY(entrypoint, segment_selector, flags) {         \
	(uint16_t) 0,                                            \
	((uint16_t) (segment_selector)),                         \
	0,                                                       \
	(flags),                                                 \
	(uint16_t) 0                                             \
}

/**
 * Contructs an IDT entry flag with a given ring level privilege
 * \seealso Intel Software Developer's Manual - Volume 3a Chapter 5 Figure 5-2 
 * segment present flag: 1
 * gate size: 32
 *
 * Some segment selector stuff :
 * - Faults are in kernel level, flag is then 0x8E, because we won't explicitely trigger them from userland.
 * - But pipcalls may be triggered on purpose from userland (well, they sould always be, in fact), so our flags are 0xEE.
*/
#define IDT_FLAGS(ring) (0x8E | (((ring) & 0x3) << 5))
#define IDT_KERNEL_FLAGS (IDT_FLAGS(0))
#define IDT_USER_FLAGS (IDT_FLAGS(3))

#define IRQ_CODE_SEGMENT (0x08)

extern void irq_unsupported(void);

void unsupportedHandler(void *ctx) {
	DEBUG(TRACE, "Unsupported IRQ !\n");
	while(1);
}

extern void irq_test(void);

void testHandler(void *ctx) {
	outb (PIC2_COMMAND, PIC_EOI);
	outb (PIC1_COMMAND, PIC_EOI);
	DEBUG(TRACE, "Testtest !\n");
}

/**
 * Interrupt Descriptor Table
 * \seealso Intel Software Developer's Manual - Volume 3a Chapter 5
 * /!\ Beware BEWARE you must update the callback table correctly after updating this one
 */
static idt_entry_t idt_entries[256] = {
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_KERNEL_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_KERNEL_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_KERNEL_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_KERNEL_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_KERNEL_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_KERNEL_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_KERNEL_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_KERNEL_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_KERNEL_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_KERNEL_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_KERNEL_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_KERNEL_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_KERNEL_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_KERNEL_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_KERNEL_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_KERNEL_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_KERNEL_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_KERNEL_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_KERNEL_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_KERNEL_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_KERNEL_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_KERNEL_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_KERNEL_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_KERNEL_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_KERNEL_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_KERNEL_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_KERNEL_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_KERNEL_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_KERNEL_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_KERNEL_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_KERNEL_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_KERNEL_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_KERNEL_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_KERNEL_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_KERNEL_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_KERNEL_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_KERNEL_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_KERNEL_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_KERNEL_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_KERNEL_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_KERNEL_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_KERNEL_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_KERNEL_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_KERNEL_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_KERNEL_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_KERNEL_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_KERNEL_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_KERNEL_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS),
       IDT_ENTRY(irq_unsupported, IRQ_CODE_SEGMENT, IDT_USER_FLAGS)
};

/**
 * \brief IDT entry initializer
 * \seealso idt_entry_t
 */
#define IDT_ENTRY(entrypoint, segment_selector, flags) {         \
	(uint16_t) 0,                                            \
	((uint16_t) (segment_selector)),                         \
	0,                                                       \
	(flags),                                                 \
	(uint16_t) 0                                             \
}


typedef void (*callback)(void);
static callback idt_callbacks[256] = {
	[0] = irq_unsupported, 
	[1] = irq_test,
	[2] = irq_unsupported,
	[3] = irq_unsupported,
	[4] = irq_unsupported,
	[5] = irq_unsupported,
	[6] = irq_unsupported,
	[7] = irq_unsupported,
	[8] = irq_unsupported,
	[9] = irq_unsupported,
	[10] = irq_unsupported,
	[11] = irq_unsupported,
	[12] = irq_unsupported,
	[13] = irq_unsupported,
	[14] = irq_unsupported,
	[15] = irq_unsupported,
	[16] = irq_unsupported,
	[17] = irq_unsupported,
	[18] = irq_unsupported,
	[19] = irq_unsupported,
	[20] = irq_unsupported,
	[21] = irq_unsupported,
	[22] = irq_unsupported,
	[23] = irq_unsupported,
	[24] = irq_unsupported,
	[25] = irq_unsupported,
	[26] = irq_unsupported,
	[27] = irq_unsupported,
	[28] = irq_unsupported,
	[29] = irq_unsupported,
	[30] = irq_unsupported,
	[31] = irq_unsupported,
	[32] = irq_test,
	[33] = irq_unsupported,
	[34] = irq_unsupported,
	[35] = irq_unsupported,
	[36] = irq_unsupported,
	[37] = irq_unsupported,
	[38] = irq_unsupported,
	[39] = irq_unsupported,
	[40] = irq_unsupported,
	[41] = irq_unsupported,
	[42] = irq_unsupported,
	[43] = irq_unsupported,
	[44] = irq_unsupported,
	[45] = irq_unsupported,
	[46] = irq_unsupported,
	[47] = irq_unsupported,
	[48] = irq_unsupported,
	[49] = irq_unsupported,
	[50] = irq_unsupported,
	[51] = irq_unsupported,
	[52] = irq_unsupported,
	[53] = irq_unsupported,
	[54] = irq_unsupported,
	[55] = irq_unsupported,
	[56] = irq_unsupported,
	[57] = irq_unsupported,
	[58] = irq_unsupported,
	[59] = irq_unsupported,
	[60] = irq_unsupported,
	[61] = irq_unsupported,
	[62] = irq_unsupported,
	[63] = irq_unsupported,
	[64] = irq_unsupported,
	[65] = irq_unsupported,
	[66] = irq_unsupported,
	[67] = irq_unsupported,
	[68] = irq_unsupported,
	[69] = irq_unsupported,
	[70] = irq_unsupported,
	[71] = irq_unsupported,
	[72] = irq_unsupported,
	[73] = irq_unsupported,
	[74] = irq_unsupported,
	[75] = irq_unsupported,
	[76] = irq_unsupported,
	[77] = irq_unsupported,
	[78] = irq_unsupported,
	[79] = irq_unsupported,
	[80] = irq_unsupported,
	[81] = irq_unsupported,
	[82] = irq_unsupported,
	[83] = irq_unsupported,
	[84] = irq_unsupported,
	[85] = irq_unsupported,
	[86] = irq_unsupported,
	[87] = irq_unsupported,
	[88] = irq_unsupported,
	[89] = irq_unsupported,
	[90] = irq_unsupported,
	[91] = irq_unsupported,
	[92] = irq_unsupported,
	[93] = irq_unsupported,
	[94] = irq_unsupported,
	[95] = irq_unsupported,
	[96] = irq_unsupported,
	[97] = irq_unsupported,
	[98] = irq_unsupported,
	[99] = irq_unsupported,
	[100] = irq_unsupported,
	[101] = irq_unsupported,
	[102] = irq_unsupported,
	[103] = irq_unsupported,
	[104] = irq_unsupported,
	[105] = irq_unsupported,
	[106] = irq_unsupported,
	[107] = irq_unsupported,
	[108] = irq_unsupported,
	[109] = irq_unsupported,
	[110] = irq_unsupported,
	[111] = irq_unsupported,
	[112] = irq_unsupported,
	[113] = irq_unsupported,
	[114] = irq_unsupported,
	[115] = irq_unsupported,
	[116] = irq_unsupported,
	[117] = irq_unsupported,
	[118] = irq_unsupported,
	[119] = irq_unsupported,
	[120] = irq_unsupported,
	[121] = irq_unsupported,
	[122] = irq_unsupported,
	[123] = irq_unsupported,
	[124] = irq_unsupported,
	[125] = irq_unsupported,
	[126] = irq_unsupported,
	[127] = irq_unsupported,
	[128] = irq_unsupported,
	[129] = irq_unsupported,
	[130] = irq_unsupported,
	[131] = irq_unsupported,
	[132] = irq_unsupported,
	[133] = irq_unsupported,
	[134] = irq_unsupported,
	[135] = irq_unsupported,
	[136] = irq_unsupported,
	[137] = irq_unsupported,
	[138] = irq_unsupported,
	[139] = irq_unsupported,
	[140] = irq_unsupported,
	[141] = irq_unsupported,
	[142] = irq_unsupported,
	[143] = irq_unsupported,
	[144] = irq_unsupported,
	[145] = irq_unsupported,
	[146] = irq_unsupported,
	[147] = irq_unsupported,
	[148] = irq_unsupported,
	[149] = irq_unsupported,
	[150] = irq_unsupported,
	[151] = irq_unsupported,
	[152] = irq_unsupported,
	[153] = irq_unsupported,
	[154] = irq_unsupported,
	[155] = irq_unsupported,
	[156] = irq_unsupported,
	[157] = irq_unsupported,
	[158] = irq_unsupported,
	[159] = irq_unsupported,
	[160] = irq_unsupported,
	[161] = irq_unsupported,
	[162] = irq_unsupported,
	[163] = irq_unsupported,
	[164] = irq_unsupported,
	[165] = irq_unsupported,
	[166] = irq_unsupported,
	[167] = irq_unsupported,
	[168] = irq_unsupported,
	[169] = irq_unsupported,
	[170] = irq_unsupported,
	[171] = irq_unsupported,
	[172] = irq_unsupported,
	[173] = irq_unsupported,
	[174] = irq_unsupported,
	[175] = irq_unsupported,
	[176] = irq_unsupported,
	[177] = irq_unsupported,
	[178] = irq_unsupported,
	[179] = irq_unsupported,
	[180] = irq_unsupported,
	[181] = irq_unsupported,
	[182] = irq_unsupported,
	[183] = irq_unsupported,
	[184] = irq_unsupported,
	[185] = irq_unsupported,
	[186] = irq_unsupported,
	[187] = irq_unsupported,
	[188] = irq_unsupported,
	[189] = irq_unsupported,
	[190] = irq_unsupported,
	[191] = irq_unsupported,
	[192] = irq_unsupported,
	[193] = irq_unsupported,
	[194] = irq_unsupported,
	[195] = irq_unsupported,
	[196] = irq_unsupported,
	[197] = irq_unsupported,
	[198] = irq_unsupported,
	[199] = irq_unsupported,
	[200] = irq_unsupported,
	[201] = irq_unsupported,
	[202] = irq_unsupported,
	[203] = irq_unsupported,
	[204] = irq_unsupported,
	[205] = irq_unsupported,
	[206] = irq_unsupported,
	[207] = irq_unsupported,
	[208] = irq_unsupported,
	[209] = irq_unsupported,
	[210] = irq_unsupported,
	[211] = irq_unsupported,
	[212] = irq_unsupported,
	[213] = irq_unsupported,
	[214] = irq_unsupported,
	[215] = irq_unsupported,
	[216] = irq_unsupported,
	[217] = irq_unsupported,
	[218] = irq_unsupported,
	[219] = irq_unsupported,
	[220] = irq_unsupported,
	[221] = irq_unsupported,
	[222] = irq_unsupported,
	[223] = irq_unsupported,
	[224] = irq_unsupported,
	[225] = irq_unsupported,
	[226] = irq_unsupported,
	[227] = irq_unsupported,
	[228] = irq_unsupported,
	[229] = irq_unsupported,
	[230] = irq_unsupported,
	[231] = irq_unsupported,
	[232] = irq_unsupported,
	[233] = irq_unsupported,
	[234] = irq_unsupported,
	[235] = irq_unsupported,
	[236] = irq_unsupported,
	[237] = irq_unsupported,
	[238] = irq_unsupported,
	[239] = irq_unsupported,
	[240] = irq_unsupported,
	[241] = irq_unsupported,
	[242] = irq_unsupported,
	[243] = irq_unsupported,
	[244] = irq_unsupported,
	[245] = irq_unsupported,
	[246] = irq_unsupported,
	[247] = irq_unsupported,
	[248] = irq_unsupported,
	[249] = irq_unsupported,
	[250] = irq_unsupported,
	[251] = irq_unsupported,
	[252] = irq_unsupported,
	[253] = irq_unsupported,
	[254] = irq_unsupported,
	[255] = irq_unsupported
};

void initIDT(void) {
	DEBUG(TRACE, "Initializing the IDT...\n");
	int i = 0;
	idt_ptr_t idt_ptr;		//!< Pointer to the IDT
	idt_ptr.base = idt_entries;
	idt_ptr.limit = 256 * sizeof(idt_entry_t) - 1;
	for (i=0;i<256;i++) {
		idt_entries[i].base_lo = ((uint32_t) idt_callbacks[i]) & 0xFFFF;
		idt_entries[i].base_hi = (((uint32_t) idt_callbacks[i]) >> 16) & 0xFFFF;
	}
	BOOT_DEBUG(TRACE, "Done initializing, now loading the IDT\n");
	asm("lidt (%0)"::"r"(&idt_ptr));
	ASSERT(irq_unsupported != 0);
	BOOT_DEBUG(TRACE, "Done loading IDT\n")
}

/**
 * \fn remapIrq
 * \brief Remaps IRQ from int. 0-15 to int. 33-48
 */
void
remapIRQ (void)
{
#define PIC1_OFFSET	0x20
#define PIC2_OFFSET	0x28
	
#ifdef KEEP_PIC_MASK
	uint8_t a1, a2;
	/* save masks */
	a1 = inb (PIC1_DATA);
	a2 = inb (PIC2_DATA);
#endif
	
	/* starts the initialization sequence (in cascade mode) */
	outb (PIC1_COMMAND, ICW1_INIT | ICW1_ICW4);
	outb (PIC2_COMMAND, ICW1_INIT | ICW1_ICW4);
	outb (PIC1_DATA, PIC1_OFFSET);
	outb (PIC2_DATA, PIC2_OFFSET);
	outb (PIC1_DATA, 0x04);	/* there is a slave PIC at IRQ2 */
	outb (PIC2_DATA, 0x02);	/* Slave PIC its cascade identity */
	outb (PIC1_DATA, ICW4_8086);
	outb (PIC2_DATA, ICW4_8086);
	
	/* masks */
#ifdef KEEP_PIC_MASK
	outb (PIC1_DATA, a1);
	outb (PIC2_DATA, a2);
#else
	outb (PIC1_DATA, 0);
	outb (PIC2_DATA, 0);
#endif
}


/**
 * \fn timerPhase
 * \brief Set timer frequency
 * \param Frequency to set
 *
 */
void
timerPhase (uint32_t hz)
{
	uint32_t divisor = 2600000 / hz;
	if (divisor > 0xffff) divisor = 0xffff;
	if (divisor < 1) divisor = 1;
	
	outb (0x43, 0x36);              /* Set our command byte 0x36 */
	outb (0x40, divisor & 0xFF);    /* Set low byte of divisor */
	outb (0x40, divisor >> 8);      /* Set high byte of divisor */
	
	BOOT_DEBUG (INFO, "Timer phase changed to %d hz\n", hz);
}

uint32_t pcid_enabled = 0;

/**
 * \fn void initCpu()
 * \brief Initializes CPU-specific features
 */
void initCPU()
{
	BOOT_DEBUG(CRITICAL, "Identifying CPU model and features...\n");
	
	/* Display CPU vendor string */
	uint32_t cpu_string[4];
	cpuid_string(CPUID_GETVENDORSTRING, cpu_string); /* Vendor string will be 12 characters in EBX, EDX, ECX */
	char cpuident[17];
	char cpubrand[49];
	
	/* Build string */
	memcpy(cpuident, &(cpu_string[1]), 4 * sizeof(char));
	memcpy(&(cpuident[4]), &(cpu_string[3]), 4 * sizeof(char));
	memcpy(&(cpuident[8]), &(cpu_string[2]), 4 * sizeof(char));
	cpuident[12] = '\0';
	
	BOOT_DEBUG(CRITICAL, "CPU identification: %s\n", cpuident);
	
	/* Processor brand */
	cpuid_string(CPUID_INTELBRANDSTRING, (uint32_t*)cpubrand);
	cpuid_string(CPUID_INTELBRANDSTRINGMORE, (uint32_t*)&cpubrand[16]);
	cpuid_string(CPUID_INTELBRANDSTRINGEND, (uint32_t*)&cpubrand[32]);
	cpubrand[48] = '\n';
	BOOT_DEBUG(CRITICAL, "CPU brand: %s\n", cpubrand);
	
	/* Check whether PCID is supported as well as PGE */
	uint32_t ecx, edx;
	cpuid(CPUID_GETFEATURES, &ecx, &edx);
	uint32_t cr4;
	
	/* PGE check */
	if(edx & CPUID_FEAT_EDX_PGE)
	{
		BOOT_DEBUG(CRITICAL, "PGE supported, enabling CR4.PGE\n");
		__asm volatile("MOV %%CR4, %0" : "=r"(cr4));
		cr4 |= (1 << 7); /* Enable Page Global as well */
		__asm volatile("MOV %0, %%CR4" :: "r"(cr4));
	} else {
		BOOT_DEBUG(CRITICAL, "PGE unsupported, Global Page feature will be unavailable\n");
	}
	
	/* PCID check */
	if(ecx & CPUID_FEAT_ECX_PCID)
	{
		BOOT_DEBUG(CRITICAL, "PCID supported, enabling CR4.PCIDE\n");
		pcid_enabled = 1;
		
		/* Enable PCID */
		__asm volatile("MOV %%CR4, %0" : "=r"(cr4));
		cr4 |= (1 << 17);
		__asm volatile("MOV %0, %%CR4" :: "r"(cr4));
	} else {
		BOOT_DEBUG(CRITICAL, "PCID unsupported, Process Context Identifiers feature will be unavailable\n");
	}
}

uint32_t timer_ticks = 0;

void initInterrupts(void) {
	BOOT_DEBUG(INFO, "Initializing interrupts\n");
	initIDT();
	remapIRQ();
	timerPhase(100);
	timer_ticks = 0;
	initCPU();
	BOOT_DEBUG(INFO, "Done initializing interrupts\n");
	BOOT_DEBUG(TRACE, "Calling int 1\n");
	asm("int $0x1");
	BOOT_DEBUG(TRACE, "Returned from int 1\n");
}
