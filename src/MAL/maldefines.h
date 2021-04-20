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

/**
 * \file maldefines.h
 * \brief Memory Abstraction Layer provided methods for Coq
 */

#ifndef __MAL_DEFINES__
#define __MAL_DEFINES__

#include "mal.h"
#include <stdint.h>
#include <stddef.h>

/* Constants */
#define Constants_coq_MPUEntryLength mpuentrylength
#define Constants_coq_SHEntryLength sh1entrylength
#define Constants_coq_SCEntryLength scentrylength
#define Constants_mpuoffset MPUOFFSET
#define Constants_sh1offset sh1offset
#define Constants_scoffset scoffset
#define Constants_nextoffset nextoffset
#define Constants_rootPart 0

/* ADT structure */
#define coq_PDTable PDTable_t
#define coq_MPUEntry MPUEntry_t
#define coq_Sh1Entry Sh1Entry_t
#define coq_SCEntry SCEntry_t

/* MALInternals */
#define Paddr_leb lebPaddr
#define Paddr_addPaddr addPaddr
#define Paddr_subPaddr subPaddr
#define Paddr_pred predPaddr
#define Paddr_addPaddrIdx addPaddrIdx

#define index uint32_t
#define Index_succ      inc
#define Index_pred      dec
#define Index_eqb       eqb
#define Index_zero      zero
#define Index_geb       geb
#define Index_gtb       gtb
#define Index_leb       leb
#define Index_ltb       ltb
#define Index_subIdx    sub
#define Index_addIdx    add
#define Index_mulIdx    mul

#define getBeqAddr beqAddr
#define getBeqIdx beqIdx
#define nullAddr NULL

#define maxNbPrepare MAXNBPREPARE
#define getMaxNbPrepare MAXNBPREPARE
#define getMinBlockSize MINBLOCKSIZE
#define getKernelStructureTotalLength KERNELSTRUCTURETOTALLENGTH
#define getPDStructureTotalLength PDSTRUCTURETOTALLENGTH
#define getKernelStructureEntriesNb KERNELSTRUCTUREENTRIESNB
#define kernelStructureEntriesNb KERNELSTRUCTUREENTRIESNB

/* Astucious defines */
#define coq_N   1000

#endif
