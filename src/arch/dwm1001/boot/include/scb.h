/*******************************************************************************/
/*  © Université de Lille, The Pip Development Team (2015-2021)                */
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

#ifndef __SCB_H__
#define __SCB_H__

#include <stdlib.h>

/*!
 * Structure representing the CCR register.
 */
typedef union scb_ccr_reg_u
{
	/*!
	 * \brief Read or write the CCR register as a 32-bit value.
	 */
	uint32_t as_uint32_t;

	struct
	{
		/*!
		 * \brief Controls whether the processor can enter
		 *        Thread mode with exceptions active.
		 */
		uint32_t NONBASETHRDENA : 1  ;

		/*!
		 * \brief Controls whether unprivileged software can
		 *        access the STIR.
		 */
		uint32_t USERSETMPEND   : 1  ;

		/*!
		 * \brief Reserved.
		 */
		uint32_t RESERVED_0     : 1  ;

		/*!
		 * \brief Controls the trapping of unaligned word or
		 *        halfword accesses.
		 */
		uint32_t UNALIGN_TRP    : 1  ;

		/*!
		 * \brief Controls the trap on divide by 0.
		 */
		uint32_t DIV_0_TRP      : 1  ;

		/*!
		 * \brief Reserved.
		 */
		uint32_t RESERVED_1     : 3  ;

		/*!
		 * \brief Determines the effect of precise data access
		 *        faults on handlers running at priority -1 or
		 *        priority -2.
		 */
		uint32_t BFHFNMIGN      : 1  ;

		/*!
		 * \brief Determines whether the exception entry
		 *        sequence guarantees 8-byte stack frame
		 *        alignment, adjusting the SP if necessary
		 *        before saving state.
		 */
		uint32_t STKALIGN       : 1  ;

		/*!
		 * \brief Reserved.
		 */
		uint32_t RESERVED_2     : 6  ;

		/*!
		 * \brief Cache enable bit. This is a global enable bit
		 *        for data and unified caches.
		 */
		uint32_t DC             : 1  ;

		/*!
		 * \brief Instruction cache enable bit. This is a global
		 *        enable bit for instruction caches.
		 */
		uint32_t IC             : 1  ;

		/*!
		 * \brief Branch prediction enable bit.
		 */
		uint32_t BP             : 1  ;

		/*!
		 * \brief Reserved.
		 */
		uint32_t RESERVED_3     : 13 ;
	};
} scb_ccr_reg_t;

/*!
 * \def CCR
 * \define Sets or returns configuration and control data, and provides
 *         control over caching and branch prediction.
 */
#define CCR (*((scb_ccr_reg_t *) 0xE000ED14))

#endif /* __SCB_H__ */
