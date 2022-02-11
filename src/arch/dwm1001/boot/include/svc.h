/*******************************************************************************/
/*  © Université de Lille, The Pip Development Team (2015-2022)                */
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

#ifndef __SVC_H__
#define __SVC_H__

#include "user_ADT.h"

/*!
 * \brief System call that creates a new child, i.e. a sub-partition of
 *        the current partition.
 *
 * \param blockLocalId The local ID of the block that will contain the
 *        partition descriptor structure.
 *
 * \return 1 if the system call succeed, 0 otherwise.
 */
uint32_t Pip_createPartition(
	uint32_t *blockLocalId);

/*!
 * \brief System call that cuts a block at an address that creates a new
 *        sub-block at that address.
 *
 * \param blockToCutLocalId The local ID of the block to cut.
 *
 * \param cutAddr The address where to cut the block.
 *
 * \param mpuRegionNb The region number of the physical MPU where to
 *        place the created sub-block.
 *
 * \return Returns the ID of the newly created sub-block if the system
 *         call succeed, NULL otherwise.
 */
uint32_t *Pip_cutMemoryBlock(
	uint32_t *blockToCutLocalId,
	uint32_t *cutAddr,
	int32_t mpuRegionNb);

/*!
 * \brief System call that merges two blocks together.
 *
 * \param blockToMerge1LocalId The local ID of the block to be merged
 *        becomes the beginning of the merged blocks.
 *
 * \param blockToMerge2LocalId The local ID of the block to be merged
 *        disappears from the list of blocks.
 *
 * \param mpuRegionNb The region number of the physical MPU where to
 *        place the merged block.
 *
 * \return Returns the local ID of the merged blocks if the system call
 *         succeed, NULL otherwise.
 */
uint32_t *Pip_mergeMemoryBlocks(
	uint32_t *blockToMerge1LocalId,
	uint32_t *blockToMerge2LocalId,
	int32_t mpuRegionNb);

/*!
 * \brief System call that prepares the partition descriptor structure
 *        of the current partition or one of its child to receive blocks
 *        and use a block as a metadata structure.
 *
 * \param partDescBlockId The ID of the block containing the current
 *        partition descriptor structure or one of its child.
 *
 * \param projectedSlotsNb The number of requested slots. -1 to force
 *        the prepare, even if there are still free slots.
 *
 * \param requisitionedBlockLocalId The local ID of the block used as
 *        the new kernel structure.
 *
 * \return 1 if the system call succeed, 0 otherwise.
 */
uint32_t Pip_prepare(
	uint32_t *partDescBlockId,
	int32_t projectedSlotsNb,
	uint32_t *requisitionedBlockLocalId);

/*!
 * \brief System call that adds a block to the partition descriptor
 *        structure of a child of the current partition. The block
 *        is still accessible from the current partition (shared
 *        memory).
 *
 * \param childPartDescBlockLocalId The local ID of the block containing
 *        the partition descriptor structure of the child.
 *
 * \param blockToShareLocalId The local ID of the block to share with
 *        the child partition.
 *
 * \param r The read right to apply to the block in the child partition.
 *
 * \param w The write right to apply to the block in the child partition.
 *
 * \param e The execute right to apply to the block in the child
 *          partition.
 *
 * \return Returns the ID of the shared block in the child.
 */
uint32_t *Pip_addMemoryBlock(
	uint32_t *childPartDescBlockLocalId,
	uint32_t *blockToShareLocalId,
	uint32_t r,
	uint32_t w,
	uint32_t e);

/*!
 * \brief System call that removes a block from the partition descriptor
 *        structure of a child of the current partition.
 *
 * \param blockToRemoveLocalId The local ID of the block to remove from
 *        the child partition.
 *
 * \return 1 if the system call succeed, 0 otherwise.
 */
uint32_t Pip_removeMemoryBlock(
	uint32_t *blockToRemoveLocalId);

/*!
 * \brief System call that deletes the block containing the partition
 *        descriptor structure of a child of the current partition.
 *
 * \param childPartDescBlockLocalId The local ID of the block containing
 *        the partition descriptor structure of the child to remove.
 *
 * \return 1 if the system call succeed, 0 otherwise.
 */
uint32_t Pip_deletePartition(
	uint32_t *childPartDescBlockLocalId);

/*!
 * \brief System call that collects an empty structure, if possible, from
 *        the block containing the partition descriptor structure of the
 *        current partition or one of its childs.
 *
 * \param partDescBlockId The block containing the partition descriptor
 *        structure of the current partition or one of its child.
 *
 * \return The ID of the collected block containing the structure if the
 *         system call succeed, NULL otherwise.
 */
uint32_t *Pip_collect(
	uint32_t *partDescBlockId);

/*!
 * \brief System call that maps a block in the physical MPU region of
 *        the partition descriptor structure of the current partition or
 *        one of its childs.
 *
 * \param partDescBlockId The ID of the block containing the partition
 *        descriptor structure of the current partition or one of its
 *        child.
 *
 * \param blockToMapLocalId The ID of the block to map in a physical MPU
 *        region of the partition descriptor structure.
 *
 * \param mpuRegionNb The number of the physical MPU region from which
 *        to write.
 *
 * \return 1 if the system call succeed, 0 otherwise.
 */
uint32_t Pip_mapMPU(
	uint32_t *partDescBlockId,
	uint32_t *blockToMapLocalId,
	int32_t mpuRegionNb);

/*!
 * \brief System call that reads the content of a physical MPU region in
 *        the partition descriptor structure of the current partition or
 *        one of its childs.
 *
 * \param partDescBlockId The block containing the partition descriptor
 *        structure of the current partition or one of its child.
 *
 * \param mpuRegionNb The number of the physical MPU region from which
 *        to read.
 *
 * \return The block ID in the read physical MPU region if the function
 *         succeed, NULL otherwise.
 */
uint32_t *Pip_readMPU(
	uint32_t *partDescBlockId,
	int32_t mpuRegionNb);

/*!
 * \brief System call that finds in which block an address is located by
 *        searching in the blocks list of the partition descriptor
 *        structure of the current partition or one of its childs.
 *
 * \param partDescBlockId The ID of the block containing the partition
 *        descriptor structure of the current partition or one of its
 *        child.
 *
 * \param addrToFind The address to find in the blocks list.
 *
 * \param blockAddr The address of a block structure where to store the
 *        informations of the found block.
 *
 * \return The value of the error field in the structure.
 */
int32_t Pip_findBlock(
	uint32_t *partDescBlockId,
	uint32_t *addrInBlock,
	blockOrError *blockAddr);

/*!
 * \brief System call that sets the VIDT block in the partition
 *        descriptor structure of the current partition or one of its
 *        child.
 *
 * \param partDescBlockId The ID of the block containing the partition
 *        descriptor structure of the current partition or one of its
 *        childs.
 *
 * \param vidtBlockLocalId The ID of the block that will contain the
 *        VIDT or 0 to reset the VIDT block to NULL in the partition
 *        descriptor structure.
 *
 * \return 1 if the system call succeed, 0 otherwise.
 */
uint32_t Pip_setVIDT(
	uint32_t *partDescBlockId,
	uint32_t *vidtBlockLocalId);

/*!
 * \brief System call that yield from the current partition (the
 *        caller), to its parent or one of its childs (the callee).
 *
 * \param calleePartDescBlockId The ID of the block containing the
 *        partition descriptor structure of a child of the current
 *        partition, or an ID equals to 0 for the partition descriptor
 *        structure of its parent.
 *
 * \param userTargetInterrupt The index of the VIDT, which contains the
 *        address pointing to the location where the current context is
 *        to be restored.
 *
 * \param userCallerContextSaveIndex The index of the VIDT, which
 *        contains the address pointing to the location where the
 *        current context is to be stored. If this address is zero, the
 *        context is not stored.
 *
 * \param flagsOnYield The state the partition wishes to be on yield.
 *
 * \param flagsOnWake The state the partition wishes to be on wake.
 *
 * \return If the system call succeeds, no value is returned to the
 *         caller. If an error occurs, the system call returns an error
 *         code indicating the nature of the error. If the context is
 *         restored, the return value should be ignored.
 */
uint32_t Pip_yield(
	uint32_t *calleePartDescBlockId,
	uint32_t userTargetInterrupt,
	uint32_t userCallerContextSaveIndex,
	uint32_t flagsOnYield,
	uint32_t flagsOnWake);

#endif /* __SVC_H__ */
