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

(**  * Summary
    In this file we formalize and prove all invariants of the MAL and MALInternal functions *)
Require Import Model.ADT Model.Monad Model.Lib
               Model.MAL.
Require Import Core.Internal.
Require Import Proof.Consistency Proof.DependentTypeLemmas Proof.Hoare
               Proof.Isolation Proof.StateLib Proof.WeakestPreconditions.
Require Import Coq.Logic.ProofIrrelevance Lia Setoid Compare_dec EqNat List Bool.
Require Import InternalLemmas.

Module WP := WeakestPreconditions.
Module IL := InternalLemmas.

(* COPY *)
Lemma getCurPartition P :
{{fun s => P s}} MAL.getCurPartition
{{fun (pd : paddr) (s : state) => P s /\ pd = currentPartition s }}.
Proof.
eapply WP.weaken.
eapply WeakestPreconditions.getCurPartition .
cbn. intros . intuition.
Qed.

Module Index.
(* COPY*)
Lemma ltb index1 index2 (P : state -> Prop):
{{ fun s : state => P s }} MALInternal.Index.ltb index1 index2
{{ fun b s => P s /\ b = StateLib.Index.ltb index1 index2}}.
Proof.
eapply WP.weaken.
eapply  WeakestPreconditions.Index.ltb.
intros. simpl. split;trivial.
Qed.

(*COPY *)
Lemma leb index1 index2 (P : state -> Prop):
{{ fun s : state => P s }} MALInternal.Index.leb index1 index2
{{ fun b s => P s /\ b = StateLib.Index.leb index1 index2}}.
Proof.
eapply WP.weaken.
eapply  WeakestPreconditions.Index.leb.
intros. simpl. split;trivial.
Qed.

(* partial DUP *)
Lemma zero P :
{{fun s => P s }} MALInternal.Index.zero
{{fun (idx0 : index) (s : state) => P s  /\ idx0 = CIndex 0 }}.
Proof.
unfold MALInternal.Index.zero.
eapply WP.weaken.
eapply WP.ret .
intros. simpl.
intuition.
Qed.

(* COPY *)
Lemma succ (idx : index ) P :
{{fun s => P s  /\ idx + 1 <= maxIdx }} MALInternal.Index.succ idx
{{fun (idxsuc : index) (s : state) => P s  /\ StateLib.Index.succ idx = Some idxsuc }}.
Proof.
eapply WP.weaken.
eapply  WeakestPreconditions.Index.succ.
cbn.
intros.
split.
intuition.
split. intuition.
unfold StateLib.Index.succ.
subst.
destruct (lt_dec idx maxIdx) ; intuition ; try lia.
assert (l=H1).
apply proof_irrelevance.
f_equal. f_equal.
apply proof_irrelevance.
Qed.

(* COPY *)
Lemma pred (idx : index ) P :
{{fun s => P s  /\ idx > 0}} MALInternal.Index.pred idx
{{fun (idxpred : index) (s : state) => P s  /\ StateLib.Index.pred idx = Some idxpred }}.
Proof.
eapply WP.weaken.
eapply  WeakestPreconditions.Index.pred.
cbn.
intros.
split.
intuition.
intros.
split. intuition.
unfold StateLib.Index.pred.
subst.
destruct (gt_dec idx 0).
f_equal.
f_equal.
apply proof_irrelevance.
subst.
intuition.
Qed.
End Index.

Module Paddr.
(* DUP *)
Lemma leb addr1 addr2 (P : state -> Prop):
{{ fun s : state => P s }} MALInternal.Paddr.leb addr1 addr2
{{ fun b s => P s /\ b = StateLib.Paddr.leb addr1 addr2}}.
Proof.
eapply WP.weaken.
eapply  WeakestPreconditions.Paddr.leb.
intros. simpl. split;trivial.
Qed.

(* DUP *)
Lemma ltb addr1 addr2 (P : state -> Prop):
{{ fun s : state => P s }} MALInternal.Paddr.ltb addr1 addr2
{{ fun b s => P s /\ b = StateLib.Paddr.ltb addr1 addr2}}.
Proof.
eapply WP.weaken.
eapply  WeakestPreconditions.Paddr.ltb.
intros. simpl. split;trivial.
Qed.

(* DUP de pred *)
Lemma subPaddr  (addr1 addr2 : paddr ) P :
{{fun s => P s  /\ addr1 >= 0 /\ addr2 >= 0 /\ addr1 - addr2 <= maxIdx}}
MALInternal.Paddr.subPaddr addr1 addr2
{{fun (idxsub : index) (s : state) => P s  /\ StateLib.Paddr.subPaddr addr1 addr2 = Some idxsub }}.
Proof.
eapply WP.weaken.
eapply  WeakestPreconditions.Paddr.subPaddr.
cbn.
intros.
split.
intuition.
intros.
split. intuition.
unfold StateLib.Paddr.subPaddr.
subst.
destruct (le_dec (addr1 - addr2) maxIdx).
split. intuition. intuition.
f_equal.
f_equal.
apply proof_irrelevance.
subst.
intuition.
Qed.

(* DUP*)
Lemma subPaddrIdx  (addr : paddr) (idx: index) (P: state -> Prop) :
{{ fun s : state => P s /\ addr >= 0 /\ idx >= 0 /\ addr - idx <= maxAddr (*/\ forall Hp : n - m < maxAddr,
                   P {| p := n -m; Hp := Hp |} s*) }}
MALInternal.Paddr.subPaddrIdx addr idx
{{fun (paddrsub : paddr) (s : state) => P s  (*/\ StateLib.Paddr.subPaddrIdx addr idx = Some paddrsub *)
/\ CPaddr (addr - idx) = paddrsub}}.
Proof.
eapply WP.weaken.
eapply  WeakestPreconditions.Paddr.subPaddrIdx.
cbn.
intros.
split.
intuition.
intros.
split. intuition.
intros. split. apply H.
unfold CPaddr.
destruct (le_dec (addr - idx) maxAddr). intuition.
f_equal.
f_equal.
apply proof_irrelevance.
subst. exfalso. congruence.
Qed.

(* DUP *)
Lemma pred (addr : paddr ) P :
{{fun s => P s  /\ addr > 0}} MALInternal.Paddr.pred addr
{{fun (addrpred : paddr) (s : state) => P s  /\ StateLib.Paddr.pred addr = Some addrpred }}.
Proof.
eapply WP.weaken.
eapply WeakestPreconditions.Paddr.pred.
cbn.
intros.
split.
intuition.
intros.
split. intuition.
unfold StateLib.Paddr.pred.
subst.
destruct (gt_dec addr 0).
f_equal.
f_equal.
apply proof_irrelevance.
subst.
intuition.
Qed.

End Paddr.

Lemma check32Aligned (addr : paddr ) P :
{{fun s => P s  /\ addr >= 0}} MAL.check32Aligned addr
{{fun (is32aligned : bool) (s : state) => P s  /\ is32aligned = StateLib.is32Aligned addr }}.
Proof.
eapply WP.weaken.
eapply  WeakestPreconditions.check32Aligned.
cbn.
intros.
split.
intuition.
intros. reflexivity.
Qed.

(* DUP of getDefaultVaddr *)
Lemma getMinBlockSize P :
{{fun s => P s}} MALInternal.getMinBlockSize
{{fun minsize s => P s /\ minsize = Constants.minBlockSize }}.
Proof.
unfold MALInternal.getMinBlockSize.
eapply WP.weaken.
eapply WP.ret .
intros.
simpl. intuition.
Qed.

(* DUP *)
Lemma getKernelStructureEntriesNb P :
{{fun s => P s}} MALInternal.getKernelStructureEntriesNb
{{fun entriesnb s => P s /\ entriesnb = (CIndex kernelStructureEntriesNb) }}.
Proof.
unfold MALInternal.getKernelStructureEntriesNb.
eapply WP.weaken.
eapply WP.ret .
intros.
simpl. intuition.
Qed.

(* DUP *)
Lemma getMPURegionsNb P :
{{fun s => P s}} MALInternal.getMPURegionsNb
{{fun mpuregionsnb s => P s /\ mpuregionsnb = (CIndex MPURegionsNb) }}.
Proof.
unfold MALInternal.getMPURegionsNb.
eapply WP.weaken.
eapply WP.ret .
intros.
simpl. intuition.
Qed.


(* DUP *)
Lemma getKernelStructureTotalLength P :
{{fun s => P s}} MALInternal.getKernelStructureTotalLength
{{fun totallength s => P s /\ totallength = Constants.kernelStructureTotalLength }}.
Proof.
unfold MALInternal.getKernelStructureTotalLength.
eapply WP.weaken.
eapply WP.ret .
intros.
simpl. intuition.
Qed.


(* DUP *)
Lemma getPDStructurePointerAddrFromPD (paddr : paddr) (P : state -> Prop) :
{{ fun s => P s /\ isPDT paddr s  }} MAL.getPDStructurePointerAddrFromPD paddr
{{ fun (pointerToKS : ADT.paddr) (s : state) => P s /\ pointerToKS = CPaddr (paddr + Constants.kernelstructureidx) }}.
Proof.
unfold MAL.getPDStructurePointerAddrFromPD.
eapply WP.weaken.
eapply WP.ret .
intros.
simpl. intuition.
Qed.

(* DUP *)
Lemma removeDupIdentity  (l :  list (paddr * value)) :
forall addr1 addr2 , addr1 <> addr2  ->
lookup addr1 (removeDup addr2 l  beqAddr) beqAddr =
lookup addr1 l beqAddr.
Proof.
intros.
induction l.
simpl. trivial.
simpl.
destruct a.
destruct p.
+ case_eq (beqAddr {| p := p; Hp := Hp |} addr2).
  - intros. cbn in *.
    case_eq (PeanoNat.Nat.eqb p addr1).
    * intros.
      apply PeanoNat.Nat.eqb_eq in H0.
      apply PeanoNat.Nat.eqb_eq in H1.
			rewrite H1 in H0.
			apply beqAddrFalse in H.
			unfold beqAddr in H.
			apply PeanoNat.Nat.eqb_neq in H.
			congruence.

		* intros. assumption.
	- intros. simpl.
		case_eq (beqAddr {| p := p; Hp := Hp |} addr1).
		intros. trivial.
		intros. assumption.
Qed.

(* DUP *)
Lemma removeDupRemoved  (l :  list (paddr * value)) :
forall addr,
lookup addr (removeDup addr l  beqAddr) beqAddr = None.
Proof.
intros.
induction l.
simpl. trivial.
simpl.
destruct a.
destruct p.
+ case_eq (beqAddr {| p := p; Hp := Hp |} addr).
  - intros. assumption.
	- intros. simpl.
		case_eq (beqAddr {| p := p; Hp := Hp |} addr).
		intros. exfalso; congruence.
		intros. assumption.
Qed.

Lemma removeDupDupIdentity  (l :  list (paddr * value)) :
forall addr1 addr2 , addr1 <> addr2  ->
lookup addr1
  (removeDup addr2 (removeDup addr2 l beqAddr) beqAddr)
	beqAddr
= lookup addr1 (removeDup addr2 l beqAddr) beqAddr.
Proof.
intros.
induction l.
simpl. trivial.
simpl.
destruct a.
destruct p.
+ case_eq (beqAddr {| p := p; Hp := Hp |} addr2).
  - intros. cbn in *. rewrite removeDupIdentity. reflexivity.
		assumption.
	- intros. simpl.
		rewrite H0. simpl.
		case_eq (beqAddr {| p := p; Hp := Hp |} addr1).
		intros. trivial.
		intros. assumption.
Qed.

(* DUP *)
Lemma isPDTLookupEq (pd : paddr) s :
isPDT pd s -> exists entry : PDTable,
  lookup pd (memory s) beqAddr = Some (PDT entry).
Proof.
intros.
unfold isPDT in H.
destruct (lookup pd (memory s) beqAddr); try now contradict H.
destruct v; try now contradict H.
eexists;repeat split;trivial.
Qed.

(* DUP *)
Lemma isBELookupEq (blockentryaddr : paddr) s :
isBE blockentryaddr s <-> exists entry : BlockEntry,
  lookup blockentryaddr (memory s) beqAddr = Some (BE entry).
Proof.
intros. split.
- intros.
unfold isBE in H.
destruct (lookup blockentryaddr (memory s) beqAddr); try now contradict H.
destruct v; try now contradict H.
eexists;repeat split;trivial.
- intros. unfold isBE. destruct H. rewrite H ; trivial.
Qed.

(* DUP *)
Lemma isSHELookupEq (sh1entryaddr : paddr) s :
isSHE sh1entryaddr s <-> exists entry : Sh1Entry,
  lookup sh1entryaddr (memory s) beqAddr = Some (SHE entry).
Proof.
intros. split.
- intros. unfold isSHE in H.
	destruct (lookup sh1entryaddr (memory s) beqAddr); try now contradict H.
	destruct v; try now contradict H.
	eexists;repeat split;trivial.
- intros. unfold isSHE. destruct H. rewrite H ; trivial.
Qed.

(* DUP *)
Lemma isSCELookupEq (scentryaddr : paddr) s :
isSCE scentryaddr s <-> exists entry : SCEntry,
  lookup scentryaddr (memory s) beqAddr = Some (SCE entry).
Proof.
intros. split.
- intros. unfold isSCE in H.
destruct (lookup scentryaddr (memory s) beqAddr); try now contradict H.
destruct v; try now contradict H.
eexists;repeat split;trivial.
- intros. unfold isSCE. destruct H. rewrite H ; trivial.
Qed.

(* DUP *)
Lemma isKSLookupEq (addr : paddr) s :
isKS addr s -> exists entry : BlockEntry,
  lookup addr (memory s) beqAddr = Some (BE entry)
	/\ entry.(blockindex) = zero.
Proof.
intros.
unfold isKS in H.
destruct (lookup addr (memory s) beqAddr); try now contradict H.
destruct v; try now contradict H.
eexists;repeat split;trivial.
Qed.

(* DUP *)
Lemma isPADDRLookupEq (addr : paddr) s :
isPADDR addr s -> exists addr' : paddr,
  lookup addr (memory s) beqAddr = Some (PADDR addr').
Proof.
intros.
unfold isPADDR in H.
destruct (lookup addr (memory s) beqAddr); try now contradict H.
destruct v; try now contradict H.
eexists;repeat split;trivial.
Qed.

(* DUP*)
Lemma lookupBEntryAccessibleFlag entryaddr s :
forall entry , lookup entryaddr (memory s) beqAddr = Some (BE entry) ->
bentryAFlag entryaddr (accessible entry) s.
Proof.
intros.
unfold bentryAFlag.
rewrite H;trivial.
Qed.

(* DUP*)
Lemma lookupBEntryPresentFlag entryaddr s :
forall entry , lookup entryaddr (memory s) beqAddr = Some (BE entry) ->
bentryPFlag entryaddr (present entry) s.
Proof.
intros.
unfold bentryPFlag.
rewrite H;trivial.
Qed.

(* DUP*)
Lemma lookupBEntryReadFlag entryaddr s :
forall entry , lookup entryaddr (memory s) beqAddr = Some (BE entry) ->
bentryRFlag entryaddr (read entry) s.
Proof.
intros.
unfold bentryRFlag.
rewrite H;trivial.
Qed.

(* DUP*)
Lemma lookupBEntryWriteFlag entryaddr s :
forall entry , lookup entryaddr (memory s) beqAddr = Some (BE entry) ->
bentryWFlag entryaddr (write entry) s.
Proof.
intros.
unfold bentryWFlag.
rewrite H;trivial.
Qed.

(* DUP *)
Lemma lookupBEntryExecFlag entryaddr s :
forall entry , lookup entryaddr (memory s) beqAddr = Some (BE entry) ->
bentryXFlag entryaddr (exec entry) s.
Proof.
intros.
unfold bentryXFlag.
rewrite H;trivial.
Qed.

Lemma lookupBEntryBlockIndex entryaddr s :
forall entry , lookup entryaddr (memory s) beqAddr = Some (BE entry) ->
bentryBlockIndex entryaddr (blockindex entry) s.
Proof.
intros.
unfold bentryBlockIndex.
rewrite H;trivial.
Qed.

(*DUP*)
Lemma lookupBEntryStartAddr entryaddr s :
forall entry , lookup entryaddr (memory s) beqAddr = Some (BE entry) ->
bentryStartAddr entryaddr (startAddr (blockrange entry)) s.
Proof.
intros.
unfold bentryStartAddr.
rewrite H;trivial.
Qed.

(*DUP*)
Lemma lookupBEntryEndAddr entryaddr s :
forall entry , lookup entryaddr (memory s) beqAddr = Some (BE entry) ->
bentryEndAddr entryaddr (endAddr (blockrange entry)) s.
Proof.
intros.
unfold bentryEndAddr.
rewrite H;trivial.
Qed.

(* DUP *)
Lemma lookupSh1EntryPDflag paddr s :
forall entry , lookup paddr (memory s) beqAddr = Some (SHE entry) ->
sh1entryPDflag paddr (PDflag entry) s.
Proof.
intros.
unfold sh1entryPDflag.
rewrite H;trivial.
Qed.

Lemma lookupSh1EntryPDchild paddr s :
forall entry , lookup paddr (memory s) beqAddr = Some (SHE entry) ->
sh1entryPDchild paddr (PDchild entry) s.
Proof.
intros.
unfold sh1entryPDchild.
rewrite H;trivial.
Qed.

Lemma lookupSh1EntryInChildLocation paddr s :
forall entry , lookup paddr (memory s) beqAddr = Some (SHE entry) ->
consistency s ->
sh1entryInChildLocation paddr (inChildLocation entry) s.
Proof.
intros.
unfold sh1entryInChildLocation.
rewrite H;trivial.
intuition.
unfold consistency in *. unfold consistency1 in *.
unfold sh1InChildLocationIsBE in *. intuition.
eauto.
Qed.

Lemma lookupSCEntryOrigin paddr s :
forall entry , lookup paddr (memory s) beqAddr = Some (SCE entry) ->
scentryOrigin paddr (origin entry) s.
Proof.
intros.
unfold scentryOrigin.
rewrite H;trivial.
Qed.

Lemma lookupSCEntryNext paddr s :
forall entry , lookup paddr (memory s) beqAddr = Some (SCE entry) ->
scentryNext paddr (next entry) s.
Proof.
intros.
unfold scentryNext.
rewrite H;trivial.
Qed.

(*DUP*)
Lemma lookupPDEntryFirstFreeSlot entryaddr s :
forall entry , lookup entryaddr (memory s) beqAddr = Some (PDT entry) ->
pdentryFirstFreeSlot entryaddr (firstfreeslot entry) s.
Proof.
intros.
unfold pdentryFirstFreeSlot.
rewrite H;trivial.
Qed.


(*DUP*)
Lemma lookupPDEntryNbFreeSlots entryaddr s :
forall entry , lookup entryaddr (memory s) beqAddr = Some (PDT entry) ->
pdentryNbFreeSlots entryaddr (nbfreeslots entry) s.
Proof.
intros.
unfold pdentryNbFreeSlots.
rewrite H;trivial.
Qed.

(*DUP*)
Lemma lookupPDEntryStructurePointer entryaddr s :
forall entry , lookup entryaddr (memory s) beqAddr = Some (PDT entry) ->
(*consistency s ->*)
pdentryStructurePointer entryaddr (structure entry) s.
Proof.
intros.
unfold pdentryStructurePointer.
rewrite H;trivial.
Qed.

(*DUP*)
Lemma lookupPDEntryNbPrepare entryaddr s :
forall entry , lookup entryaddr (memory s) beqAddr = Some (PDT entry) ->
pdentryNbPrepare entryaddr (nbprepare entry) s.
Proof.
intros.
unfold pdentryNbPrepare.
rewrite H;trivial.
Qed.

(*DUP*)
Lemma lookupPDEntryMPU entryaddr s :
forall entry , lookup entryaddr (memory s) beqAddr = Some (PDT entry) ->
pdentryMPU entryaddr (MPU entry) s.
Proof.
intros.
unfold pdentryMPU.
rewrite H;trivial.
Qed.

(* DUP*)
Lemma lookupSh1EntryAddr entryaddr s :
forall entry , lookup entryaddr (memory s) beqAddr = Some (BE entry) ->
sh1entryAddr entryaddr (CPaddr (entryaddr + sh1offset)) s.
Proof.
intros.
unfold sh1entryAddr.
rewrite H;trivial.
Qed.


(* DUP*)
Lemma lookupSCEntryAddr entryaddr s :
forall entry , lookup entryaddr (memory s) beqAddr = Some (BE entry) ->
scentryAddr entryaddr (CPaddr (entryaddr + scoffset)) s.
Proof.
intros.
unfold scentryAddr.
rewrite H;trivial.
Qed.

(*DUP*)
Lemma lookupPDMPU entryaddr s :
forall entry , lookup entryaddr (memory s) beqAddr = Some (PDT entry) ->
pdentryMPU entryaddr (MPU entry) s.
Proof.
intros.
unfold pdentryMPU.
rewrite H;trivial.
Qed.

(*
(* DUP *)
Lemma readBlockStartFromBlockEntryAddr (paddr : paddr) (P : state -> Prop) :
{{ fun s => P s /\ isBE paddr s  }} MAL.readBlockStartFromBlockEntryAddr paddr
{{ fun (start : ADT.paddr) (s : state) => P s /\ bentryStartAddr paddr start s }}.
Proof.
eapply WP.weaken.
apply WP.getBlockRecordField.
simpl.
intros.
destruct H as (H & Hentry).
apply isBELookupEq in Hentry ;trivial.
destruct Hentry as (entry & Hentry).
exists entry. repeat split;trivial.
apply lookupBEntryStartAddr;trivial.
Qed.


Lemma readBlockEndFromBlockEntryAddr (paddr : paddr) (P : state -> Prop) :
{{ fun s => P s /\ isBE paddr s  }} MAL.readBlockEndFromBlockEntryAddr paddr
{{ fun (endaddr : ADT.paddr) (s : state) => P s /\ bentryEndAddr paddr endaddr s }}.
Proof.
eapply WP.weaken.
apply WP.getBlockRecordField.
simpl.
intros.
destruct H as (H & Hentry).
apply isBELookupEq in Hentry ;trivial.
destruct Hentry as (entry & Hentry).
exists entry. repeat split;trivial.
apply lookupBEntryEndAddr;trivial.
Qed.*)

Lemma readBlockStartFromBlockEntryAddr (paddr : paddr) (P : state -> Prop) :
{{ fun s => P s /\ isBE paddr s  }} MAL.readBlockStartFromBlockEntryAddr paddr
{{ fun (start : ADT.paddr) (s : state) => P s /\ bentryStartAddr paddr start s }}.
Proof.
eapply WP.weaken.
unfold readBlockStartFromBlockEntryAddr.
eapply bindRev.
apply WP.getBlockRecordField.
simpl.
intros.
eapply weaken. apply ret.
intros. simpl. apply H.
intros. simpl.
destruct H as (H & Hentry).
apply isBELookupEq in Hentry ;trivial.
destruct Hentry as (entry & Hentry).
exists entry. repeat split;trivial.
apply lookupBEntryStartAddr;trivial.
Qed.


Lemma readBlockEndFromBlockEntryAddr (paddr : paddr) (P : state -> Prop) :
{{ fun s => P s /\ isBE paddr s  }} MAL.readBlockEndFromBlockEntryAddr paddr
{{ fun (endaddr : ADT.paddr) (s : state) => P s /\ bentryEndAddr paddr endaddr s }}.
Proof.
eapply WP.weaken.
unfold readBlockEndFromBlockEntryAddr.
eapply bindRev.
apply WP.getBlockRecordField.
simpl.
intros.
eapply weaken. apply ret.
intros. simpl. apply H.
intros. simpl.
destruct H as (H & Hentry).
apply isBELookupEq in Hentry ;trivial.
destruct Hentry as (entry & Hentry).
exists entry. repeat split;trivial.
apply lookupBEntryEndAddr;trivial.
Qed.


(* DUP *)
Lemma readBlockAccessibleFromBlockEntryAddr (paddr : paddr) (P : state -> Prop) :
{{ fun s => P s /\ isBE paddr s  }} MAL.readBlockAccessibleFromBlockEntryAddr paddr
{{ fun (isA : bool) (s : state) => P s /\ bentryAFlag paddr isA s }}.
Proof.
eapply WP.weaken.
apply WP.getBlockRecordField.
simpl.
intros.
destruct H as (H & Hentry).
apply isBELookupEq in Hentry ;trivial.
destruct Hentry as (entry & Hentry).
exists entry. repeat split;trivial.
apply lookupBEntryAccessibleFlag;trivial.
Qed.

Lemma readBlockPresentFromBlockEntryAddr (paddr : paddr) (P : state -> Prop) :
{{ fun s => P s /\ isBE paddr s  }} MAL.readBlockPresentFromBlockEntryAddr paddr
{{ fun (isP : bool) (s : state) => P s /\ bentryPFlag paddr isP s }}.
Proof.
eapply WP.weaken.
apply WP.getBlockRecordField.
simpl.
intros.
destruct H as (H & Hentry).
apply isBELookupEq in Hentry ;trivial.
destruct Hentry as (entry & Hentry).
exists entry. repeat split;trivial.
apply lookupBEntryPresentFlag;trivial.
Qed.

(* DUP *)
Lemma readBlockRFromBlockEntryAddr (paddr : paddr) (P : state -> Prop) :
{{ fun s => P s /\ isBE paddr s  }} MAL.readBlockRFromBlockEntryAddr paddr
{{ fun (isR : bool) (s : state) => P s /\ bentryRFlag paddr isR s }}.
Proof.
eapply WP.weaken.
apply WP.getBlockRecordField.
simpl.
intros.
destruct H as (H & Hentry).
apply isBELookupEq in Hentry ;trivial.
destruct Hentry as (entry & Hentry).
exists entry. repeat split;trivial.
apply lookupBEntryReadFlag;trivial.
Qed.

(* DUP *)
Lemma readBlockWFromBlockEntryAddr (paddr : paddr) (P : state -> Prop) :
{{ fun s => P s /\ isBE paddr s  }} MAL.readBlockWFromBlockEntryAddr paddr
{{ fun (isW : bool) (s : state) => P s /\ bentryWFlag paddr isW s }}.
Proof.
eapply WP.weaken.
apply WP.getBlockRecordField.
simpl.
intros.
destruct H as (H & Hentry).
apply isBELookupEq in Hentry ;trivial.
destruct Hentry as (entry & Hentry).
exists entry. repeat split;trivial.
apply lookupBEntryWriteFlag;trivial.
Qed.

(* DUP *)
Lemma readBlockXFromBlockEntryAddr (paddr : paddr) (P : state -> Prop) :
{{ fun s => P s /\ isBE paddr s  }} MAL.readBlockXFromBlockEntryAddr paddr
{{ fun (isX : bool) (s : state) => P s /\ bentryXFlag paddr isX s }}.
Proof.
eapply WP.weaken.
apply WP.getBlockRecordField.
simpl.
intros.
destruct H as (H & Hentry).
apply isBELookupEq in Hentry ;trivial.
destruct Hentry as (entry & Hentry).
exists entry. repeat split;trivial.
apply lookupBEntryExecFlag;trivial.
Qed.

(* DUP *)
Lemma readBlockIndexFromBlockEntryAddr (paddr : paddr) (P : state -> Prop) :
{{ fun s => P s /\ isBE paddr s  }} MAL.readBlockIndexFromBlockEntryAddr paddr
{{ fun (idx : index) (s : state) => P s /\ isBE paddr s /\ bentryBlockIndex paddr idx s }}.
Proof.
eapply WP.weaken.
apply WP.getBlockRecordField.
simpl.
intros.
destruct H as (H & Hentry).
apply isBELookupEq in Hentry ;trivial.
destruct Hentry as (entry & Hentry).
exists entry. repeat split;trivial.
unfold isBE. rewrite Hentry ; trivial.
apply lookupBEntryBlockIndex;trivial.
Qed.

(* DUP *)
Lemma readBlockEntryFromBlockEntryAddr (paddr : paddr) (P : state -> Prop) :
{{ fun s => P s /\ isBE paddr s  }} MAL.readBlockEntryFromBlockEntryAddr paddr
{{ fun (be : BlockEntry) (s : state) => P s /\ isBE paddr s /\ entryBE paddr be s }}.
Proof.
eapply WP.weaken.
apply WP.readBlockEntryFromBlockEntryAddr.
simpl.
intros.
destruct H as (H & Hentry).
apply isBELookupEq in Hentry ;trivial.
destruct Hentry as (entry & Hentry).
exists entry. repeat split;trivial.
unfold isBE. rewrite Hentry ; trivial.
unfold entryBE. rewrite Hentry;trivial.
Qed.

(* DUP *)
Lemma readPDFirstFreeSlotPointer (paddr : paddr) (P : state -> Prop) :
{{ fun s => P s /\ isPDT paddr s  }} MAL.readPDFirstFreeSlotPointer paddr
{{ fun (firstfreeslotaddr : ADT.paddr) (s : state) => P s /\ pdentryFirstFreeSlot paddr firstfreeslotaddr s}}.
Proof.
eapply WP.weaken.
apply WP.getPDTRecordField.
simpl.
intros.
destruct H as (H & Hentry).
apply isPDTLookupEq in Hentry ;trivial.
destruct Hentry as (entry & Hentry).
exists entry. repeat split;trivial.
apply lookupPDEntryFirstFreeSlot;trivial.
Qed.

(* DUP *)
Lemma readPDNbFreeSlots (paddr : paddr) (P : state -> Prop) :
{{ fun s => P s /\ isPDT paddr s  }} MAL.readPDNbFreeSlots paddr
{{ fun (nbfreeslots : index) (s : state) => P s /\ pdentryNbFreeSlots paddr nbfreeslots s }}.
Proof.
eapply WP.weaken.
apply WP.getPDTRecordField.
simpl.
intros.
destruct H as (H & Hentry).
apply isPDTLookupEq in Hentry ;trivial.
destruct Hentry as (entry & Hentry).
exists entry. repeat split;trivial.
apply lookupPDEntryNbFreeSlots;trivial.
Qed.

(* DUP *)
Lemma readPDStructurePointer (pdpaddr : paddr) (P : state -> Prop) :
{{ fun s => P s /\ isPDT pdpaddr s  }} MAL.readPDStructurePointer pdpaddr
{{ fun (structurepointer : paddr) (s : state) => P s /\ pdentryStructurePointer pdpaddr structurepointer s }}.
Proof.
eapply WP.weaken.
apply WP.getPDTRecordField.
simpl.
intros.
destruct H as (H & Hentry).
apply isPDTLookupEq in Hentry ;trivial.
destruct Hentry as (entry & Hentry).
exists entry. intuition.
apply lookupPDEntryStructurePointer;trivial.
Qed.

(* DUP *)
Lemma readPDMPU (pdpaddr : paddr) (P : state -> Prop) :
{{ fun s => P s /\ isPDT pdpaddr s  }} MAL.readPDMPU pdpaddr
{{ fun (MPU : list paddr) (s : state) => P s /\ pdentryMPU pdpaddr MPU s }}.
Proof.
eapply WP.weaken.
apply WP.getPDTRecordField.
simpl.
intros.
destruct H as (H & Hentry).
apply isPDTLookupEq in Hentry ;trivial.
destruct Hentry as (entry & Hentry).
exists entry. repeat split;trivial.
apply lookupPDEntryMPU;trivial.
Qed.

(* DUP *)
Lemma readPDNbPrepare (paddr : paddr) (P : state -> Prop) :
{{ fun s => P s /\ isPDT paddr s  }} MAL.readPDNbPrepare paddr
{{ fun (nbprepare : index) (s : state) => P s /\ pdentryNbPrepare paddr nbprepare s }}.
Proof.
eapply WP.weaken.
apply WP.getPDTRecordField.
simpl.
intros.
destruct H as (H & Hentry).
apply isPDTLookupEq in Hentry ;trivial.
destruct Hentry as (entry & Hentry).
exists entry. repeat split;trivial.
apply lookupPDEntryNbPrepare;trivial.
Qed.

(* DUP *)
Lemma readPDVidt (paddr : paddr) (P : state -> Prop) :
{{ fun s => P s /\ isPDT paddr s  }} MAL.readPDVidt paddr
{{ fun (vidtBlock : ADT.paddr) (s : state) => P s /\ pdentryVidt paddr vidtBlock s }}.
Proof.
eapply WP.weaken.
apply WP.getPDTRecordField.
simpl.
intros.
destruct H as (H & Hentry).
apply isPDTLookupEq in Hentry ;trivial.
destruct Hentry as (entry & Hentry).
exists entry. repeat split;trivial.
apply lookupPDEntryVidt;trivial.
Qed.

(* DUP *)
Lemma readBlockFromPhysicalMPU (pd : paddr) (idx : index) (P : state -> Prop) :
{{ fun s => P s /\ isPDT pd s  }} MAL.readBlockFromPhysicalMPU pd idx
{{ fun (block: paddr) (s : state) => P s /\ pdentryMPUblock pd idx block s }}.
Proof.
unfold readBlockFromPhysicalMPU.
eapply bindRev.
{ (** readPDMPU *)
	eapply weaken. apply readPDMPU.
	intros. simpl. split. apply H. intuition.
}
intro realMPU.
{ (** ret *)
	eapply weaken. apply WeakestPreconditions.ret.
	intros. simpl. intuition.
	unfold pdentryMPUblock. unfold isPDT in *. 	unfold pdentryMPU in *.
	destruct (lookup pd (memory s) beqAddr) ; try (exfalso ; congruence).
	destruct v ; try (exfalso ; congruence).
	subst. reflexivity.
}
Qed.

(* Partial DUP *)
Lemma compareAddrToNull (pa : paddr) (P : state -> Prop):
{{fun s => P s }} compareAddrToNull pa
{{fun (isnull : bool) (s : state) => P s /\
                                       (beqAddr nullAddr pa) = isnull }}.
Proof.
unfold compareAddrToNull.
eapply WP.bindRev.
+ unfold MALInternal.getNullAddr.
  eapply WP.weaken.
  eapply WP.ret . intros.
  instantiate (1:= fun nullPa s => P s /\ beqAddr nullAddr nullPa = true ).
  simpl.
  intuition.
+ intro nullPa. simpl.
  unfold MALInternal.getBeqAddr.
  eapply WP.weaken. eapply WP.ret . intros.
  simpl. intuition.
  unfold beqAddr in *.
	destruct nullAddr, pa.
  simpl in *.
	case_eq p. intros. induction p0. subst. simpl. destruct H1.
	apply PeanoNat.Nat.eqb_sym.
	subst. apply PeanoNat.Nat.eqb_eq in H1.
	rewrite -> H1. trivial.
	intros. apply PeanoNat.Nat.eqb_eq in H1. rewrite <- H1. rewrite ->H. trivial.
Qed.

Lemma getBeqAddr (p1 : paddr)  (p2 : paddr) (P : state -> Prop):
{{fun s => P s }} getBeqAddr p1 p2
{{fun (isequal : bool) (s : state) => P s /\
                                       (beqAddr p1 p2) = isequal }}.
Proof.
	unfold MALInternal.getBeqAddr.
  eapply WP.weaken. eapply WP.ret . intros.
  simpl. intuition.
Qed.

Lemma getBeqIdx (i1 : index)  (i2 : index) (P : state -> Prop):
{{fun s => P s }} getBeqIdx i1 i2
{{fun (isequal : bool) (s : state) => P s /\
                                       (beqIdx i1 i2) = isequal }}.
Proof.
	unfold MALInternal.getBeqIdx.
  eapply WP.weaken. eapply WP.ret . intros.
  simpl. intuition.
Qed.

(* DUP *)
Lemma getMaxNbPrepare P :
{{fun s => P s}} MALInternal.getMaxNbPrepare
{{fun nbprepare s => P s (*/\ entriesnb = (CIndex kernelStructureEntriesNb)*) }}.
Proof.
unfold MALInternal.getMaxNbPrepare.
eapply WP.weaken.
eapply WP.ret.
intros.
simpl. intuition.
Qed.


Lemma compatibleRight (originalright newright : bool) (P : state -> Prop) :
{{fun s => P s}} Internal.compatibleRight originalright newright {{fun iscompatible s => P s}}.
Proof.
unfold Internal.compatibleRight.
case_eq newright.
	- intros.
		eapply WP.weaken.
		eapply WP.ret.
		intros.
 simpl; trivial.
	- intros.
		eapply WP.weaken.
		eapply WP.ret.
		intros.  simpl; trivial.
Qed.

Lemma getBlockEntryAddrFromKernelStructureStart (kernelStartAddr : paddr) (blockidx : index) (P : state -> Prop) :
{{ fun s => P s /\ BlocksRangeFromKernelStartIsBE s
								/\ isKS kernelStartAddr s
								/\ blockidx < kernelStructureEntriesNb}}
MAL.getBlockEntryAddrFromKernelStructureStart kernelStartAddr blockidx
{{ fun (BEAddr : ADT.paddr) (s : state) => P s /\ BEAddr = CPaddr (kernelStartAddr + blkoffset + blockidx)
																						/\ isBE BEAddr s}}.
Proof.
unfold MAL.getBlockEntryAddrFromKernelStructureStart.
eapply weaken. apply ret.
intros. simpl. split. apply H. split. reflexivity.
(* entryaddr is a BE because it's a simple offset from KS start *)
rewrite PeanoNat.Nat.add_0_r.
unfold BlocksRangeFromKernelStartIsBE in *. intuition.
Qed.

Lemma getSh1EntryAddrFromKernelStructureStart (kernelStartAddr : paddr) (blockidx : index) (P : state -> Prop) :
{{ fun s => P s }}
MAL.getSh1EntryAddrFromKernelStructureStart kernelStartAddr blockidx
{{ fun (SHEAddr : ADT.paddr) (s : state) => P s /\ SHEAddr = CPaddr (kernelStartAddr + sh1offset + blockidx) }}.
Proof.
	unfold MAL.getSh1EntryAddrFromKernelStructureStart.
	eapply weaken. apply ret.
	intros. simpl. split. apply H.
	intuition.
Qed.

Lemma getSCEntryAddrFromKernelStructureStart (kernelStartAddr : paddr) (blockidx : index) (P : state -> Prop) :
{{fun s => P s }}
MAL.getSCEntryAddrFromKernelStructureStart kernelStartAddr blockidx
{{ fun scentryaddr s => P s /\ scentryaddr = CPaddr (kernelStartAddr + scoffset + blockidx)
}}.
Proof.
unfold MAL.getSCEntryAddrFromKernelStructureStart.
	eapply weaken. apply ret.
	intros. simpl. split. apply H.
	reflexivity.
Qed.

Lemma getKernelStructureStartAddr  (blockentryaddr : paddr) (blockidx : index)  (P : state -> Prop) :
{{fun s => P s /\ 	KernelStructureStartFromBlockEntryAddrIsKS s
					/\	blockidx < kernelStructureEntriesNb
					/\ blockentryaddr <= maxAddr
					/\	exists entry, lookup blockentryaddr s.(memory) beqAddr = Some (BE entry)
					/\ bentryBlockIndex blockentryaddr blockidx s
}}

MAL.getKernelStructureStartAddr blockentryaddr blockidx
{{ fun KSstart s => P s
									/\ exists entry, lookup KSstart s.(memory) beqAddr = Some (BE entry)
									/\ KSstart = CPaddr (blockentryaddr - blockidx) (* need for getSCEntryAddrFromblockentryAddr *)}}.
Proof.
unfold MAL.getKernelStructureStartAddr.
eapply bindRev.
{ (** MALInternal.Paddr.subPaddrIdx *)
	eapply weaken. apply Paddr.subPaddrIdx.
	intros. simpl. split. apply H. split. lia. split. lia. intuition.
	lia.
}
intro kernelStartAddr. simpl.
{ (** ret *)
	eapply weaken. apply ret.
	intros. simpl. split. apply H.
	intuition. unfold KernelStructureStartFromBlockEntryAddrIsKS in *.
	destruct H5. destruct H4.
	assert(HBEs : isBE blockentryaddr s).
	{ unfold isBE. rewrite H4. trivial. }
	specialize(H0 blockentryaddr blockidx HBEs H5).
	replace kernelStartAddr with (CPaddr (blockentryaddr - blockidx)).
	apply KSIsBE in H0.
	apply isBELookupEq in H0. destruct H0. exists x0.
	intuition.
}
Qed.

Lemma getSh1EntryAddrFromBlockEntryAddr  (blockentryaddr : paddr) (Q : state -> Prop) :
{{fun s => Q s /\  wellFormedFstShadowIfBlockEntry s
					  	 /\ KernelStructureStartFromBlockEntryAddrIsKS s
							 /\ BlocksRangeFromKernelStartIsBE s
							 /\ nullAddrExists s
							 /\ exists entry, lookup blockentryaddr s.(memory) beqAddr = Some (BE entry)}}
MAL.getSh1EntryAddrFromBlockEntryAddr blockentryaddr
{{ fun sh1entryaddr s => Q s /\ exists sh1entry : Sh1Entry,
lookup sh1entryaddr s.(memory) beqAddr = Some (SHE sh1entry)
/\ sh1entryAddr blockentryaddr sh1entryaddr s}}.
Proof.
unfold MAL.getSh1EntryAddrFromBlockEntryAddr.
eapply bindRev.
{ (** MAL.readBlockIndexFromBlockEntryAddr *)
	eapply weaken. apply readBlockIndexFromBlockEntryAddr.
	intros. simpl. split. apply H.
	unfold isBE. intuition. destruct H5. rewrite H4; trivial.
}
intro BlockEntryIndex.
eapply bindRev.
{ (** getKernelStructureStartAddr *)
	eapply weaken. apply getKernelStructureStartAddr.
	intros. simpl. split. exact H.
	intuition.
	unfold bentryBlockIndex in *.
	destruct H7. rewrite H6 in *. subst BlockEntryIndex. apply Hidx.
	destruct blockentryaddr. simpl. trivial.
	destruct H7. exists x. intuition.
}
intro kernelStartAddr.
eapply bindRev.
{ (** MAL.getSh1EntryAddrFromKernelStructureStart *)
	eapply weaken. apply getSh1EntryAddrFromKernelStructureStart.
	intros. simpl. exact H.
}
(* Proof : kernelStartAddr + blockindex is BE, so +sh1offset is SHE *)
intro SHEAddr.
{ (** ret *)
	eapply weaken. apply ret.
	intros. simpl. split. apply H.
	intuition.
	assert(HwellFormedFstShadowIfBlockEntrys' : wellFormedFstShadowIfBlockEntry s)
		by assumption.
	unfold wellFormedFstShadowIfBlockEntry in *.
	assert(HKS : exists entry : BlockEntry,
       lookup kernelStartAddr (memory s) beqAddr = Some (BE entry) /\
       kernelStartAddr = CPaddr (blockentryaddr - BlockEntryIndex)) by trivial.
	destruct HKS as [ksentry (HKSEq & Hlookupks)].
	subst kernelStartAddr. unfold sh1entryAddr.
	assert(Hblock : exists entry : BlockEntry,
       lookup blockentryaddr (memory s) beqAddr = Some (BE entry)) by trivial.
	destruct Hblock as [blockentry Hlookupblocks]. rewrite Hlookupblocks.

	assert(HKSStartFromBlockEntryAddrIsKS : KernelStructureStartFromBlockEntryAddrIsKS s)
		by intuition.
	unfold KernelStructureStartFromBlockEntryAddrIsKS in *.
	assert(HBE : isBE blockentryaddr s) by trivial.
	assert(Hbentryidx : bentryBlockIndex blockentryaddr BlockEntryIndex s) by trivial.
	specialize (HKSStartFromBlockEntryAddrIsKS blockentryaddr BlockEntryIndex
																						HBE Hbentryidx).
	assert(HBlocksRangeFromKernelStartIsBEs : BlocksRangeFromKernelStartIsBE s)
		by trivial.
	unfold BlocksRangeFromKernelStartIsBE in *.
	assert(Hlt : BlockEntryIndex < kernelStructureEntriesNb)
		by (unfold bentryBlockIndex in * ; rewrite Hlookupblocks in * ;
					subst BlockEntryIndex ; eapply Hidx).
	specialize (HBlocksRangeFromKernelStartIsBEs (CPaddr (blockentryaddr - BlockEntryIndex))
																								BlockEntryIndex
																								HKSStartFromBlockEntryAddrIsKS
																								Hlt).
	specialize (HwellFormedFstShadowIfBlockEntrys' (CPaddr (CPaddr (blockentryaddr - BlockEntryIndex) + BlockEntryIndex))
								HBlocksRangeFromKernelStartIsBEs).
	assert(HSHEAddrEq : SHEAddr =
     CPaddr
       (CPaddr (blockentryaddr - BlockEntryIndex) + sh1offset + BlockEntryIndex))
			by trivial.
	unfold CPaddr in HKSEq. unfold CPaddr at 2 in HSHEAddrEq.
	unfold CPaddr at 3 in HwellFormedFstShadowIfBlockEntrys'.

	unfold CPaddr at 2 in HBlocksRangeFromKernelStartIsBEs.
	destruct (le_dec (blockentryaddr - BlockEntryIndex) maxAddr) ; intuition.
	- simpl in *.
		unfold CPaddr at 2 in HwellFormedFstShadowIfBlockEntrys'.
		unfold CPaddr in HBlocksRangeFromKernelStartIsBEs.
		destruct (le_dec (blockentryaddr - BlockEntryIndex + BlockEntryIndex) maxAddr) ; intuition.
		-- simpl in *.
			apply isSHELookupEq in  HwellFormedFstShadowIfBlockEntrys'.
			destruct HwellFormedFstShadowIfBlockEntrys' as [sh1entry Hsh1entry].
			exists sh1entry. subst SHEAddr. 
			assert(HEq : blockentryaddr - BlockEntryIndex + sh1offset + BlockEntryIndex =
										blockentryaddr - BlockEntryIndex + BlockEntryIndex + sh1offset).
			{ rewrite PeanoNat.Nat.add_shuffle0. reflexivity. }
			rewrite HEq in *. rewrite HSHEAddrEq in *. intuition.
			assert(HEq' : blockentryaddr - BlockEntryIndex + BlockEntryIndex + sh1offset = 
									blockentryaddr + sh1offset).
			{
				rewrite PeanoNat.Nat.sub_add. reflexivity.
				assert(blockentryaddr - BlockEntryIndex <= maxAddr) by lia.
				unfold isBE in *.
				destruct (blockentryaddr - BlockEntryIndex) eqn:diff ; intuition.
				- (* False cause BE NULL *)
					unfold nullAddrExists in *. unfold isPADDR in *.
					unfold nullAddr in *.
					unfold CPaddr in *.
					destruct (le_dec 0 maxAddr) ; try(lia).
					assert(HpEq : ADT.CPaddr_obligation_1 0 l1 = ADT.CPaddr_obligation_1 0 l)
						by apply proof_irrelevance.
					rewrite HpEq in *.
					destruct (lookup {| p := 0; Hp := ADT.CPaddr_obligation_1 0 l |} (memory s) beqAddr) ;
						try (exfalso ; congruence).
					destruct v ; try(exfalso ; congruence).
				- lia.
			}
			rewrite HEq'. reflexivity.
			-- (* False cause BE NULL *)
					unfold isBE in *.
					(* DUP *)
					unfold nullAddrExists in *. unfold isPADDR in *.
					unfold nullAddr in *.
					unfold CPaddr in *.
					destruct (le_dec 0 maxAddr) ; try(lia).
					assert(HpEq : forall n Hyp, ADT.CPaddr_obligation_2 n Hyp = ADT.CPaddr_obligation_1 0 l0)
						by (intros; apply proof_irrelevance).
					rewrite HpEq in *.
					destruct (lookup {| p := 0; Hp := ADT.CPaddr_obligation_1 0 l0|} (memory s) beqAddr) ;
						try (exfalso ; congruence).
					destruct v ; try(exfalso ; congruence).
	- (* False cause BE Null *)
		unfold isBE in *.
		(* DUP *)
		unfold nullAddrExists in *. unfold isPADDR in *.
		unfold nullAddr in *.
		unfold CPaddr in *.
		destruct (le_dec 0 maxAddr) ; try(lia).
		assert(HpEq : forall n Hyp, ADT.CPaddr_obligation_2 n Hyp = ADT.CPaddr_obligation_1 0 l)
			by (intros; apply proof_irrelevance).
		rewrite HpEq in *.
		destruct (lookup {| p := 0; Hp := ADT.CPaddr_obligation_1 0 l|} (memory s) beqAddr) ;
			try (exfalso ; congruence).
		destruct v ; try(exfalso ; congruence).
}
Qed.

(* DUP *)
Lemma getNextAddrFromKernelStructureStart  (kernelStartAddr : paddr) (P : state -> Prop) :
{{fun s => P s (*/\ wellFormedNextKSAddrIfKernelStructureStart s *)
					/\ exists entry, lookup kernelStartAddr s.(memory) beqAddr = Some (BE entry)}}
MAL.getNextAddrFromKernelStructureStart kernelStartAddr
{{ fun nextaddr s => P s /\ nextaddr = CPaddr (kernelStartAddr + nextoffset) (*/\ exists entry, lookup nextaddr s.(memory) beqAddr = Some (PADDR entry)
/\ nextKSAddr nextksaddr nextksaddr s
/\ nextksaddr = CPaddr (kernelStartAddr + nextoffset)*)}}.
Proof.
unfold MAL.getNextAddrFromKernelStructureStart.
eapply weaken. apply ret.
intros. simpl. intuition.
Qed.

Lemma readSh1PDChildFromBlockEntryAddr  (blockentryaddr : paddr) (Q : state -> Prop)  :
{{fun s  =>  Q s /\ wellFormedFstShadowIfBlockEntry s /\ KernelStructureStartFromBlockEntryAddrIsKS s
              /\ BlocksRangeFromKernelStartIsBE s /\ nullAddrExists s
              /\ exists entry, lookup blockentryaddr s.(memory) beqAddr = Some (BE entry)}}
MAL.readSh1PDChildFromBlockEntryAddr blockentryaddr
{{fun pdchild s => Q s
										/\ exists sh1entry sh1entryaddr, lookup sh1entryaddr s.(memory) beqAddr = Some (SHE sh1entry)
										/\ sh1entryPDchild sh1entryaddr pdchild s
										/\ sh1entryAddr blockentryaddr sh1entryaddr s}}.
Proof.
unfold MAL.readSh1PDChildFromBlockEntryAddr.
eapply WP.bindRev.
+   eapply WP.weaken. apply getSh1EntryAddrFromBlockEntryAddr.
	intros. simpl. split. apply H. split. apply H.
	split. apply H. split. apply H. split. apply H. intuition.
+	intro sh1entryaddr. simpl.
	eapply bind.
	intros. apply ret.
	eapply weaken. apply getSh1RecordField.
	intros. simpl. destruct H. destruct H0. exists x.
	split. intuition. split. apply H.
	exists x. exists sh1entryaddr. split. apply H0.
	split. apply lookupSh1EntryPDchild. apply H0.
	intuition.
Qed.

(* DUP *)
Lemma readSh1PDFlagFromBlockEntryAddr  (blockentryaddr : paddr) (Q : state -> Prop)  :
{{fun s  =>  Q s /\ consistency s /\ exists entry : BlockEntry, lookup blockentryaddr s.(memory) beqAddr = Some (BE entry)}}
MAL.readSh1PDFlagFromBlockEntryAddr blockentryaddr
{{fun pdflag s => Q s
										/\ exists sh1entry : Sh1Entry, exists sh1entryaddr : paddr, lookup sh1entryaddr s.(memory) beqAddr = Some (SHE sh1entry)
										/\ sh1entryPDflag sh1entryaddr pdflag s
										/\ sh1entryAddr blockentryaddr sh1entryaddr s }}.
Proof.
unfold MAL.readSh1PDFlagFromBlockEntryAddr.
eapply WP.bindRev.
+   eapply WP.weaken. apply getSh1EntryAddrFromBlockEntryAddr.
	intros. simpl. unfold consistency in H. split. apply H. split. apply H.
	split. apply H. split. apply H. split. apply H. intuition.
+	intro sh1entryaddr. simpl.
	eapply bind.
	intros. apply ret.
	eapply weaken. apply getSh1RecordField.
	intros. simpl. destruct H. destruct H0. exists x.
	split. intuition. split. apply H.
	exists x. exists sh1entryaddr. split. apply H0.
	split. apply lookupSh1EntryPDflag. apply H0.
	intuition.
Qed.

(* DUP with deeper changes because of lookupSh1EntryInChildLocation *)
Lemma readSh1InChildLocationFromBlockEntryAddr  (blockentryaddr : paddr) (Q : state -> Prop)  :
{{fun s  =>  Q s /\ consistency s /\ exists entry : BlockEntry, lookup blockentryaddr s.(memory) beqAddr = Some (BE entry)}}
MAL.readSh1InChildLocationFromBlockEntryAddr blockentryaddr
{{fun inchildlocation s => Q s (*/\ consistency s*) (*/\ exists entry, lookup blockentryaddr s.(memory) beqAddr = Some (BE entry)*)
										/\ exists sh1entry : Sh1Entry, exists sh1entryaddr : paddr, lookup sh1entryaddr s.(memory) beqAddr = Some (SHE sh1entry)
										/\ sh1entryInChildLocation sh1entryaddr inchildlocation s}}.
Proof.
unfold readSh1InChildLocationFromBlockEntryAddr.
eapply WP.bindRev.
+   eapply WP.weaken. apply getSh1EntryAddrFromBlockEntryAddr.
	intros. simpl. split. apply H. unfold consistency in H. unfold consistency1 in H.
	intuition.
+	intro sh1entryaddr. simpl.
	eapply bind.
	intros. apply ret.
	eapply weaken. apply getSh1RecordField.
	intros. simpl. destruct H. destruct H0. exists x.
	split. intuition. split. apply H.
	exists x. exists sh1entryaddr. split. apply H0.
	apply lookupSh1EntryInChildLocation. apply H0. intuition.
Qed.


Lemma getSCEntryAddrFromBlockEntryAddr  (blockentryaddr : paddr) (P : state -> Prop) :
{{fun s => P s /\ wellFormedShadowCutIfBlockEntry s
							/\ KernelStructureStartFromBlockEntryAddrIsKS s
							/\ BlocksRangeFromKernelStartIsBE s
							/\ nullAddrExists s
					/\ exists entry, lookup blockentryaddr s.(memory) beqAddr = Some (BE entry)
							 }}
MAL.getSCEntryAddrFromBlockEntryAddr blockentryaddr
{{ fun scentryaddr s => P s /\ exists entry, lookup scentryaddr s.(memory) beqAddr = Some (SCE entry)
																/\ scentryAddr blockentryaddr scentryaddr s
}}.
Proof.
unfold MAL.getSCEntryAddrFromBlockEntryAddr.
eapply bindRev.
{ eapply weaken.
- apply readBlockIndexFromBlockEntryAddr.
- intros. cbn. split. exact H. (* NOTE : Important to propagate the whole property *)
	unfold isBE. destruct H. destruct H0. destruct H1. destruct H2.
	destruct H3. destruct H4. rewrite H4. trivial.
}
intro BlockEntryIndex.
eapply bindRev.
{ (* getKernelStructureStartAddr *)
	eapply weaken. apply getKernelStructureStartAddr.
	intros. simpl. split. exact H. intuition.
	unfold bentryBlockIndex in *. destruct H7. rewrite H6 in *.
	subst BlockEntryIndex. apply Hidx.
	destruct blockentryaddr. simpl. trivial. (* already done in sh1entry *)
	apply isBELookupEq in H0.
	destruct H0. exists x. intuition.
}
intro kernelStartAddr. simpl.
eapply bindRev.
{ (* getSCEntryAddrFromKernelStructureStart *)
	eapply weaken.  apply getSCEntryAddrFromKernelStructureStart.
	intros. simpl. apply H.
}
intro SCEAddr.
{ (** ret *)
	eapply weaken. apply ret.
	intros. simpl.
	split. apply H.
	intuition.
	rewrite H1.
	assert(HKS : exists entry : BlockEntry,
       lookup kernelStartAddr (memory s) beqAddr = Some (BE entry) /\
       kernelStartAddr = CPaddr (blockentryaddr - BlockEntryIndex)) by trivial.
	destruct HKS as [ksentry (HKSEq & Hlookupks)].
	subst kernelStartAddr. unfold scentryAddr.

	assert(HwellFormedShadowCutIfBlockEntry : wellFormedShadowCutIfBlockEntry s)
		by assumption.
	unfold wellFormedFstShadowIfBlockEntry in *.
	assert(Hblock : exists entry : BlockEntry,
       lookup blockentryaddr (memory s) beqAddr = Some (BE entry)) by trivial.
	destruct Hblock as [blockentry Hlookupblocks]. rewrite Hlookupblocks.

	assert(HKSStartFromBlockEntryAddrIsKS : KernelStructureStartFromBlockEntryAddrIsKS s)
		by intuition.
	unfold KernelStructureStartFromBlockEntryAddrIsKS in *.
	assert(HBE : isBE blockentryaddr s) by trivial.
	assert(Hbentryidx : bentryBlockIndex blockentryaddr BlockEntryIndex s) by trivial.
	specialize (HKSStartFromBlockEntryAddrIsKS blockentryaddr BlockEntryIndex
																						HBE Hbentryidx).
	assert(HBlocksRangeFromKernelStartIsBEs : BlocksRangeFromKernelStartIsBE s)
		by trivial.
	unfold BlocksRangeFromKernelStartIsBE in *.
	assert(Hlt : BlockEntryIndex < kernelStructureEntriesNb)
		by (unfold bentryBlockIndex in * ; rewrite Hlookupblocks in * ;
					subst BlockEntryIndex ; eapply Hidx).
	specialize (HBlocksRangeFromKernelStartIsBEs (CPaddr (blockentryaddr - BlockEntryIndex))
																								BlockEntryIndex
																								HKSStartFromBlockEntryAddrIsKS
																								Hlt).
	specialize (HwellFormedShadowCutIfBlockEntry (CPaddr (CPaddr (blockentryaddr - BlockEntryIndex) + BlockEntryIndex))
								HBlocksRangeFromKernelStartIsBEs).
	assert(HSCEAddrEq : SCEAddr =
     CPaddr
       (CPaddr (blockentryaddr - BlockEntryIndex) + scoffset + BlockEntryIndex))
			by trivial.
	unfold CPaddr in HKSEq. unfold CPaddr at 2 in HSCEAddrEq.
	unfold CPaddr at 3 in HwellFormedShadowCutIfBlockEntry.

	unfold CPaddr at 2 in HBlocksRangeFromKernelStartIsBEs.
	destruct (le_dec (blockentryaddr - BlockEntryIndex) maxAddr) ; intuition.
	- simpl in *.
		unfold CPaddr at 2 in HwellFormedShadowCutIfBlockEntry.
		unfold CPaddr in HBlocksRangeFromKernelStartIsBEs.
		destruct (le_dec (blockentryaddr - BlockEntryIndex + BlockEntryIndex) maxAddr) ; intuition.
		-- simpl in *.
			destruct HwellFormedShadowCutIfBlockEntry as [scentryaddr (HSCE & HaddrEq) ].
			apply isSCELookupEq in HSCE. destruct HSCE as [scentry Hscentry].
			exists scentry. subst SCEAddr. subst scentryaddr.
			assert(HEq : blockentryaddr - BlockEntryIndex + scoffset + BlockEntryIndex =
										blockentryaddr - BlockEntryIndex + BlockEntryIndex + scoffset).
			{ rewrite PeanoNat.Nat.add_shuffle0. reflexivity. }
			rewrite HEq in *. rewrite HSCEAddrEq in *. intuition.
			assert(HEq' : blockentryaddr - BlockEntryIndex + BlockEntryIndex + scoffset = 
									blockentryaddr + scoffset).
			{
				rewrite PeanoNat.Nat.sub_add. reflexivity.
				assert(blockentryaddr - BlockEntryIndex <= maxAddr) by lia.
				unfold isBE in *.
				destruct (blockentryaddr - BlockEntryIndex) eqn:diff ; intuition.
				- (* False cause BE NULL *)
					unfold nullAddrExists in *. unfold isPADDR in *.
					unfold nullAddr in *.
					unfold CPaddr in *.
					destruct (le_dec 0 maxAddr) ; try(lia).
					assert(HpEq : ADT.CPaddr_obligation_1 0 l1 = ADT.CPaddr_obligation_1 0 l)
						by apply proof_irrelevance.
					rewrite HpEq in *.
					destruct (lookup {| p := 0; Hp := ADT.CPaddr_obligation_1 0 l |} (memory s) beqAddr) ;
						try (exfalso ; congruence).
					destruct v ; try(exfalso ; congruence).
				- lia.
			}
			rewrite HEq'. reflexivity.
			-- (* False cause BE NULL *)
					unfold isBE in *.
					(* DUP *)
					unfold nullAddrExists in *. unfold isPADDR in *.
					unfold nullAddr in *.
					unfold CPaddr in *.
					destruct (le_dec 0 maxAddr) ; try(lia).
					assert(HpEq : forall n Hyp, ADT.CPaddr_obligation_2 n Hyp = ADT.CPaddr_obligation_1 0 l0)
						by (intros; apply proof_irrelevance).
					rewrite HpEq in *.
					destruct (lookup {| p := 0; Hp := ADT.CPaddr_obligation_1 0 l0|} (memory s) beqAddr) ;
						try (exfalso ; congruence).
					destruct v ; try(exfalso ; congruence).
	- (* False cause BE Null *)
		unfold isBE in *.
		(* DUP *)
		unfold nullAddrExists in *. unfold isPADDR in *.
		unfold nullAddr in *.
		unfold CPaddr in *.
		destruct (le_dec 0 maxAddr) ; try(lia).
		assert(HpEq : forall n Hyp, ADT.CPaddr_obligation_2 n Hyp = ADT.CPaddr_obligation_1 0 l)
			by (intros; apply proof_irrelevance).
		rewrite HpEq in *.
		destruct (lookup {| p := 0; Hp := ADT.CPaddr_obligation_1 0 l|} (memory s) beqAddr) ;
			try (exfalso ; congruence).
		destruct v ; try(exfalso ; congruence).
}
Qed.

(* DUP *)
Lemma readSCOriginFromBlockEntryAddr  (blockentryaddr : paddr) (Q : state -> Prop)  :
{{fun s  =>  Q s /\ wellFormedShadowCutIfBlockEntry s /\ KernelStructureStartFromBlockEntryAddrIsKS s
              /\ BlocksRangeFromKernelStartIsBE s /\ nullAddrExists s
              /\ exists entry : BlockEntry, lookup blockentryaddr s.(memory) beqAddr = Some (BE entry)}}
MAL.readSCOriginFromBlockEntryAddr blockentryaddr
{{fun origin s => Q s (*/\ consistency s*) (*/\ exists entry, lookup blockentryaddr s.(memory) beqAddr = Some (BE entry)*)
										/\ scentryOrigin (CPaddr (blockentryaddr + scoffset)) origin s}}.
Proof.
unfold MAL.readSCOriginFromBlockEntryAddr.
eapply WP.bindRev.
+ eapply WP.weaken. apply getSCEntryAddrFromBlockEntryAddr.
	intros. simpl. unfold consistency in H. split. apply H. split. apply H.
	split. apply H. split. apply H. split. apply H. intuition.
+	intro scentryaddr. simpl. eapply bind.
	intros. apply ret.
	eapply weaken. apply getSCRecordField.
	intros. simpl. destruct H. destruct H0. exists x.
	split. intuition. split. apply H.
	destruct H0. unfold scentryAddr in *. destruct H as (HQ & _ & _ & _ & _ & [bentry HBE]). rewrite HBE in *.
	apply lookupSCEntryOrigin. subst scentryaddr. assumption.
Qed.

(* DUP with changes in scentryNext + lookupSCEntryNext + changes of function names*)
Lemma readSCNextFromBlockEntryAddr  (blockentryaddr : paddr) (Q : state -> Prop)  :
{{fun s  =>  Q s /\ wellFormedShadowCutIfBlockEntry s /\ KernelStructureStartFromBlockEntryAddrIsKS s
            /\ BlocksRangeFromKernelStartIsBE s /\ nullAddrExists s
            /\ exists entry : BlockEntry, lookup blockentryaddr s.(memory) beqAddr = Some (BE entry)}}
MAL.readSCNextFromBlockEntryAddr blockentryaddr
{{fun next s => Q s
					/\ scentryNext (CPaddr (blockentryaddr + scoffset)) next s}}.
Proof.
unfold MAL.readSCNextFromBlockEntryAddr.
eapply WP.bindRev.
+ eapply WP.weaken. apply getSCEntryAddrFromBlockEntryAddr.
	intros s Hprops. simpl. unfold consistency1 in Hprops. split. apply Hprops. split. apply Hprops.
	split. apply Hprops. split. apply Hprops. split. apply Hprops. intuition.
+	intro scentryaddr. simpl. eapply bind.
	intros. apply ret.
	eapply weaken. apply getSCRecordField.
	intros s Hprops. simpl. destruct Hprops as (Hprops & Hsce). destruct Hsce as [scentry (HlookupSce & Hsce)].
  exists scentry. split. assumption. split. apply Hprops.
	apply lookupSCEntryNext. unfold scentryAddr in Hsce.
  destruct (lookup blockentryaddr (memory s) beqAddr); try(exfalso; congruence).
  destruct v; try(exfalso; congruence). subst scentryaddr. assumption.
Qed.

Lemma readNextFromKernelStructureStart (structurepaddr : paddr) (P : state -> Prop)  :
{{fun s  =>  P s /\ NextKSOffsetIsPADDR s /\
						isKS structurepaddr s
             }}
MAL.readNextFromKernelStructureStart structurepaddr
{{fun nextkernelstructure s => P s
																/\ exists offset, (offset = CPaddr (structurepaddr + nextoffset)
																/\ nextKSAddr structurepaddr offset s)
																/\ nextKSentry offset nextkernelstructure s}}.
Proof.
unfold MAL.readNextFromKernelStructureStart.
eapply WP.bindRev.
+   eapply WP.weaken. apply getNextAddrFromKernelStructureStart.
	intros. simpl. split. apply H. intuition. apply isKSLookupEq in H2.
	destruct H2. exists x. intuition.
+ intro nextaddr.
	simpl. eapply bind.
	intros. apply ret.
	eapply weaken. apply WP.readNextFromKernelStructureStart2.
	intros. simpl. intuition. subst.
	unfold NextKSOffsetIsPADDR in H0.
	specialize (H0 structurepaddr (CPaddr (structurepaddr + nextoffset)) H3).
	unfold isKS in *. unfold nextKSAddr in H0.
	destruct(lookup structurepaddr (memory s) beqAddr) eqn:Hlookup ; intuition.
	destruct v eqn:Hv ; intuition.
	apply isPADDRLookupEq in H0. destruct H0.
	exists x. intuition.
	exists (CPaddr (structurepaddr + nextoffset)). intuition.
	unfold nextKSAddr. rewrite Hlookup ; trivial.
	unfold nextKSentry. subst. rewrite H0 ; trivial.
Qed.

Lemma checkRights p r w e P :
{{ fun s => P s /\ exists entry, lookup p s.(memory) beqAddr = Some (BE entry)}}
Internal.checkRights  p r w e
{{ fun rights s => P s /\ exists entry, lookup p s.(memory) beqAddr = Some (BE entry)  }}.
Proof.
unfold checkRights.
case_eq r.
2: {intros. simpl.
	eapply WP.weaken.
eapply WP.ret.
simpl; trivial.
}
 intros. simpl.
	eapply WP.bindRev.
{
	eapply WP.weaken.
	eapply readBlockXFromBlockEntryAddr.
	intuition. apply H1.

unfold isBE.
	destruct H2. destruct (lookup p (memory s) beqAddr). destruct v.
	trivial. repeat congruence. congruence. congruence. congruence. congruence.
}
	intro xoriginal.
 	eapply WP.bindRev.
{
		eapply WP.weaken.
	eapply readBlockWFromBlockEntryAddr.
	intuition. apply H1.

	unfold bentryXFlag in H2.

unfold isBE;
destruct (lookup p (memory s) beqAddr). destruct v.
destruct xoriginal.  destruct exec. try repeat trivial. repeat trivial. trivial. trivial. trivial.
trivial. trivial. trivial.
}
	intro woriginal.
 	eapply WP.bindRev.
{ case_eq e.
	intros.
	intros;	apply compatibleRight.
	intros; apply compatibleRight.
}
	intro isCompatibleWithX.
 	eapply WP.bindRev.
{ case_eq w.
	intros;	apply compatibleRight.
	intros; apply compatibleRight.
}
	intro isCompatibleWithW.
	simpl in *.
	destruct (isCompatibleWithX && isCompatibleWithW).
- (* Dup *)
	simpl.
	eapply WP.weaken.
	eapply WP.ret.
	intuition.
	unfold bentryWFlag in H2.
	destruct (lookup p (memory s) beqAddr) eqn:lookup.
	destruct v eqn:V.
	exists b. reflexivity. intuition. intuition. intuition. intuition. intuition.
- simpl.
	eapply WP.weaken.
	eapply WP.ret.
	intuition.
	unfold bentryWFlag in H2.
	destruct (lookup p (memory s) beqAddr) eqn:lookup.
	destruct v eqn:V.
	exists b. reflexivity. intuition. intuition. intuition. intuition. intuition.
Qed.

Lemma writeSh1PDChildFromBlockEntryAddr (blockentryaddr pdchild : paddr)  (P : unit -> state -> Prop) :
{{fun  s => exists entry , lookup (CPaddr (blockentryaddr + sh1offset)) s.(memory) beqAddr = Some (SHE entry) /\
P tt {|
  currentPartition := currentPartition s;
  memory := add (CPaddr (blockentryaddr + sh1offset))
              (SHE {|	PDchild := pdchild;
											PDflag := entry.(PDflag);
											inChildLocation := entry.(inChildLocation) |})
              (memory s) beqAddr |}
/\ isBE blockentryaddr s
/\ wellFormedFstShadowIfBlockEntry s
/\ KernelStructureStartFromBlockEntryAddrIsKS s
/\ BlocksRangeFromKernelStartIsBE s
/\ nullAddrExists s
 }}
MAL.writeSh1PDChildFromBlockEntryAddr blockentryaddr pdchild  {{P}}.
Proof.
eapply bindRev.
{ eapply weaken. apply getSh1EntryAddrFromBlockEntryAddr.
	intros. simpl. split. apply H. destruct H. intuition.
 apply isBELookupEq in H1 ;trivial.
}
	intro Sh1EAddr.
{ cbn. eapply weaken. eapply WP.writeSh1PDChildFromBlockEntryAddr2.	cbn.
	intros. simpl. destruct H. destruct H.
	intuition.
	unfold sh1entryAddr in *.
	apply isBELookupEq in H2. destruct H2.
	rewrite H2 in H0.
	destruct H0. destruct H0.
	subst. exists x. split.
	assumption. assumption.
}
Qed.


(* DUP*)
Lemma writeSh1InChildLocationFromBlockEntryAddr (blockentryaddr newinchildlocation : paddr)  (P : unit -> state -> Prop) :
{{fun  s => exists entry , lookup (CPaddr (blockentryaddr + sh1offset)) s.(memory) beqAddr = Some (SHE entry) /\
P tt {|
  currentPartition := currentPartition s;
  memory := add (CPaddr (blockentryaddr + sh1offset))
              (SHE {|	PDchild := entry.(PDchild);
											PDflag := entry.(PDflag);
											inChildLocation := newinchildlocation |})
              (memory s) beqAddr |}
/\ isBE blockentryaddr s
/\ wellFormedFstShadowIfBlockEntry s
/\ KernelStructureStartFromBlockEntryAddrIsKS s
/\ BlocksRangeFromKernelStartIsBE s
/\ nullAddrExists s
 }}
MAL.writeSh1InChildLocationFromBlockEntryAddr blockentryaddr newinchildlocation  {{P}}.
Proof.
eapply bindRev.
{ eapply weaken. apply getSh1EntryAddrFromBlockEntryAddr.
	intros. simpl. split. apply H. destruct H. intuition.
 apply isBELookupEq in H1 ;trivial.
}
	intro Sh1EAddr.
{ cbn. eapply weaken. eapply WP.writeSh1InChildLocationFromBlockEntryAddr2.	cbn.
	intros. simpl. destruct H. destruct H.
	intuition.
	unfold sh1entryAddr in *.
	apply isBELookupEq in H2. destruct H2.
	rewrite H2 in H0.
	destruct H0. destruct H0.
	subst. exists x. split.
	assumption. assumption.
}
Qed.

Lemma writeSCOriginFromBlockEntryAddr  (entryaddr : paddr) (neworigin : ADT.paddr)  (P : unit -> state -> Prop) :
{{fun  s => (*exists blockentry , lookup entryaddr s.(memory) beqAddr = Some (BE blockentry) /\*)
						isBE entryaddr s
						/\ wellFormedShadowCutIfBlockEntry s
						/\ KernelStructureStartFromBlockEntryAddrIsKS s
						/\ BlocksRangeFromKernelStartIsBE s
						/\ nullAddrExists s
						(*exists entry , exists scentryaddr, lookup scentryaddr s.(memory) beqAddr = Some (SCE entry) /\ *)
/\ exists entry , lookup (CPaddr (entryaddr + scoffset)) s.(memory) beqAddr = Some (SCE entry) /\
P tt {|
  currentPartition := currentPartition s;
  memory := add (CPaddr (entryaddr + scoffset))
              (SCE {| origin := neworigin ; next := entry.(next) |})
              (memory s) beqAddr |} }}
writeSCOriginFromBlockEntryAddr entryaddr neworigin  {{P}}.
Proof.
unfold MAL.writeSCOriginFromBlockEntryAddr.
eapply bindRev.
{ eapply weaken. apply getSCEntryAddrFromBlockEntryAddr.
	intros. simpl. split. apply H. intuition.
 apply isBELookupEq in H0 ;trivial.
}
	intro SCEAddr.
{ cbn. eapply weaken. eapply WP.writeSCOriginFromBlockEntryAddr2.
	cbn.
	intros. simpl. destruct H.
	intuition.
	unfold scentryAddr in H0.
	apply isBELookupEq in H1. destruct H1.
	rewrite H1 in H0.
	destruct H0. destruct H0.
	subst.
	assumption.
}
Qed.

Lemma writeSCNextFromBlockEntryAddr  (addr newnext: paddr) (P: unit -> state -> Prop) :
{{fun  s => wellFormedShadowCutIfBlockEntry s /\ KernelStructureStartFromBlockEntryAddrIsKS s
            /\ BlocksRangeFromKernelStartIsBE s /\ nullAddrExists s
            /\ exists entry blockIndex scentry, lookup addr s.(memory) beqAddr = Some (BE entry)
            /\ blockIndex = blockindex entry
            /\ lookup (CPaddr (addr + scoffset)) (memory s) beqAddr
                                = Some (SCE scentry)
            /\
P tt {|
  currentPartition := currentPartition s;
  memory := add (CPaddr (addr + scoffset))
              (SCE {| origin := scentry.(origin) ; next := newnext |})
              (memory s) beqAddr |} }}
MAL.writeSCNextFromBlockEntryAddr addr newnext {{P}}.
Proof.
unfold MAL.writeSCNextFromBlockEntryAddr.
eapply bind.
- intro SCEAddr. eapply bind.
  + intro s.
    case_eq (lookup SCEAddr s.(memory) beqAddr).
    * intros v Hpage.
      instantiate (1:= fun s s0 => s = s0
                     /\ exists entry blockIndex scentry, lookup addr s.(memory) beqAddr = Some (BE entry)
                       /\ blockIndex = blockindex entry
                       /\ SCEAddr = CPaddr (addr + scoffset)
                       /\ lookup SCEAddr (memory s) beqAddr = Some (SCE scentry)
                       /\ P tt {|
                            currentPartition := currentPartition s;
                            memory := add (CPaddr (addr + scoffset))
                                        (SCE {| origin := scentry.(origin) ; next := newnext |})
                                        (memory s) beqAddr |}).
      simpl. case_eq v; intros; eapply weaken; try eapply undefined ;simpl;
      subst;
      cbn; intros;
      try destruct H as [Hs (entry & (blockIndex & (scentry & (HlookupAddr & HblockIndex & HsceAddr & HlookupSce
                          & HP))))];
      subst; try rewrite HlookupSce in Hpage; inversion Hpage; subst; try assumption.
      eapply modify. intros. simpl. assumption.
    * intros Hpage; eapply weaken; try eapply undefined ;simpl.
      intros s0 H0. destruct H0 as [Hs (entry & (blockIndex & (scentry & (HlookupAddr & HblockIndex & HsceAddr
                                    & HlookupSce & HP))))].
      rewrite HlookupSce in Hpage. inversion Hpage.
  + eapply get.
- eapply strengthen. eapply weaken. apply getSCEntryAddrFromBlockEntryAddr.
  + simpl. intros s Hprops. split. apply Hprops. intuition.
    destruct H4 as [entry (blockIndex & (scentry & Hprops))]. exists entry. intuition.
  + simpl. intros s scentryAddr Hprops. split. reflexivity.
    destruct Hprops as [(HwellFormed & Hkernel & Hblocks & Hnull & Hprops) (scentry & (HlookupSceAddr &
                        HscentryAddr))].
    destruct Hprops as [entry (blockIndex & (scentryBis & (HlookupAddr & HblockIndex & HlookupSce & HP)))].
    exists entry. exists blockIndex. exists scentry. unfold StateLib.scentryAddr in HscentryAddr.
    rewrite HlookupAddr in HscentryAddr. rewrite <-HscentryAddr in HlookupSce.
    rewrite HlookupSceAddr in HlookupSce. injection HlookupSce as HsceEq. subst scentryBis. intuition.
Qed.

Lemma checkEntry  (kernelstructurestart blockentryaddr : paddr) (P :  state -> Prop) :
{{fun s => P s }}
MAL.checkEntry kernelstructurestart blockentryaddr
{{fun isValidentry s => P s /\ (isValidentry = true -> isBE blockentryaddr s)}}.
Proof.
eapply weaken. apply WeakestPreconditions.checkEntry.
intros.  simpl. intuition.
unfold entryExists in *. unfold isBE.
destruct (lookup blockentryaddr (memory s) beqAddr) eqn:Hlookup.
destruct v eqn:Hv ; trivial ; congruence. congruence.
Qed.

Lemma checkBlockInRAM  (blockentryaddr : paddr) (P :  state -> Prop) :
{{fun s => P s /\ isBE blockentryaddr s}}
MAL.checkBlockInRAM blockentryaddr
{{fun isblockinram s => P s /\ isBlockInRAM blockentryaddr isblockinram s}}.
Proof.
eapply weaken. apply checkBlockInRAM.
intros.  simpl. intuition.
apply isBELookupEq in H1. destruct H1. exists x. intuition.
unfold isBlockInRAM in *. rewrite H.
unfold blockInRAM in *. rewrite H.
reflexivity.
Qed.

Lemma writePDFirstFreeSlotPointer (pdtablepaddr firstfreeslotpaddr : paddr) (P : unit -> state -> Prop) :
{{fun s =>
exists entry , lookup pdtablepaddr s.(memory) beqAddr = Some (PDT entry) /\
P tt {|
  currentPartition := currentPartition s;
  memory := add pdtablepaddr
              (PDT {| structure := entry.(structure);
											firstfreeslot := firstfreeslotpaddr;
											nbfreeslots := entry.(nbfreeslots);
                     	nbprepare := entry.(nbprepare);
											parent := entry.(parent);
											MPU := entry.(MPU) ; vidtAddr := entry.(vidtAddr) |})
              (memory s) beqAddr |} }}
MAL.writePDFirstFreeSlotPointer pdtablepaddr firstfreeslotpaddr {{P}}.
Proof.
eapply WP.writePDFirstFreeSlotPointer.
Qed.

Lemma writePDNbFreeSlots (pdtablepaddr : paddr) (nbfreeslots : index) (P : unit -> state -> Prop) :
{{fun s =>
exists entry , lookup pdtablepaddr s.(memory) beqAddr = Some (PDT entry) /\
P tt {|
  currentPartition := currentPartition s;
  memory := add pdtablepaddr
              (PDT {| structure := entry.(structure);
											firstfreeslot := entry.(firstfreeslot);
											nbfreeslots := nbfreeslots;
                    	nbprepare := entry.(nbprepare);
											parent := entry.(parent);
											MPU := entry.(MPU) ; vidtAddr := entry.(vidtAddr) |})
              (memory s) beqAddr |}
}}
MAL.writePDNbFreeSlots pdtablepaddr nbfreeslots
{{ P }}.
Proof.
eapply WP.writePDNbFreeSlots.
Qed.

Lemma writeBlockStartFromBlockEntryAddr (entryaddr newstartaddr : paddr) (P : unit -> state -> Prop)  :
{{fun s => 
exists entry , lookup entryaddr s.(memory) beqAddr = Some (BE entry) /\
P tt {|
  currentPartition := currentPartition s;
  memory := add entryaddr
								(BE (CBlockEntry 	entry.(read) entry.(write) entry.(exec)
																	entry.(present) entry.(accessible)
																	entry.(blockindex) (CBlock newstartaddr entry.(blockrange).(endAddr))))
              (memory s) beqAddr |}
}}
MAL.writeBlockStartFromBlockEntryAddr entryaddr newstartaddr
{{P}}.
Proof.
eapply WP.writeBlockStartFromBlockEntryAddr.
Qed.

(* DUP*)
Lemma copyBlock  (blockTarget blockSource: paddr)  (P : unit -> state -> Prop) :
{{fun  s => P tt s
 }}
MAL.copyBlock blockTarget blockSource  {{P}}.
Proof.
eapply weaken. eapply WP.copyBlock.
intros. simpl.
intuition.
Qed.

Lemma findBlockIdxInPhysicalMPU partition block default (P: state -> Prop):
{{ fun s => P s /\ MPUsizeIsBelowMax s /\ isPDT partition s }}
MAL.findBlockIdxInPhysicalMPU partition block default
{{ fun idx s => P s /\ exists MPUlist, pdentryMPU partition MPUlist s
                                      /\ (idx = CIndex default /\ ~In block MPUlist
                                          \/ nth idx MPUlist nullAddr = block) }}.
Proof.
unfold findBlockIdxInPhysicalMPU. eapply bindRev.
{
  eapply weaken. apply readPDMPU. simpl. instantiate(1:= fun s => P s /\ MPUsizeIsBelowMax s).
  intuition.
}
intro realMPU. eapply bindRev.
{
  eapply weaken. apply Index.zero. intros s Hprops. simpl. apply Hprops.
}
intro zero. eapply strengthen. eapply weaken. apply ret.
- intros s Hprops.
  instantiate(1:= fun idx s =>
                    P s /\ MPUsizeIsBelowMax s /\ pdentryMPU partition realMPU s /\ zero = CIndex 0
                    /\ (idx = CIndex default
                         /\ (forall blockBis, In blockBis realMPU -> beqAddr blockBis block = false)
                       \/ idx >= zero /\ beqAddr (nth (idx - zero) realMPU nullAddr) block = true)). simpl.
  destruct Hprops as (((HP & HMPUsize) & HrealMPU) & Hzero). split. assumption. split. assumption. split.
  assumption. split. assumption.
  assert(HeqTriv: Lib.indexOf block zero realMPU beqAddr default = Lib.indexOf block zero realMPU beqAddr default)
      by reflexivity.
  assert(HlenBounded: length realMPU + zero <= maxIdx).
  {
    specialize(HMPUsize partition realMPU  HrealMPU). subst zero. unfold CIndex.
    destruct (le_dec 0 maxIdx); try(lia). simpl. rewrite PeanoNat.Nat.add_0_r.
    assert(MPURegionsNb <= maxIdx) by (apply MPURegionsNbBelowMaxIdx). lia.
  }
  pose proof (indexOf block zero realMPU beqAddr default
                (Lib.indexOf block zero realMPU beqAddr default) HeqTriv HlenBounded) as Hres. clear HeqTriv.
  destruct Hres as [Hleft | Hright].
  + left. destruct Hleft as (HeqDef & HnotPresent). split; try(assumption). rewrite HeqDef. reflexivity.
  + right. destruct Hright as (HlenBelowMaxIdx & Hgt & HbeqNthBlock).
    assert(Hcindex: i (CIndex (Lib.indexOf block zero realMPU beqAddr default))
                    = Lib.indexOf block zero realMPU beqAddr default).
    {
      unfold CIndex. destruct (le_dec (Lib.indexOf block zero realMPU beqAddr default) maxIdx); try(lia).
      simpl. reflexivity.
    }
    rewrite Hcindex. intuition.
- simpl. intros s idxRes Hprops. destruct Hprops as (HP & _ & HMPU & Hzero & HpropsOr). split. assumption.
  exists realMPU. split. assumption. destruct HpropsOr as [HnotPresent | Hpresent].
  + left. destruct HnotPresent as (HidxIsDef & HnotPresent). split. assumption. clear HMPU.
    induction realMPU.
    * intuition.
    * simpl. apply Classical_Prop.and_not_or. split.
      -- intro Hcontra. subst a. specialize(HnotPresent block). rewrite <-beqAddrFalse in HnotPresent.
         apply HnotPresent; try(reflexivity). simpl. left. reflexivity.
      -- apply IHrealMPU. intros blockBis HblockBis.
         apply HnotPresent. simpl. right. assumption.
  + right. destruct Hpresent as (HidxRes & HbeqNthBlock). rewrite <-DTL.beqAddrTrue in HbeqNthBlock.
    rewrite Hzero in HbeqNthBlock. unfold CIndex in HbeqNthBlock. destruct (le_dec 0 maxIdx); try(lia).
    simpl in HbeqNthBlock. rewrite PeanoNat.Nat.sub_0_r in HbeqNthBlock. assumption.
Qed.

Lemma initPDTable newPDTableAddr P:
{{ fun s => P s }}
MAL.initPDTable newPDTableAddr
{{ fun _ s => exists s0, P s0
              /\ s = {|
                        currentPartition := currentPartition s0;
                        memory := add newPDTableAddr
                                    (PDT
                                       {|
                                          structure := nullAddr;
                                          firstfreeslot := nullAddr;
                                          nbfreeslots := zero;
                                          nbprepare := zero;
                                          parent := nullAddr;
                                          MPU := nil;
                                          vidtAddr := nullAddr;
                                       |}) (memory s0) beqAddr
                      |} }}.
Proof.
unfold initPDTable. eapply bindRev.
{ (* getEmptyPDTable *)
  unfold getEmptyPDTable. eapply bindRev.
  { (* MALInternal.getNullAddr *)
    unfold MALInternal.getNullAddr. eapply weaken. apply WP.ret. intros s Hprops.
    instantiate(1 := fun retAddr s => P s /\ retAddr = nullAddr). simpl. intuition.
  }
  intro nulladdr. eapply bindRev.
  { (* MALInternal.Index.zero *)
    eapply weaken. apply Index.zero. intros s Hprops. simpl. apply Hprops.
  }
  intro zero. eapply weaken. apply WP.ret. intros s Hprops.
  instantiate(1 := fun retStruct s => P s
                                      /\ retStruct = {|
                                                       structure := nullAddr;
                                                       firstfreeslot := nullAddr;
                                                       nbfreeslots := CIndex 0;
                                                       nbprepare := CIndex 0;
                                                       parent := nullAddr;
                                                       MPU := nil;
                                                       vidtAddr := nullAddr
                                                     |}). simpl. intuition. subst nulladdr. subst zero.
  reflexivity.
}
(* writePDTable *)
intro emptytable. unfold writePDTable. eapply weaken. apply modify. intros s Hprops. simpl. exists s.
destruct Hprops as (HP & Hempty). split. assumption. rewrite Hempty. reflexivity.
Qed.

Lemma writePDParent PDTableAddr pdentry pdparent P:
{{ fun s => P s /\ lookup PDTableAddr (memory s) beqAddr = Some(PDT pdentry) }}
MAL.writePDParent PDTableAddr pdparent
{{ fun _ s => exists s0 newPDEntry, P s0
              /\ lookup PDTableAddr (memory s) beqAddr = Some(PDT newPDEntry)
              /\ s = {|
                        currentPartition := currentPartition s0;
                        memory := add PDTableAddr (PDT newPDEntry) (memory s0) beqAddr
                      |}
              /\ newPDEntry = {|
                                 structure := structure pdentry;
                                 firstfreeslot := firstfreeslot pdentry;
                                 nbfreeslots := nbfreeslots pdentry;
                                 nbprepare := nbprepare pdentry;
                                 parent := pdparent;
                                 MPU := MPU pdentry;
                                 vidtAddr := vidtAddr pdentry
                               |} }}.
Proof.
unfold writePDParent. eapply bindRev.
{ (* Monad.get *)
  eapply weaken. apply get. intros s Hprops. simpl.
  instantiate(1 := fun s0 s => P s /\ lookup PDTableAddr (memory s) beqAddr = Some (PDT pdentry) /\ s0 = s).
  simpl. intuition.
}
intro s. destruct (lookup PDTableAddr (memory s) beqAddr) eqn:HlookupPD.
- destruct v; try(eapply weaken; try(apply undefined); intros s1 Hprops; simpl;
                  destruct Hprops as (_ & HlookupContra & Hss1); subst s1; congruence).
  eapply weaken. apply modify. intros s0 Hprops. simpl. exists s0. rewrite IL.beqAddrTrue.
  exists {|
            structure := structure pdentry;
            firstfreeslot := firstfreeslot pdentry;
            nbfreeslots := nbfreeslots pdentry;
            nbprepare := nbprepare pdentry;
            parent := pdparent;
            MPU := MPU pdentry;
            vidtAddr := vidtAddr pdentry
          |}. destruct Hprops as (HP & HlookupPDs0 & Hss0Eq). subst s0. split. assumption.
  rewrite HlookupPD in HlookupPDs0. injection HlookupPDs0 as HpdentriesEq. subst p. split. reflexivity.
  split; reflexivity.
- eapply weaken. apply undefined. intros s0 Hprops. simpl. destruct Hprops as (_ & HlookupContra & Hss0).
  subst s0. congruence.
Qed.

Lemma writeSh1PDFlagFromBlockEntryAddr block pdflag P:
{{ fun s => P s /\ wellFormedFstShadowIfBlockEntry s /\ KernelStructureStartFromBlockEntryAddrIsKS s
            /\ BlocksRangeFromKernelStartIsBE s /\ nullAddrExists s /\ isBE block s }}
MAL.writeSh1PDFlagFromBlockEntryAddr block pdflag
{{ fun _ s => exists s0 sh1entry, P s0
                        /\ lookup (CPaddr (block + sh1offset)) (memory s0) beqAddr = Some(SHE sh1entry)
                        /\ s = {|
                                 currentPartition := currentPartition s0;
                                 memory :=
                                   add (CPaddr (block + sh1offset))
                                     (SHE {|
                                            PDchild := PDchild sh1entry;
                                            PDflag := pdflag;
                                            inChildLocation := inChildLocation sh1entry |})
                                     (memory s0) beqAddr
                               |} }}.
Proof.
unfold writeSh1PDFlagFromBlockEntryAddr. eapply bindRev.
{ (* MAL.getSh1EntryAddrFromBlockEntryAddr *)
  eapply weaken. apply getSh1EntryAddrFromBlockEntryAddr. intros s Hprops. simpl. split. apply Hprops.
  intuition. apply isBELookupEq. assumption.
}
intro Sh1EAddr. eapply bindRev.
{ (* Monad.get *)
  eapply weaken. apply get. intros s Hprops. simpl.
  instantiate(1 := fun resState s => P s /\ wellFormedFstShadowIfBlockEntry s
                  /\ KernelStructureStartFromBlockEntryAddrIsKS s /\ BlocksRangeFromKernelStartIsBE s
                  /\ nullAddrExists s /\ isBE block s
                  /\ (exists sh1entry, lookup Sh1EAddr (memory s) beqAddr = Some (SHE sh1entry)
                        /\ sh1entryAddr block Sh1EAddr s)
                  /\ resState = s). intuition.
}
intro s. destruct (lookup Sh1EAddr (memory s) beqAddr) eqn:HlookupSh1.
- destruct v; try(eapply weaken; try(apply undefined); intros s1 Hprops; simpl;
      destruct Hprops as (_ & _ & _ & _ & _ & _ & Hcontra & Hs); subst s1;
      destruct Hcontra as [sh1entry (Hcontra & _)]; congruence).
  eapply weaken. apply modify. intros s1 Hprops. simpl. exists s. exists s0.
  destruct Hprops as (HP & _ & _ & _ & _ & _ & HlookupSh1Bis & Hs). subst s1. split. assumption.
  split; try(reflexivity). destruct HlookupSh1Bis as [sh1entry (HlookupSh1Bis & Hsh1)]. rewrite HlookupSh1 in *.
  injection HlookupSh1Bis as HshentriesEq. subst s0. unfold sh1entryAddr in Hsh1.
  destruct (lookup block (memory s) beqAddr); try(exfalso; congruence). destruct v; try(exfalso; congruence).
  subst Sh1EAddr. assumption. destruct HlookupSh1Bis as [_ (_ & Hsh1)]. unfold sh1entryAddr in Hsh1.
  destruct (lookup block (memory s) beqAddr); try(exfalso; congruence). destruct v; try(exfalso; congruence).
  subst Sh1EAddr. reflexivity.
- eapply weaken. apply undefined. intros s0 Hprops. simpl.
  destruct Hprops as (_ & _ & _ & _ & _ & _ & Hcontra & Hs). subst s0.
  destruct Hcontra as [sh1entry (Hcontra & _)]. congruence.
Qed.

Lemma writeSh1EntryFromBlockEntryAddr block newPdChild newPdFlag newInChildLocation P:
{{ fun s => P s /\ wellFormedFstShadowIfBlockEntry s /\ KernelStructureStartFromBlockEntryAddrIsKS s
            /\ BlocksRangeFromKernelStartIsBE s /\ nullAddrExists s /\ isBE block s }}
writeSh1EntryFromBlockEntryAddr block newPdChild newPdFlag newInChildLocation
{{ fun _ s => exists s0 sh1entry1 sh1entry0,
                P s0
                /\ s = {|
                         currentPartition := currentPartition s0;
                         memory :=
                           add (CPaddr (block + sh1offset))
                             (SHE {| PDchild := newPdChild;
                                     PDflag := newPdFlag;
                                     inChildLocation := newInChildLocation |})
                             (add (CPaddr (block + sh1offset)) sh1entry1
                                (add (CPaddr (block + sh1offset)) sh1entry0 (memory s0) beqAddr) beqAddr) beqAddr
                       |}
                /\ wellFormedFstShadowIfBlockEntry s /\ KernelStructureStartFromBlockEntryAddrIsKS s
                /\ BlocksRangeFromKernelStartIsBE s /\ nullAddrExists s }}.
Proof.
unfold writeSh1EntryFromBlockEntryAddr. eapply bindRev.
{ (* MAL.writeSh1PDChildFromBlockEntryAddr *)
  eapply weaken. apply writeSh1PDChildFromBlockEntryAddr. intros s Hprops. simpl.
  destruct Hprops as (HP & HwellFormedSh & HstructIsKS & HrangeIsBE & Hnull & HblockIsBE).
  assert(HwellFormedShCopy: wellFormedFstShadowIfBlockEntry s) by assumption.
  specialize(HwellFormedShCopy block HblockIsBE). unfold isSHE in HwellFormedShCopy.
  destruct (lookup (CPaddr (block + sh1offset)) (memory s) beqAddr) eqn:HlookupSh1; try(exfalso; congruence).
  destruct v; try(exfalso; congruence). exists s0. split. reflexivity.
  instantiate(1 := fun _ s =>
      wellFormedFstShadowIfBlockEntry s
      /\ KernelStructureStartFromBlockEntryAddrIsKS s /\ BlocksRangeFromKernelStartIsBE s
      /\ nullAddrExists s /\ beqAddr (CPaddr (block + sh1offset)) block = false
      /\ exists s0 sh1entry, P s0 /\ isBE block s0
                /\ lookup block (memory s) beqAddr = lookup block (memory s0) beqAddr
                /\ lookup (CPaddr (block + sh1offset)) (memory s0) beqAddr = Some (SHE sh1entry)
                /\ s = {|
                         currentPartition := currentPartition s0;
                         memory :=
                           add (CPaddr (block + sh1offset))
                             (SHE {| PDchild := newPdChild;
                                     PDflag := PDflag sh1entry;
                                     inChildLocation := inChildLocation sh1entry |})
                             (memory s0) beqAddr
                       |}). simpl. split.
  - set(s' := {|
                currentPartition := currentPartition s;
                memory :=
                  add (CPaddr (block + sh1offset))
                    (SHE {| PDchild := newPdChild; PDflag := PDflag s0; inChildLocation := inChildLocation s0 |})
                    (memory s) beqAddr
              |}).
    assert(wellFormedFstShadowIfBlockEntry s').
    {
      intros blockBis HblockBisIsBE. unfold isSHE. simpl.
      destruct (beqAddr (CPaddr (block + sh1offset)) (CPaddr (blockBis + sh1offset))) eqn:HbeqBlocks; trivial.
      rewrite <-beqAddrFalse in HbeqBlocks. rewrite removeDupIdentity; try(apply not_eq_sym; assumption).
      assert(HblockBisIsBEs: isBE blockBis s).
      {
        unfold isBE in *. simpl in HblockBisIsBE.
        destruct (beqAddr (CPaddr (block + sh1offset)) blockBis) eqn:HbeqBlockSh1BlockBis;
          try(exfalso; congruence). rewrite <-beqAddrFalse in HbeqBlockSh1BlockBis.
        rewrite removeDupIdentity in HblockBisIsBE; try(apply not_eq_sym); assumption.
      }
      specialize(HwellFormedSh blockBis HblockBisIsBEs). assumption.
    }
    assert(KernelStructureStartFromBlockEntryAddrIsKS s').
    {
      intros blockBis blockidx HblockBisIsBE HblockIdx.
      assert(HblockBisIsBEs: isBE blockBis s).
      {
        unfold isBE in *. simpl in HblockBisIsBE.
        destruct (beqAddr (CPaddr (block + sh1offset)) blockBis) eqn:HbeqBlockSh1BlockBis;
          try(exfalso; congruence). rewrite <-beqAddrFalse in HbeqBlockSh1BlockBis.
        rewrite removeDupIdentity in HblockBisIsBE; try(apply not_eq_sym); assumption.
      }
      assert(HblockIdxs: bentryBlockIndex blockBis blockidx s).
      {
        unfold bentryBlockIndex in *. simpl in HblockIdx.
        destruct (beqAddr (CPaddr (block + sh1offset)) blockBis) eqn:HbeqBlockSh1BlockBis;
          try(exfalso; congruence). rewrite <-beqAddrFalse in HbeqBlockSh1BlockBis.
        rewrite removeDupIdentity in HblockIdx; try(apply not_eq_sym); assumption.
      }
      specialize(HstructIsKS blockBis blockidx HblockBisIsBEs HblockIdxs). unfold isKS in *. simpl.
      destruct (beqAddr (CPaddr (block + sh1offset)) (CPaddr (blockBis - blockidx))) eqn:HbeqBlockSh1BlockBisKern.
      {
        rewrite <-DTL.beqAddrTrue in HbeqBlockSh1BlockBisKern. rewrite HbeqBlockSh1BlockBisKern in *.
        rewrite HlookupSh1 in HstructIsKS. congruence.
      }
      rewrite <-beqAddrFalse in HbeqBlockSh1BlockBisKern. rewrite removeDupIdentity; try(apply not_eq_sym);
        assumption.
    }
    assert(BlocksRangeFromKernelStartIsBE s').
    {
      intros kernelBis blockidx HkernIsKS HblockIdxBound.
      assert(HkernIsKSs: isKS kernelBis s).
      {
        unfold isKS in *. simpl in HkernIsKS.
        destruct (beqAddr (CPaddr (block + sh1offset)) kernelBis) eqn:HbeqBlockSh1KernBis;
          try(exfalso; congruence). rewrite <-beqAddrFalse in HbeqBlockSh1KernBis.
        rewrite removeDupIdentity in HkernIsKS; try(apply not_eq_sym); assumption.
      }
      specialize(HrangeIsBE kernelBis blockidx HkernIsKSs HblockIdxBound). unfold isBE in *. simpl.
      destruct (beqAddr (CPaddr (block + sh1offset)) (CPaddr (kernelBis + blockidx))) eqn:HbeqBlockSh1KernIdx.
      {
        rewrite <-DTL.beqAddrTrue in HbeqBlockSh1KernIdx. rewrite HbeqBlockSh1KernIdx in *.
        rewrite HlookupSh1 in HrangeIsBE. congruence.
      }
      rewrite <-beqAddrFalse in HbeqBlockSh1KernIdx. rewrite removeDupIdentity; try(apply not_eq_sym); assumption.
    }
    assert(nullAddrExists s').
    {
      unfold nullAddrExists in *. unfold isPADDR in *. simpl.
      destruct (beqAddr (CPaddr (block + sh1offset)) nullAddr) eqn:HbeqBlockSh1Null.
      {
        rewrite <-DTL.beqAddrTrue in HbeqBlockSh1Null. rewrite HbeqBlockSh1Null in *.
        rewrite HlookupSh1 in Hnull. congruence.
      }
      rewrite <-beqAddrFalse in HbeqBlockSh1Null. rewrite removeDupIdentity; try(apply not_eq_sym); assumption.
    }
    destruct (beqAddr (CPaddr (block + sh1offset)) block) eqn:HbeqBlockSh1Block.
    {
      exfalso. rewrite <-DTL.beqAddrTrue in HbeqBlockSh1Block. rewrite HbeqBlockSh1Block in *.
      unfold isBE in HblockIsBE. rewrite HlookupSh1 in HblockIsBE. congruence.
    }
    split. assumption. split. assumption. split. assumption. split. assumption. split. reflexivity.
    exists s. exists s0. rewrite <-beqAddrFalse in HbeqBlockSh1Block.
    rewrite removeDupIdentity; intuition.
  - intuition.
}
intro. eapply bindRev.
{ (* MAL.writeSh1PDFlagFromBlockEntryAddr *)
  eapply weaken. apply writeSh1PDFlagFromBlockEntryAddr. intros s Hprops. simpl. split. apply Hprops.
  destruct Hprops as (HwellFormedSh & HstructIsKS & HrangeIsBE & Hnull & HbeqBlockSh1Block & [s0 [sh1entry (_ &
      HblockIsBEs0 & HlookupEq & _)]]). unfold isBE in HblockIsBEs0. rewrite <-HlookupEq in HblockIsBEs0.
  intuition.
}
intro. eapply bindRev.
{ (* MAL.writeSh1InChildLocationFromBlockEntryAddr *)
  eapply weaken. apply writeSh1InChildLocationFromBlockEntryAddr. intros s Hprops. simpl.
  destruct Hprops as [s1 [sh1entry1 (Hprops & HlookupBlockSh1 & Hs)]].
  set(sh1entry2 := {|
                     PDchild := PDchild sh1entry1;
                     PDflag := newPdFlag;
                     inChildLocation := inChildLocation sh1entry1
                   |}).
  assert(HlookupBlockSh1s: lookup (CPaddr (block + sh1offset)) (memory s) beqAddr = Some (SHE sh1entry2)).
  {
    rewrite Hs. simpl. rewrite beqAddrTrue. reflexivity.
  }
  exists sh1entry2. split. assumption.
  destruct Hprops as (HwellFormedSh & HstructIsKS & HrangeIsBE & Hnull & HbeqBlockSh1Block & [s0 [sh1entry
      (HP & HblockIsBEs0 & HlookupBlockEq & Hprops)]]).
  assert(HlookupBlockEqss0: lookup block (memory s) beqAddr = lookup block (memory s0) beqAddr).
  {
    rewrite <-HlookupBlockEq. rewrite Hs. simpl. rewrite HbeqBlockSh1Block.
    rewrite <-beqAddrFalse in HbeqBlockSh1Block. rewrite removeDupIdentity; intuition.
  }
  unfold isBE. rewrite HlookupBlockEqss0.
  assert(wellFormedFstShadowIfBlockEntry s).
  {
    intros blockBis HblockBisIsBE. assert(HblockBisIsBEs1: isBE blockBis s1).
    {
      unfold isBE in *. rewrite Hs in HblockBisIsBE. simpl in HblockBisIsBE.
      destruct (beqAddr (CPaddr (block + sh1offset)) blockBis) eqn:HbeqBlockSh1BlockBis; try(exfalso; congruence).
      rewrite <-beqAddrFalse in HbeqBlockSh1BlockBis. rewrite removeDupIdentity in HblockBisIsBE; intuition.
    }
    specialize(HwellFormedSh blockBis HblockBisIsBEs1).
    unfold isSHE. rewrite Hs. simpl.
    destruct (beqAddr (CPaddr (block + sh1offset)) (CPaddr (blockBis + sh1offset))) eqn:HbeqBlockSh1BlockBisSh1;
      trivial. rewrite <-beqAddrFalse in HbeqBlockSh1BlockBisSh1. rewrite removeDupIdentity; intuition.
  }
  assert(KernelStructureStartFromBlockEntryAddrIsKS s).
  {
    intros blockBis blockidx HblockBisIsBE HblockIdx. assert(HblockBisIsBEs1: isBE blockBis s1).
    {
      unfold isBE in *. rewrite Hs in HblockBisIsBE. simpl in HblockBisIsBE.
      destruct (beqAddr (CPaddr (block + sh1offset)) blockBis) eqn:HbeqBlockSh1BlockBis; try(exfalso; congruence).
      rewrite <-beqAddrFalse in HbeqBlockSh1BlockBis. rewrite removeDupIdentity in HblockBisIsBE; intuition.
    }
    assert(HblockIdxs1: bentryBlockIndex blockBis blockidx s1).
    {
      unfold bentryBlockIndex in *. rewrite Hs in HblockIdx. simpl in HblockIdx.
      destruct (beqAddr (CPaddr (block + sh1offset)) blockBis) eqn:HbeqBlockSh1BlockBis; try(exfalso; congruence).
      rewrite <-beqAddrFalse in HbeqBlockSh1BlockBis. rewrite removeDupIdentity in HblockIdx; intuition.
    }
    specialize(HstructIsKS blockBis blockidx HblockBisIsBEs1 HblockIdxs1). unfold isKS in *. rewrite Hs. simpl.
    destruct (beqAddr (CPaddr (block + sh1offset)) (CPaddr (blockBis - blockidx))) eqn:HbeqBlockSh1BlockBisKern.
    {
      rewrite <-DTL.beqAddrTrue in HbeqBlockSh1BlockBisKern. rewrite HbeqBlockSh1BlockBisKern in *.
      rewrite HlookupBlockSh1 in HstructIsKS. congruence.
    }
    rewrite <-beqAddrFalse in HbeqBlockSh1BlockBisKern. rewrite removeDupIdentity; intuition.
  }
  assert(BlocksRangeFromKernelStartIsBE s).
  {
    intros kernelBis blockidx HkernIsKS HblockIdxBound.
    assert(HkernIsKSs: isKS kernelBis s1).
    {
      unfold isKS in *. rewrite Hs in HkernIsKS. simpl in HkernIsKS.
      destruct (beqAddr (CPaddr (block + sh1offset)) kernelBis) eqn:HbeqBlockSh1KernBis;
        try(exfalso; congruence). rewrite <-beqAddrFalse in HbeqBlockSh1KernBis.
      rewrite removeDupIdentity in HkernIsKS; try(apply not_eq_sym); assumption.
    }
    specialize(HrangeIsBE kernelBis blockidx HkernIsKSs HblockIdxBound). unfold isBE in *. rewrite Hs. simpl.
    destruct (beqAddr (CPaddr (block + sh1offset)) (CPaddr (kernelBis + blockidx))) eqn:HbeqBlockSh1KernIdx.
    {
      rewrite <-DTL.beqAddrTrue in HbeqBlockSh1KernIdx. rewrite HbeqBlockSh1KernIdx in *.
      rewrite HlookupBlockSh1 in HrangeIsBE. congruence.
    }
    rewrite <-beqAddrFalse in HbeqBlockSh1KernIdx. rewrite removeDupIdentity; try(apply not_eq_sym); assumption.
  }
  assert(nullAddrExists s).
  {
    unfold nullAddrExists in *. unfold isPADDR in *. rewrite Hs. simpl.
    destruct (beqAddr (CPaddr (block + sh1offset)) nullAddr) eqn:HbeqBlockSh1Null.
    {
      rewrite <-DTL.beqAddrTrue in HbeqBlockSh1Null. rewrite HbeqBlockSh1Null in *.
      rewrite HlookupBlockSh1 in Hnull. congruence.
    }
    rewrite <-beqAddrFalse in HbeqBlockSh1Null. rewrite removeDupIdentity; try(apply not_eq_sym); assumption.
  }
  instantiate(1 := fun _ s =>
      exists s2 s1 s0 sh1entry2 sh1entry1 sh1entry0,
          s = {|
                currentPartition := currentPartition s2;
                memory :=
                  add (CPaddr (block + sh1offset))
                    (SHE
                       {|
                         PDchild := PDchild sh1entry2;
                         PDflag := PDflag sh1entry2;
                         inChildLocation := newInChildLocation
                       |}) (memory s2) beqAddr
              |}
          /\ s2 = {|
                    currentPartition := currentPartition s1;
                    memory :=
                      add (CPaddr (block + sh1offset))
                        (SHE sh1entry2) (memory s1) beqAddr
                  |}
          /\ sh1entry2 =
              {|
                PDchild := PDchild sh1entry1; PDflag := newPdFlag; inChildLocation := inChildLocation sh1entry1
              |}
          /\ sh1entry1 =
              {|
                PDchild := newPdChild; PDflag := PDflag sh1entry0; inChildLocation := inChildLocation sh1entry0
              |}
          /\ beqAddr (CPaddr (block + sh1offset)) block = false
          /\ lookup (CPaddr (block + sh1offset)) (memory s2) beqAddr = Some (SHE sh1entry2)
          /\ wellFormedFstShadowIfBlockEntry s2 /\ KernelStructureStartFromBlockEntryAddrIsKS s2
          /\ BlocksRangeFromKernelStartIsBE s2 /\ nullAddrExists s2
          /\ s1 = {|
                    currentPartition := currentPartition s0;
                    memory :=
                      add (CPaddr (block + sh1offset))
                        (SHE
                           {|
                             PDchild := newPdChild;
                             PDflag := PDflag sh1entry0;
                             inChildLocation := inChildLocation sh1entry0
                           |}) (memory s0) beqAddr
                  |}
          /\ lookup (CPaddr (block + sh1offset)) (memory s1) beqAddr = Some (SHE sh1entry1)
          /\ lookup block (memory s1) beqAddr = lookup block (memory s0) beqAddr
          /\ lookup (CPaddr (block + sh1offset)) (memory s0) beqAddr = Some (SHE sh1entry0)
          /\ isBE block s0 /\ P s0). simpl. split.
  - exists s. exists s1. exists s0. exists sh1entry2. exists sh1entry1. exists sh1entry.
    intuition. rewrite H4 in HlookupBlockSh1. simpl in HlookupBlockSh1. rewrite beqAddrTrue in HlookupBlockSh1.
    injection HlookupBlockSh1 as Hres. apply eq_sym. assumption.
  - intuition.
}
intro. eapply weaken. apply ret. intros s Hprops. simpl. destruct Hprops as [s2 [s1 [s0 [sh1entry2 [sh1entry1
  [sh1entry0 (Hs & Hs2 & Hsh1entry2 & Hsh1entry1 & HbeqBlockSh1Block & HlookupBlockSh1s2 & HwellFormedSh &
  HstructIsKS & HrangeIsBE & Hnull & Hs1 & _ & _ & _ & _ & HP)]]]]]]. exists s0.
exists (SHE {| PDchild := newPdChild; PDflag := newPdFlag; inChildLocation := inChildLocation sh1entry0 |}).
exists (SHE {| PDchild := newPdChild; PDflag := PDflag sh1entry0;
               inChildLocation := inChildLocation sh1entry0 |}).
 split. assumption. split.
- rewrite Hs. rewrite Hs2. simpl. rewrite Hsh1entry2. simpl. rewrite Hsh1entry1. simpl. rewrite Hs1. simpl.
  reflexivity.
- split.
  { (* wellFormedFstShadowIfBlockEntry s *)
    intros blockBis HblockBisIsBE. assert(HblockBisIsBEs2: isBE blockBis s2).
    {
      unfold isBE in *. rewrite Hs in HblockBisIsBE. simpl in HblockBisIsBE.
      destruct (beqAddr (CPaddr (block + sh1offset)) blockBis) eqn:HbeqBlockSh1BlockBis; try(exfalso; congruence).
      rewrite <-beqAddrFalse in HbeqBlockSh1BlockBis. rewrite removeDupIdentity in HblockBisIsBE; intuition.
    }
    specialize(HwellFormedSh blockBis HblockBisIsBEs2).
    unfold isSHE. rewrite Hs. simpl.
    destruct (beqAddr (CPaddr (block + sh1offset)) (CPaddr (blockBis + sh1offset))) eqn:HbeqBlockSh1BlockBisSh1;
      trivial. rewrite <-beqAddrFalse in HbeqBlockSh1BlockBisSh1. rewrite removeDupIdentity; intuition.
  }
  split.
  { (* KernelStructureStartFromBlockEntryAddrIsKS s *)
    intros blockBis blockidx HblockBisIsBE HblockIdx. assert(HblockBisIsBEs2: isBE blockBis s2).
    {
      unfold isBE in *. rewrite Hs in HblockBisIsBE. simpl in HblockBisIsBE.
      destruct (beqAddr (CPaddr (block + sh1offset)) blockBis) eqn:HbeqBlockSh1BlockBis; try(exfalso; congruence).
      rewrite <-beqAddrFalse in HbeqBlockSh1BlockBis. rewrite removeDupIdentity in HblockBisIsBE; intuition.
    }
    assert(HblockIdxs2: bentryBlockIndex blockBis blockidx s2).
    {
      unfold bentryBlockIndex in *. rewrite Hs in HblockIdx. simpl in HblockIdx.
      destruct (beqAddr (CPaddr (block + sh1offset)) blockBis) eqn:HbeqBlockSh1BlockBis; try(exfalso; congruence).
      rewrite <-beqAddrFalse in HbeqBlockSh1BlockBis. rewrite removeDupIdentity in HblockIdx; intuition.
    }
    specialize(HstructIsKS blockBis blockidx HblockBisIsBEs2 HblockIdxs2). unfold isKS in *. rewrite Hs. simpl.
    destruct (beqAddr (CPaddr (block + sh1offset)) (CPaddr (blockBis - blockidx))) eqn:HbeqBlockSh1BlockBisKern.
    {
      rewrite <-DTL.beqAddrTrue in HbeqBlockSh1BlockBisKern. rewrite HbeqBlockSh1BlockBisKern in *.
      rewrite HlookupBlockSh1s2 in HstructIsKS. congruence.
    }
    rewrite <-beqAddrFalse in HbeqBlockSh1BlockBisKern. rewrite removeDupIdentity; intuition.
  }
  split.
  { (* BlocksRangeFromKernelStartIsBE s *)
    intros kernelBis blockidx HkernIsKS HblockIdxBound.
    assert(HkernIsKSs2: isKS kernelBis s2).
    {
      unfold isKS in *. rewrite Hs in HkernIsKS. simpl in HkernIsKS.
      destruct (beqAddr (CPaddr (block + sh1offset)) kernelBis) eqn:HbeqBlockSh1KernBis;
        try(exfalso; congruence). rewrite <-beqAddrFalse in HbeqBlockSh1KernBis.
      rewrite removeDupIdentity in HkernIsKS; try(apply not_eq_sym); assumption.
    }
    specialize(HrangeIsBE kernelBis blockidx HkernIsKSs2 HblockIdxBound). unfold isBE in *. rewrite Hs. simpl.
    destruct (beqAddr (CPaddr (block + sh1offset)) (CPaddr (kernelBis + blockidx))) eqn:HbeqBlockSh1KernIdx.
    {
      rewrite <-DTL.beqAddrTrue in HbeqBlockSh1KernIdx. rewrite HbeqBlockSh1KernIdx in *.
      rewrite HlookupBlockSh1s2 in HrangeIsBE. congruence.
    }
    rewrite <-beqAddrFalse in HbeqBlockSh1KernIdx. rewrite removeDupIdentity; try(apply not_eq_sym); assumption.
  }
  unfold nullAddrExists in *. unfold isPADDR in *. rewrite Hs. simpl.
  destruct (beqAddr (CPaddr (block + sh1offset)) nullAddr) eqn:HbeqBlockSh1Null.
  {
    rewrite <-DTL.beqAddrTrue in HbeqBlockSh1Null. rewrite HbeqBlockSh1Null in *.
    rewrite HlookupBlockSh1s2 in Hnull. congruence.
  }
  rewrite <-beqAddrFalse in HbeqBlockSh1Null. rewrite removeDupIdentity; try(apply not_eq_sym); assumption.
Qed.


