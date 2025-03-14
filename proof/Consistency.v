(*******************************************************************************)
(*  © Université de Lille, The Pip Development Team (2015-2024)                *)
(*  Copyright (C) 2020-2024 Orange                                             *)
(*                                                                             *)
(*  This software is a computer program whose purpose is to run a minimal,     *)
(*  hypervisor relying on proven properties such as memory isolation.          *)
(*                                                                             *)
(*  This software is governed by the CeCILL license under French law and       *)
(*  abiding by the rules of distribution of free software.  You can  use,      *)
(*  modify and/ or redistribute the software under the terms of the CeCILL     *)
(*  license as circulated by CEA, CNRS and INRIA at the following URL          *)
(*  "http://www.cecill.info".                                                  *)
(*                                                                             *)
(*  As a counterpart to the access to the source code and  rights to copy,     *)
(*  modify and redistribute granted by the license, users are provided only    *)
(*  with a limited warranty  and the software's author,  the holder of the     *)
(*  economic rights,  and the successive licensors  have only  limited         *)
(*  liability.                                                                 *)
(*                                                                             *)
(*  In this respect, the user's attention is drawn to the risks associated     *)
(*  with loading,  using,  modifying and/or developing or reproducing the      *)
(*  software by the user in light of its specific status of free software,     *)
(*  that may mean  that it is complicated to manipulate,  and  that  also      *)
(*  therefore means  that it is reserved for developers  and  experienced      *)
(*  professionals having in-depth computer knowledge. Users are therefore      *)
(*  encouraged to load and test the software's suitability as regards their    *)
(*  requirements in conditions enabling the security of their systems and/or   *)
(*  data to be ensured and,  more generally, to use and operate it in the      *)
(*  same conditions as regards security.                                       *)
(*                                                                             *)
(*  The fact that you are presently reading this means that you have had       *)
(*  knowledge of the CeCILL license and that you accept its terms.             *)
(*******************************************************************************)


(** * Summary
    This file contains the formalization of the consistency properties :
for each one we summarize the description of its definition *)
Require Import Model.ADT Model.Monad Model.MAL Model.Lib Lib StateLib.
Require Import List Coq.Logic.ProofIrrelevance.
Import List.ListNotations.

(** **  Type SHE is linked to a particular BE entry by an offset sh1offset in
    the metadata superstructure. **)
Definition wellFormedFstShadowIfBlockEntry s :=
forall pa,
isBE pa s ->
isSHE (CPaddr (pa + sh1offset)) s.

(** **  Type SCE is linked to a particular BE entry by an offset scoffset in
    the metadata superstructure. **)
Definition wellFormedShadowCutIfBlockEntry s :=
forall pa,
isBE pa s ->
exists scentryaddr : paddr, isSCE scentryaddr s
/\ scentryaddr = CPaddr (pa + scoffset).

Definition wellFormedBlock s :=
forall block startaddr endaddr,
bentryPFlag block true s ->
bentryStartAddr block startaddr s ->
bentryEndAddr block endaddr s ->
(* startaddr inferior to endaddr + size of block greater than minimum MPU size *)
(startaddr < endaddr) /\ (Constants.minBlockSize <= (endaddr - startaddr)).

(** **  If the PDflag of a Shadow 1 entry is set, then
    the linked block in the Blocks structure hosts a PD structure. **)
Definition PDTIfPDFlag s :=
forall idPDchild sh1entryaddr,
true = StateLib.checkChild idPDchild s sh1entryaddr /\
sh1entryAddr idPDchild sh1entryaddr s ->
bentryAFlag idPDchild false s /\
bentryPFlag idPDchild true s /\
exists startaddr, bentryStartAddr idPDchild startaddr s /\
 entryPDT idPDchild startaddr s.

(** **  An accessible block cannot host a metadata structure (type PDT). **)
Definition AccessibleNoPDFlag s :=
forall block sh1entryaddr,
isBE block s ->
sh1entryAddr block sh1entryaddr s ->
bentryAFlag block true s ->
sh1entryPDflag sh1entryaddr false s.

(** **  Address 0 is a special entry in the memory model taking on the role of
    the empty address. It must be of type PADDR. **)
Definition nullAddrExists s :=
isPADDR nullAddr s.

(* TODO : to remove -> consequence of freeSlotsListIsFreeSlot and FreeSlotIsBE
	-> but convenient for now so keep it *)
(** **  The reference to the first free slot has the type BE and is free. **)
Definition FirstFreeSlotPointerIsBEAndFreeSlot s :=
forall pdentryaddr pdentry,
lookup pdentryaddr (memory s) beqAddr = Some (PDT pdentry) ->
pdentry.(firstfreeslot) <> nullAddr ->
isBE pdentry.(firstfreeslot) s /\
isFreeSlot pdentry.(firstfreeslot) s.

(* TODO : when removing the unecessary check in addMemoryBlock if this holds *)
Definition NbFreeSlotsISNbFreeSlotsInList s :=
forall pd nbfreeslots,
isPDT pd s ->
pdentryNbFreeSlots pd nbfreeslots s ->
exists optionfreeslotslist, optionfreeslotslist = getFreeSlotsList pd s /\
wellFormedFreeSlotsList optionfreeslotslist <> False /\ (* to get rid of false induction bound constraints *)
nbfreeslots.(i) (* nat *) = length (*(filterOption*) (optionfreeslotslist).

(** **  Given all partitions of a partition tree, all free slots lists are disjoint. **)
Definition DisjointFreeSlotsLists s :=
forall pd1 pd2,
isPDT pd1 s ->
isPDT pd2 s ->
pd1 <> pd2 ->
exists optionfreeslotslist1 optionfreeslotslist2,
optionfreeslotslist1 = getFreeSlotsList pd1 s /\
wellFormedFreeSlotsList optionfreeslotslist1 <> False /\ (* to get rid of false induction bound constraints *)
optionfreeslotslist2 = getFreeSlotsList pd2 s /\
wellFormedFreeSlotsList optionfreeslotslist2 <> False /\ (* to get rid of false induction bound constraints *)
disjoint (filterOptionPaddr (optionfreeslotslist1))(filterOptionPaddr (optionfreeslotslist2)).

(** **  Each element of a free slots list is unique. **)
Definition NoDupInFreeSlotsList s :=
forall pd pdentry,
lookup pd (memory s) beqAddr = Some (PDT pdentry) ->
exists optionfreeslotslist, optionfreeslotslist = getFreeSlotsList pd s /\
wellFormedFreeSlotsList optionfreeslotslist <> False /\ (* to get rid of false induction bound constraints *)
NoDup (filterOptionPaddr (optionfreeslotslist)).

(** **  The reference to the first superstructure is the start of a superstructure. **)
Definition StructurePointerIsKS s :=
forall entryaddr entry,
lookup entryaddr (memory s) beqAddr = Some (PDT entry) ->
entry.(structure) <> nullAddr ->
isKS entry.(structure) s.

(** **  The value of the reference to the next linked superstructure has the type PADDR. **)
Definition NextKSOffsetIsPADDR s :=
forall addr nextksaddr : paddr,
isKS addr s ->
nextKSAddr addr nextksaddr s ->
isPADDR nextksaddr s /\ nextksaddr <> nullAddr.

(** **  The reference to the next element of the linked list of
    superstructures is the start of another superstructure. **)
Definition NextKSIsKS s :=
forall addr nextKSaddr nextKS : paddr,
isKS addr s ->
nextKSAddr addr nextKSaddr s ->
nextKSentry nextKSaddr nextKS s ->
nextKS <> nullAddr ->
isKS nextKS s.

Definition multiplexerIsPDT s :=
isPDT multiplexer s.

(** **  The current partition belongs to the partition tree. **)
Definition currentPartitionInPartitionsList s :=
In (currentPartition s) (getPartitions multiplexer s).

(** **  Each block entry has the type BE. The kernelStructureEntriesNb parameter
    bounds the index to an arbitrary value. **)
Definition BlocksRangeFromKernelStartIsBE s :=
forall kernelentryaddr : paddr, forall blockidx : index,
isKS kernelentryaddr s ->
blockidx < kernelStructureEntriesNb ->
isBE (CPaddr (kernelentryaddr + blockidx)) s.

(** **  The start of a superstructure has the type BE. **)
Definition KernelStructureStartFromBlockEntryAddrIsKS s :=
forall (blockentryaddr : paddr) (blockidx : index),
isBE blockentryaddr s ->
bentryBlockIndex blockentryaddr blockidx s ->
isKS (CPaddr (blockentryaddr - blockidx)) s.

(** **  The reference to a block’s location in the child partition has the type BE. **)
Definition sh1InChildLocationIsBE s :=
forall sh1entryaddr sh1entry,
lookup sh1entryaddr (memory s) beqAddr = Some (SHE sh1entry) ->
sh1entry.(inChildLocation) <> nullAddr ->
isBE sh1entry.(inChildLocation) s.

(** **  Each element of a free slots list are free. **)
Definition freeSlotsListIsFreeSlot s :=
forall pd freeslotaddr optionfreeslotslist freeslotslist,
isPDT pd s ->
optionfreeslotslist = getFreeSlotsList pd s /\
wellFormedFreeSlotsList optionfreeslotslist <> False -> (* to get rid of false induction bound constraints *)
freeslotslist = filterOptionPaddr(optionfreeslotslist) /\
In freeslotaddr freeslotslist ->
freeslotaddr <> nullAddr ->
isFreeSlot freeslotaddr s.

(** **  The free slots list is included in the Blocks structure. **)
Definition inclFreeSlotsBlockEntries s :=
forall pd,
isPDT pd s ->
incl (getFreeSlotsList pd s) (getKSEntries pd s).

(** **  Given all partitions in a partition tree, all slots are unique. **)
Definition DisjointKSEntries s :=
forall pd1 pd2,
isPDT pd1 s ->
isPDT pd2 s ->
pd1 <> pd2 ->
exists optionentrieslist1 optionentrieslist2,
optionentrieslist1 = getKSEntries pd1 s /\
optionentrieslist2 = getKSEntries pd2 s /\
disjoint (filterOptionPaddr (optionentrieslist1))(filterOptionPaddr (optionentrieslist2)).

(* Prove DisjointKSEntries -> DisjointFreeSlotsList because of inclusion *)

(** ** All partitions pointing to the same parent are children of this parent. **)
Definition isChild  s :=
forall partition parent : paddr,
In partition (getPartitions multiplexer s) ->
pdentryParent partition parent s ->
In partition (getChildren parent s).


(** **  All children of a parent partition points to this unique parent. **)
Definition isParent  s :=
forall partition parent : paddr,
In parent (getPartitions multiplexer s) ->
In partition (getChildren parent s) ->
pdentryParent partition parent s.

(* TODO: remove, consequence of noDupKSEntriesList*)
(** **  In a given partition, each mapped block is unique. **)
Definition noDupMappedBlocksList s :=
forall (partition : paddr),
isPDT partition s ->
NoDup (getMappedBlocks partition s).

(** **  In a given partition, each slot is unique. **)
Definition noDupKSEntriesList s :=
forall (partition : paddr),
isPDT partition s ->
NoDup (filterOptionPaddr (getKSEntries partition s)).

(** **  In a given partition, no block overlaps another
    (the sets of addresses they contain are disjoint). **)
Definition noDupUsedPaddrList s :=
forall (partition : paddr),
isPDT partition s ->
NoDup (getUsedPaddr partition s).

(** **  All partitions belonging to the partition tree are unique. **)
Definition noDupPartitionTree s :=
NoDup (getPartitions multiplexer s).

(* 18/06/2024: this consistency prop is false, it IS possible to have a block mapped in a partition and in its
    parent, removing it *)
(** **  In a given partition, all blocks configured
    in the MPU that are not null are accessible blocks belonging to that partition. **)
Definition MPUFromAccessibleBlocks s :=
forall partition block blocksInMPU,
pdentryMPU partition blocksInMPU s ->
In block blocksInMPU ->
block <> nullAddr ->
In block (getAccessibleMappedBlocks partition s).

(** ** Each block in a child partition has a corresponding block in the parent partition
    that contains the same addresses; block which points to the child (in the Shadow 1 structure). **)
Definition sharedBlockPointsToChild s :=
forall parent child addr parentblock sh1entryaddr,
In parent (getPartitions multiplexer s) ->
In child (getChildren parent s) ->
In addr (getUsedPaddr child s) ->
In addr (getAllPaddrAux [parentblock] s) ->
In parentblock (getMappedBlocks parent s) ->
sh1entryAddr parentblock sh1entryaddr s ->
(sh1entryPDchild (CPaddr (parentblock + sh1offset)) child s \/
sh1entryPDflag (CPaddr (parentblock + sh1offset)) true s).

(** ** All accessible addresses
in a partition (union of all addresses contained in the accessible mapped blocks) are
mapped and accessible in their parent. **)
(*Definition accessibleChildPaddrIsAccessibleIntoParent s :=
 forall parent child addr,
In parent (getPartitions multiplexer s) ->
In child (getChildren parent s) ->
In addr (getAccessibleMappedPaddr child s) ->
In addr (getAccessibleMappedPaddr parent s).*)

(** ** All accessible addresses
in a partition (union of all addresses contained in the accessible mapped blocks) are
mapped and accessible in their parent. **)
Definition accessibleParentPaddrIsAccessibleIntoChild s :=
 forall parent child addr,
In parent (getPartitions multiplexer s) ->
In child (getChildren parent s) ->
In addr (getAccessibleMappedPaddr parent s) ->
In addr (getMappedPaddr child s) -> (*hypothesis necessary to say that the address is in a block given to child*)
In addr (getAccessibleMappedPaddr child s).

(** ** The parent of a partition is either null or a partition, but is never equal to the child **)
Definition parentOfPartitionIsPartition s :=
forall (partition : paddr), forall (entry : PDTable),
lookup partition (memory s) beqAddr = Some (PDT entry)
-> (partition <> constantRootPartM
    -> (exists parentEntry, lookup (parent entry) (memory s) beqAddr = Some (PDT parentEntry))
      /\ In (parent entry) (getPartitions multiplexer s)) (*TODO needs partition to be in too?*)
   /\ (partition = constantRootPartM
    -> parent entry = nullAddr)
   /\ parent entry <> partition.

(*TODO put that elsewhere; in StateLib?*)
Fixpoint isListOfKernelsAux kernList initKern s :=
match kernList with
| [] => True
| kern::nextKernList => lookup (CPaddr (initKern + nextoffset)) (memory s) beqAddr = Some (PADDR kern)
                       /\ initKern + nextoffset <= maxAddr
                       /\ kern <> nullAddr (*do we want that?*)
                       /\ isListOfKernelsAux nextKernList kern s
end.

Definition isListOfKernels kernList idPD s :=
match kernList with
| [] => True
| kern::nextKernList => exists pdentry, lookup idPD (memory s) beqAddr = Some (PDT pdentry)
                          /\ structure pdentry <> nullAddr /\ structure pdentry = kern
                          /\ isListOfKernelsAux nextKernList kern s
end.

(** ** The number of kernels is bounded by the variable maxNbPrepare **)
Definition maxNbPrepareIsMaxNbKernels s :=
forall (partition : paddr) (kernList: list paddr),
isListOfKernels kernList partition s -> length kernList <= maxNbPrepare.

(*Newly changed*)
(** ** In any partition that is not the root, for any block whose field origin is equal to its start address and
whose field next is null, we have a block in the parent partition with the same start and end addresses **)
Definition adressesRangePreservedIfOriginAndNextOk s :=
forall partition pdentry block scentryaddr start endaddr,
In partition (getPartitions multiplexer s)
-> In block (getMappedBlocks partition s)
-> isBE block s
-> bentryStartAddr block start s
-> bentryEndAddr block endaddr s
-> bentryPFlag block true s
-> scentryaddr = CPaddr (block + scoffset)
-> scentryOrigin scentryaddr start s
-> scentryNext scentryaddr nullAddr s
-> lookup partition (memory s) beqAddr = Some (PDT pdentry)
-> partition <> constantRootPartM
-> exists blockParent,
    In blockParent (getMappedBlocks (parent pdentry) s)
    /\ isBE blockParent s
    /\ bentryStartAddr blockParent start s
    /\ bentryEndAddr blockParent endaddr s.

(* New, gives the properties of the origin field *)
(** ** In any partition that is not the root, the origin field of any block corresponds to the start address of
        the the block in the partition's parent which contains at least the same addresses ** **)
Definition originIsParentBlocksStart s :=
forall partition pdentry block scentryaddr scorigin,
In partition (getPartitions multiplexer s)
-> lookup partition (memory s) beqAddr = Some (PDT pdentry)
-> In block (getMappedBlocks partition s)
-> scentryaddr = CPaddr (block + scoffset)
-> scentryOrigin scentryaddr scorigin s
-> (partition <> constantRootPartM
    -> exists blockParent,
        In blockParent (getMappedBlocks (parent pdentry) s)
        /\ bentryStartAddr blockParent scorigin s
        /\ (forall addr, In addr (getAllPaddrAux [block] s) -> In addr (getAllPaddrAux [blockParent] s)))
    /\ (forall startaddr, bentryStartAddr block startaddr s -> scorigin <= startaddr).

(* New, gives some properties of the next field *)
(** ** In any partition that is not the root, if the next field of a block is not null, then the end address of
        the block in the partition's parent which contains at least the same addresses is strictly higher than
        the end address of the block ** **)
Definition nextImpliesBlockWasCut s :=
forall partition pdentry block scentryaddr scnext endaddr,
In partition (getPartitions multiplexer s)
-> lookup partition (memory s) beqAddr = Some (PDT pdentry)
-> In block (getMappedBlocks partition s)
-> bentryEndAddr block endaddr s
-> scentryaddr = CPaddr (block + scoffset)
-> scnext <> nullAddr
-> scentryNext scentryaddr scnext s
-> partition <> constantRootPartM
-> exists blockParent endParent,
    In blockParent (getMappedBlocks (parent pdentry) s)
    /\ bentryEndAddr blockParent endParent s
    /\ endaddr < endParent
    /\ (forall addr, In addr (getAllPaddrAux [block] s) -> In addr (getAllPaddrAux [blockParent] s)).

(* New, gives a property of the PDchild field *)
(** In any partition, if the PDChild field of a block is null, then none of the addresses of that block are
    shared with a child of the partition **)
Definition noChildImpliesAddressesNotShared s :=
forall partition pdentry block sh1entryaddr,
In partition (getPartitions multiplexer s)
-> lookup partition (memory s) beqAddr = Some (PDT pdentry)
-> In block (getMappedBlocks partition s)
-> sh1entryaddr = CPaddr (block + sh1offset)
-> sh1entryPDchild sh1entryaddr nullAddr s
-> (forall child addr,
      In child (getChildren partition s)
      -> In addr (getAllPaddrAux [block] s)
      -> ~ In addr (getMappedPaddr child s)).

(* Not strong enough to be a consistency property, but useful, so we keep it here *)
(** ** All adresses mapped in a partition are mapped into its parent **)
Definition childPaddrIsIntoParent s :=
 forall parent child addr,
In parent (getPartitions multiplexer s) ->
In child (getChildren parent s) ->
In addr (getMappedPaddr child s) ->
In addr (getMappedPaddr parent s).

(* Compensates the loss of information when replacing accessibleChildPaddrIsAccessibleIntoParent by
   accessibleParentPaddrIsAccessibleIntoChild *)
(** ** For any block b in a partition, there exists a block in the partition's parent that includes b ** **)
Definition blockInChildHasAtLeastEquivalentBlockInParent s :=
  forall parent child block startChild endChild,
In parent (getPartitions multiplexer s) ->
In child (getChildren parent s) ->
In block (getMappedBlocks child s) ->
bentryStartAddr block startChild s ->
bentryEndAddr block endChild s ->
bentryPFlag block true s ->
exists blockParent startParent endParent,
  In blockParent (getMappedBlocks parent s)
  /\ bentryStartAddr blockParent startParent s
  /\ bentryEndAddr blockParent endParent s
  /\ startParent <= startChild
  /\ endParent >= endChild.

(* Gives properties on a block in a given partition's parent *)
(** ** For any block mapped in a partition p, the block defined by blockInChildHasAtLeastEquivalentBlockInParent
       in p has the following properties:
        - it is not a partition descriptor in the parent
        - the corresponding PDchild field is not null
        - the corresponding inChildLocation field is not null and points to the block in p if the left bound is
          the same
        - if the block has been cut in p, then it is not accessible in its parent ** **)
Definition childsBlocksPropsInParent s :=
forall child parentPart blockChild startChild endChild blockParent startParent endParent,
In parentPart (getPartitions multiplexer s) ->
In child (getChildren parentPart s) ->
In blockChild (getMappedBlocks child s) ->
bentryStartAddr blockChild startChild s ->
bentryEndAddr blockChild endChild s ->
bentryPFlag blockChild true s ->
In blockParent (getMappedBlocks parentPart s) ->
bentryStartAddr blockParent startParent s ->
bentryEndAddr blockParent endParent s ->
bentryPFlag blockParent true s ->
startParent <= startChild ->
endParent >= endChild ->
false = checkChild blockParent s (CPaddr (blockParent + sh1offset))
/\ (forall childGlobalID,
      sh1entryPDchild (CPaddr (blockParent + sh1offset)) childGlobalID s
      -> childGlobalID <> nullAddr)
/\ (forall blockIDInChild,
      sh1entryInChildLocation (CPaddr (blockParent + sh1offset)) blockIDInChild s
      -> (blockIDInChild <> nullAddr
          /\ (startParent = startChild -> blockIDInChild = blockChild)))
/\ ((startParent <> startChild \/ endParent <> endChild) -> bentryAFlag blockParent false s).

(* Not a consistency property, but a partial version of the previous one, to be used in some proofs where the
    property stays true for all pairs of partitions except for one *)
Definition childsBlocksPropsInParentPartial partition s :=
forall child parentPart blockChild startChild endChild blockParent startParent endParent,
parentPart <> partition ->
In parentPart (getPartitions multiplexer s) ->
In child (getChildren parentPart s) ->
In blockChild (getMappedBlocks child s) ->
bentryStartAddr blockChild startChild s ->
bentryEndAddr blockChild endChild s ->
bentryPFlag blockChild true s ->
In blockParent (getMappedBlocks parentPart s) ->
bentryStartAddr blockParent startParent s ->
bentryEndAddr blockParent endParent s ->
bentryPFlag blockParent true s ->
startParent <= startChild ->
endParent >= endChild ->
false = checkChild blockParent s (CPaddr (blockParent + sh1offset))
/\ (forall childGlobalID,
      sh1entryPDchild (CPaddr (blockParent + sh1offset)) childGlobalID s
      -> childGlobalID <> nullAddr)
/\ (forall blockIDInChild,
      sh1entryInChildLocation (CPaddr (blockParent + sh1offset)) blockIDInChild s
      -> (blockIDInChild <> nullAddr
          /\ (startParent = startChild -> blockIDInChild = blockChild)))
/\ ((startParent <> startChild \/ endParent <> endChild) -> bentryAFlag blockParent false s).

Definition childsBlocksPropsInParentLight s :=
forall child parentPart blockChild startChild endChild blockParent startParent endParent,
In parentPart (getPartitions multiplexer s) ->
In child (getChildren parentPart s) ->
In blockChild (getMappedBlocks child s) ->
bentryStartAddr blockChild startChild s ->
bentryEndAddr blockChild endChild s ->
bentryPFlag blockChild true s ->
In blockParent (getMappedBlocks parentPart s) ->
bentryStartAddr blockParent startParent s ->
bentryEndAddr blockParent endParent s ->
bentryPFlag blockParent true s ->
startParent <= startChild ->
endParent >= endChild ->
false = checkChild blockParent s (CPaddr (blockParent + sh1offset)).

(* Ensures that the partition tree is acyclic *)
(** ** Given a partition p and its parent, there is no chain of partitions that contains p and such that the
       parent is the first element and each element is the parent of the previous one ** **)
Definition partitionTreeIsTree s :=
forall child pdparent parentsList,
child <> constantRootPartM
-> In child (getPartitions multiplexer s)
-> pdentryParent child pdparent s
-> isParentsList s parentsList pdparent
-> ~ In child parentsList.

Definition kernelEntriesAreValid s :=
forall kernel index,
isKS kernel s
-> index <= CIndex (kernelStructureEntriesNb - 1)
-> isBE (CPaddr (kernel + index)) s.

Definition nextKernelIsValid s :=
forall kernel,
isKS kernel s
-> kernel + nextoffset <= maxAddr
    /\ exists nextAddr, (forall Hp,
          lookup {| p:= kernel+nextoffset; Hp:= Hp |} (memory s) beqAddr = Some(PADDR nextAddr))
          /\ (isKS nextAddr s \/ nextAddr = nullAddr).

Definition noDupListOfKerns s :=
forall partition kernList,
isListOfKernels kernList partition s -> NoDup kernList.

Definition MPUsizeIsBelowMax s :=
forall partition MPUlist,
pdentryMPU partition MPUlist s
-> length MPUlist <= MPURegionsNb.

Definition blocksAddressesTypes s :=
forall block startaddr endaddr,
bentryStartAddr block startaddr s
-> bentryEndAddr block endaddr s
-> (isKS startaddr s
      /\ (forall addr, In addr (getAllPaddrBlock startaddr endaddr)
          -> (isBE addr s \/ isSHE addr s \/ isSCE addr s))
    \/ isPDT startaddr s
      /\ (forall addr, In addr (getAllPaddrBlock startaddr endaddr) /\ addr <> startaddr
          -> lookup addr (memory s) beqAddr = None)
    \/ forall addr, In addr (getAllPaddrBlock startaddr endaddr)
          -> lookup addr (memory s) beqAddr = None).

Definition notPDTIfNotPDflag s :=
forall block startaddr sh1entryaddr,
bentryStartAddr block startaddr s
-> sh1entryAddr block sh1entryaddr s
-> sh1entryPDflag sh1entryaddr false s
-> ~ isPDT startaddr s.

Definition kernelsAreNotAccessible s :=
forall block startaddr,
bentryStartAddr block startaddr s
-> isKS startaddr s
-> bentryAFlag block false s.

Definition nextKernAddrIsInSameBlock s :=
forall block kernel startaddr endaddr,
bentryStartAddr block startaddr s
-> bentryEndAddr block endaddr s
-> isKS kernel s
-> In (CPaddr (kernel + nextoffset)) (getAllPaddrBlock startaddr endaddr)
-> kernel = startaddr.


(** ** First batch of consistency properties *)
Definition consistency1 s :=
nullAddrExists s /\
wellFormedFstShadowIfBlockEntry s /\
PDTIfPDFlag s /\
AccessibleNoPDFlag s /\
FirstFreeSlotPointerIsBEAndFreeSlot s /\
multiplexerIsPDT s /\
currentPartitionInPartitionsList s /\
wellFormedShadowCutIfBlockEntry s /\
BlocksRangeFromKernelStartIsBE s /\
KernelStructureStartFromBlockEntryAddrIsKS s /\
sh1InChildLocationIsBE s /\
StructurePointerIsKS s /\
NextKSIsKS s /\
NextKSOffsetIsPADDR s /\
NoDupInFreeSlotsList s /\
freeSlotsListIsFreeSlot s /\
DisjointFreeSlotsLists s /\
inclFreeSlotsBlockEntries s /\
DisjointKSEntries s /\
noDupPartitionTree s /\
isParent s /\
isChild s /\
noDupKSEntriesList s /\
noDupMappedBlocksList s /\
wellFormedBlock s /\
(*MPUFromAccessibleBlocks s /\*)
parentOfPartitionIsPartition s /\
NbFreeSlotsISNbFreeSlotsInList s /\
maxNbPrepareIsMaxNbKernels s /\
blockInChildHasAtLeastEquivalentBlockInParent s /\
partitionTreeIsTree s /\
kernelEntriesAreValid s /\
nextKernelIsValid s /\
noDupListOfKerns s /\
MPUsizeIsBelowMax s /\
originIsParentBlocksStart s /\
nextImpliesBlockWasCut s.

(** ** Second batch of consistency properties *)
Definition consistency2 s :=
noDupUsedPaddrList s /\
accessibleParentPaddrIsAccessibleIntoChild s /\
sharedBlockPointsToChild s /\
adressesRangePreservedIfOriginAndNextOk s /\
childsBlocksPropsInParent s /\
noChildImpliesAddressesNotShared s.

(** ** Conjunction of all consistency properties *)
Definition consistency s :=
consistency1 s /\ consistency2 s.
