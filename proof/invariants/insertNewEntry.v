(*******************************************************************************)
(*  © Université de Lille, The Pip Development Team (2015-2021)                *)
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
Require Import Model.ADT (*Pip.Model.Hardware Pip.Model.IAL*) Model.Monad Model.Lib
               Model.MAL.
Require Import Core.Internal Core.Services.
Require Import Proof.Consistency Proof.DependentTypeLemmas Proof.Hoare Proof.InternalLemmas
               Proof.Isolation Proof.StateLib Proof.WeakestPreconditions Proof.invariants.Invariants.
Require Import Coq.Logic.ProofIrrelevance Lia Setoid Compare_dec (*EqNat*) List Bool.

Module WP := WeakestPreconditions.

(* Couper le code de preuve -> ici que faire une propagation des propriétés initiale
+ propager nouvelles propriétés *)
Lemma insertNewEntry 	(pdinsertion startaddr endaddr origin: paddr)
											(r w e : bool) (currnbfreeslots : index) (P : state -> Prop):
{{ fun s => (*P s /\*) partitionsIsolation s   (*/\ kernelDataIsolation s*) /\ verticalSharing s
/\ consistency s
(* to retrieve the fields in pdinsertion *)
/\ (exists pdentry, lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry))
(* to show the first free slot pointer is not NULL *)
/\ (pdentryNbFreeSlots pdinsertion currnbfreeslots s /\ currnbfreeslots > 0)
/\ P s
(*/\ exists entry , lookup (CPaddr (entryaddr + scoffset)) s.(memory) beqAddr = Some (SCE entry) /\
P tt {|
  currentPartition := currentPartition s;
  memory := add (CPaddr (entryaddr + scoffset))
              (SCE {| origin := neworigin ; next := entry.(next) |})
              (memory s) beqAddr |}*)
(*/\ (*exists newFirstFreeSlotAddr,*)
exists newBlockEntryAddr newFirstFreeSlotAddr,
     entryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s
/\
Q tt
    {|
    currentPartition := currentPartition s;
    memory := add pdinsertion
                (PDT
                   {|
                   structure := structure pdentry;
                   firstfreeslot := newFirstFreeSlotAddr;
                   nbfreeslots := nbfreeslots pdentry;
                   nbprepare := nbprepare pdentry;
                   parent := parent pdentry;
                   MPU := MPU pdentry |}) (memory s) beqAddr |}*)
(*/\ (*(exists entry : BlockEntry, exists blockToShareInCurrPartAddr : paddr,
                 lookup blockToShareInCurrPartAddr (memory s) beqAddr =
                 Some (BE bentry)*) isBE idBlockToShare s*)

}}

Internal.insertNewEntry pdinsertion startaddr endaddr origin r w e currnbfreeslots
{{fun newentryaddr s => (*partitionsIsolation s   (*/\ kernelDataIsolation s*) /\ verticalSharing s /\ consistency s*)
(*/\ exists globalIdPDChild : paddr,
	exists pdtentry : PDTable, lookup (beentry.(blockrange).(startAddr)) s.(memory) beqAddr = Some (PDT pdtentry)
-> pas cette condition car on retourne ensuite dans le code principal et si on termine
en faux on peut pas prouver ctte partie *)
(exists s0, P s0) /\ isBE newentryaddr s /\ consistency s /\
(*
exists sceaddr scentry pdentry bentry newBlockEntryAddr newFirstFreeSlotAddr predCurrentNbFreeSlots,
s = {|
  currentPartition := currentPartition s;
  memory := add pdinsertion
              (PDT
                 {|
                 structure := structure pdentry;
                 firstfreeslot := newFirstFreeSlotAddr;
                 nbfreeslots := predCurrentNbFreeSlots;
                 nbprepare := nbprepare pdentry;
                 parent := parent pdentry;
                 MPU := MPU pdentry |})
					(add newBlockEntryAddr
                 (BE
                    (CBlockEntry r w e
                       true true (blockindex bentry)
                       (CBlock startaddr endaddr)))


				(add sceaddr (SCE {| origin := origin; next := next scentry |})
 (memory s) beqAddr) beqAddr) beqAddr |})
*)

(*exists pd : PDTable, lookup pdinsertion (memory s) beqAddr = Some (PDT pd) /\*)
(*pdentryNbFreeSlots pdinsertion predCurrentNbFreeSlots s (*/\ predCurrentNbFreeSlots > 0*) /\
     (*pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s /\
    bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s /\*)
   StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots *)


(exists s0, exists pdentry : PDTable, exists pdentry0 pdentry1: PDTable,
		exists bentry bentry0 bentry1 bentry2 bentry3 bentry4 bentry5 bentry6: BlockEntry,
		exists sceaddr, exists scentry : SCEntry,
		exists newBlockEntryAddr newFirstFreeSlotAddr predCurrentNbFreeSlots,
  s = {|
     currentPartition := currentPartition s0;
     memory := add sceaddr
									(SCE {| origin := origin; next := next scentry |})
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry5) (write bentry5) e (present bentry5)
                       (accessible bentry5) (blockindex bentry5) (blockrange bentry5)))
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry4) w (exec bentry4) (present bentry4)
                       (accessible bentry4) (blockindex bentry4) (blockrange bentry4)))
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry r (write bentry3) (exec bentry3) (present bentry3)
                       (accessible bentry3) (blockindex bentry3) (blockrange bentry3)))
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry2) (write bentry2) (exec bentry2) true
                       (accessible bentry2) (blockindex bentry2) (blockrange bentry2)))
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry1) (write bentry1) (exec bentry1)
                       (present bentry1) true (blockindex bentry1) (blockrange bentry1)))
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry0) (write bentry0) (exec bentry0)
                       (present bentry0) (accessible bentry0) (blockindex bentry0)
                       (CBlock (startAddr (blockrange bentry0)) endaddr)))
							(add newBlockEntryAddr
                     (BE
                        (CBlockEntry (read bentry) (write bentry)
                           (exec bentry) (present bentry) (accessible bentry)
                           (blockindex bentry)
                           (CBlock startaddr (endAddr (blockrange bentry)))))
								(add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry0;
                    firstfreeslot := firstfreeslot pdentry0;
                    nbfreeslots := predCurrentNbFreeSlots;
                    nbprepare := nbprepare pdentry0;
                    parent := parent pdentry0;
                    MPU := MPU pdentry0;
										vidtBlock := vidtBlock pdentry0 |})
								(add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry;
										vidtBlock := vidtBlock pdentry |}) (memory s0) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr |}

/\ lookup newBlockEntryAddr (memory s0) beqAddr = Some (BE bentry)
/\ lookup newBlockEntryAddr (memory s) beqAddr = Some (BE bentry6) /\
bentry6 = (CBlockEntry (read bentry5) (write bentry5) e (present bentry5)
                       (accessible bentry5) (blockindex bentry5) (blockrange bentry5))
/\
bentry5 = (CBlockEntry (read bentry4) w (exec bentry4) (present bentry4)
                       (accessible bentry4) (blockindex bentry4) (blockrange bentry4))
/\
bentry4 = (CBlockEntry r (write bentry3) (exec bentry3) (present bentry3)
                       (accessible bentry3) (blockindex bentry3) (blockrange bentry3))
/\
bentry3 = (CBlockEntry (read bentry2) (write bentry2) (exec bentry2) true
                       (accessible bentry2) (blockindex bentry2) (blockrange bentry2))
/\
bentry2 = (CBlockEntry (read bentry1) (write bentry1) (exec bentry1)
                       (present bentry1) true (blockindex bentry1) (blockrange bentry1))
/\
bentry1 = (CBlockEntry (read bentry0) (write bentry0) (exec bentry0)
                       (present bentry0) (accessible bentry0) (blockindex bentry0)
                       (CBlock (startAddr (blockrange bentry0)) endaddr))
/\
bentry0 = (CBlockEntry (read bentry) (write bentry)
                           (exec bentry) (present bentry) (accessible bentry)
                           (blockindex bentry)
                           (CBlock startaddr (endAddr (blockrange bentry))))
/\ lookup pdinsertion (memory s0) beqAddr = Some (PDT pdentry)
/\ lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry1) /\
pdentry1 = {|     structure := structure pdentry0;
                    firstfreeslot := firstfreeslot pdentry0;
                    nbfreeslots := predCurrentNbFreeSlots;
                    nbprepare := nbprepare pdentry0;
                    parent := parent pdentry0;
                    MPU := MPU pdentry0;
										vidtBlock := vidtBlock pdentry0 |} /\
pdentry0 = {|    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry;
										vidtBlock := vidtBlock pdentry|}
)
}}.
Proof.
(*unfold Internal.insertNewEntry.
eapply bind. intro newBlockEntryAddr.
eapply bind. intro newFirstFreeSlotAddr.
eapply bind. intro currentNbFreeSlots.
eapply bind. intro predCurrentNbFreeSlots.
eapply bind. intro ttwritePDFirstFreeSlotPointer.
eapply bind. intro ttwritePDNbFreeSlots.
eapply bind. intro ttwriteBlockStartFromBlockEntryAddr.
eapply bind. intro ttwriteBlockEndFromBlockEntryAddr.
eapply bind. intro ttwriteBlockAccessibleFromBlockEntryAddr.
eapply bind. intro ttwriteBlockPresentFromBlockEntryAddr.
eapply bind. intro ttwriteBlockRFromBlockEntryAddr.
eapply bind. intro ttwriteBlockWFromBlockEntryAddr.
eapply bind. intro ttwriteBlockXFromBlockEntryAddr.
eapply weaken. apply ret.
intros. simpl. apply H.
admit.
(*eapply weaken. eapply WP.writeSCOriginFromBlockEntryAddr.*)
(* Peux pas avancer en bind car s'applique avec des WP, or on en a pas pour certains write
car sont des opérations monadiques -> ne change rien si on réordonne les instructions
pour que les write soient tous ensemble*)
*)

unfold Internal.insertNewEntry.
eapply WP.bindRev.
{ (** readPDFirstFreeSlotPointer **)
	eapply weaken. apply readPDFirstFreeSlotPointer.
	intros. simpl. split. apply H.
	unfold isPDT. intuition. destruct H2. intuition. rewrite -> H2. trivial.
}
	intro newBlockEntryAddr.
	eapply bindRev.
{ (** readBlockEndFromBlockEntryAddr **)
	eapply weaken. apply readBlockEndFromBlockEntryAddr.
	intros. simpl. split. apply H.
	unfold isBE. intuition. destruct H3. intuition.
 	unfold consistency in *. intuition.
	assert(HfirstfreeslotBEs : FirstFreeSlotPointerIsBEAndFreeSlot s) by intuition.
	unfold FirstFreeSlotPointerIsBEAndFreeSlot in *.
	(*destruct HfirstfreeslotBEs with pdinsertion x as [HBE HFreeSlot]. intuition.*)
	specialize(HfirstfreeslotBEs pdinsertion x H3).
	- assert (Hfirstfreeslotnotnulls : FirstFreeSlotPointerNotNullEq s) by intuition.
		unfold FirstFreeSlotPointerNotNullEq in *.
		pose (H_slotnotnull := Hfirstfreeslotnotnulls pdinsertion currnbfreeslots).
		destruct H_slotnotnull as [Hleft Hright]. pose (H_conj := conj H5 H7).
		destruct Hleft as [Hslotpointer Hnull]. assumption. unfold pdentryFirstFreeSlot in *.
		rewrite H3 in *. (*destruct Hnull. subst. assumption.
	-	unfold pdentryFirstFreeSlot in *.
		rewrite H3 in H1. subst. rewrite isBELookupEq in HBE. destruct HBE.
		rewrite H1. trivial.*)
		intuition. subst. intuition.
}
	intro newFirstFreeSlotAddr.
	eapply bindRev.
{	(** Index.pred **)
	eapply weaken. apply Index.pred.
	intros. simpl. split. apply H. intuition.
}
	intro predCurrentNbFreeSlots. simpl.
		eapply bindRev.
	{ (** MAL.writePDFirstFreeSlotPointer **)
		eapply weaken. apply WP.writePDFirstFreeSlotPointer.
		intros. simpl. intuition. destruct H5. exists x. split. assumption.
		assert(isBE newBlockEntryAddr s).
		{
			unfold isBE.
			assert(HfirstfreeslotBEs : FirstFreeSlotPointerIsBEAndFreeSlot s)
				by (unfold consistency in * ; intuition).
			unfold FirstFreeSlotPointerIsBEAndFreeSlot in *.
			(*destruct H11 with pdinsertion x as [HBE HFreeSlot]. intuition.*)
			specialize(HfirstfreeslotBEs pdinsertion x H5).
			- assert (HFirstFreeSlotPointerNotNullEqs : FirstFreeSlotPointerNotNullEq s)
							by (unfold consistency in * ; intuition).
				unfold FirstFreeSlotPointerNotNullEq in *.
				pose (H_slotnotnull := HFirstFreeSlotPointerNotNullEqs pdinsertion currnbfreeslots).
				destruct H_slotnotnull as [Hleft Hright]. pose (H_conj := conj H7 H9).
				destruct Hleft as [Hslotpointer Hnull]. assumption.
				unfold pdentryFirstFreeSlot in *.
				rewrite H5 in *. (*destruct Hnull. subst. assumption.
			-	unfold pdentryFirstFreeSlot in *.
				rewrite H5 in H3. subst. rewrite isBELookupEq in HBE. destruct HBE.
				rewrite H3. trivial.*)
				intuition. subst. intuition.
	}
instantiate (1:= fun _ s => (*exists pd : PDTable, lookup pdinsertion (memory s) beqAddr = Some (PDT pd) /\*)
     (*pdentryNbFreeSlots pdinsertion currnbfreeslots s /\ currnbfreeslots > 0 /\*)
     (*pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s /\
    bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s /\*)
isBE newBlockEntryAddr s /\
   StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots

/\ (exists s0, exists pdentry newpdentry: PDTable, (*lookup pdinsertion (memory s0) beqAddr = Some (PDT pdentry)
/\*) s = {|
     currentPartition := currentPartition s0;
     memory := add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry;
										vidtBlock := vidtBlock pdentry |}) (memory s0) beqAddr |}
/\ lookup pdinsertion (memory s0) beqAddr = Some (PDT pdentry)
/\ lookup pdinsertion (memory s) beqAddr = Some (PDT newpdentry) /\
newpdentry = {|    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry;
										vidtBlock := vidtBlock pdentry|}
(*consistency s /\*)
	(*  /\  (exists olds : state, P olds /\ partitionsIsolation olds /\
       verticalSharing olds /\ consistency olds /\ pdentryFirstFreeSlot pdinsertion newBlockEntryAddr olds /\
    bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr olds)*)
/\ P s0 /\ partitionsIsolation s0 /\
       verticalSharing s0 /\ consistency s0 /\ pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s0 /\
    bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s0 /\ isBE newBlockEntryAddr s0
		/\ isPDT pdinsertion s0 /\ (pdentryNbFreeSlots pdinsertion currnbfreeslots s0 /\ currnbfreeslots > 0))
). intros. simpl. (*intuition.
	eexists.*) rewrite beqAddrTrue. intuition. (*
			split. f_equal. f_equal. intuition.*)
			- unfold isBE. cbn.
				(* show pdinsertion <> newBlockEntryAddr *)
				unfold pdentryFirstFreeSlot in *. rewrite H5 in H3.
				apply isBELookupEq in H6. destruct H6.
				destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hbeq.
				+ rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
					rewrite Hbeq in *. congruence.
				+ rewrite removeDupIdentity. rewrite H6. trivial.
					rewrite <- beqAddrFalse in Hbeq. intuition.
			(*unfold pdentryFirstFreeSlot in *. cbn. rewrite beqAddrTrue. cbn.
			unfold bentryEndAddr in *. repeat rewrite H5 in *. intuition. subst. *)
			- exists s. exists x. eexists. intuition.
				unfold isPDT. rewrite H5. trivial.
			(*- exists s. intuition.*)
}	intros. simpl.
(*
		2 : { intros. exact H. }
		unfold MAL.writePDFirstFreeSlotPointer.
		eapply bindRev.
		{ (** get **)
			eapply weaken. apply get.
			intro s. intros. simpl. instantiate (1:= fun s s0 => s = s0 /\
((((*partitionsIsolation s /\
       verticalSharing s /\*)
				P s0 /\
       (exists pdentry : PDTable,
          lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry)) /\
          (pdentryNbFreeSlots pdinsertion currnbfreeslots s /\
          currnbfreeslots > 0) (*/\ consistency s *)/\
      pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s) /\
     bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s) /\
    StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots)). intuition.
	}
		intro s0. intuition.
		destruct (lookup pdinsertion (memory s0) beqAddr) eqn:Hlookup.
		destruct v eqn:Hv.
		4 : {
		{ (** modify **)
			instantiate (1:= fun _ s => exists pd : PDTable, lookup pdinsertion (memory s) beqAddr = Some (PDT pd) /\
     (*pdentryNbFreeSlots pdinsertion currnbfreeslots s /\ currnbfreeslots > 0 /\*)
     (*pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s /\
    bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s /\*)
   StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots

/\ (exists s0, exists pdentry : PDTable, (*lookup pdinsertion (memory s0) beqAddr = Some (PDT pdentry)
/\*) s = {|
     currentPartition := currentPartition s0;
     memory := add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry |}) (memory s0) beqAddr |}
  ) /\
	(exists olds : state, P olds)
).
			unfold Monad.modify.
			eapply bindRev. eapply weaken. apply get. intros. simpl.
			pattern s in H. apply H.
			intro ss.
			eapply weaken. apply put.
			intros. simpl. set (s' := {|
      currentPartition :=  _|}).
			eexists. split. rewrite beqAddrTrue. f_equal.
			split. assumption.
			split. exists ss. exists p. intuition.
			unfold pdentryNbFreeSlots in *. destruct H. destruct H.
			destruct H. destruct H. rewrite Hlookup in H2.
			cbn. rewrite beqAddrTrue. cbn. intuition. intuition.
			(*admit. admit.*)
			exists ss. exists p. intuition.

} }			eapply weaken. apply undefined. intros. intuition. destruct H. congruence.
eapply weaken. apply undefined. intros. intuition. destruct H. congruence.
eapply weaken. apply undefined. intros. intuition. destruct H. congruence.
eapply weaken. apply undefined. intros. intuition. destruct H. congruence.
eapply weaken. apply undefined. intros. intuition. destruct H. congruence. }
		intros. simpl.*)

eapply bindRev.
	{ (**  MAL.writePDNbFreeSlots **)
		eapply weaken. apply WP.writePDNbFreeSlots.
		intros. intuition.
		(*destruct H.*) destruct H2. destruct H1. destruct H1.
		exists x1. split. intuition.
instantiate (1:= fun _ s => (*exists pd : PDTable, lookup pdinsertion (memory s) beqAddr = Some (PDT pd) /\*)
isBE newBlockEntryAddr s /\
pdentryNbFreeSlots pdinsertion predCurrentNbFreeSlots s (*/\ predCurrentNbFreeSlots > 0*) /\
    (* pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s /\
    bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s /\*)
   StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots

/\ (exists s0, exists pdentry : PDTable, (*lookup pdinsertion (memory s0) beqAddr = Some (PDT pdentry)
/\*)  exists pdentry0 newpdentry : PDTable, s = {|
     currentPartition := currentPartition s0;
     memory := add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry0;
                    firstfreeslot := firstfreeslot pdentry0;
                    nbfreeslots := predCurrentNbFreeSlots;
                    nbprepare := nbprepare pdentry0;
                    parent := parent pdentry0;
                    MPU := MPU pdentry0;
										vidtBlock := vidtBlock pdentry0 |})
								(add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry;
										vidtBlock := vidtBlock pdentry |}) (memory s0) beqAddr) beqAddr |}
/\ lookup pdinsertion (memory s0) beqAddr = Some (PDT pdentry)
/\ lookup pdinsertion (memory s) beqAddr = Some (PDT newpdentry) /\
newpdentry = {|     structure := structure pdentry0;
                    firstfreeslot := firstfreeslot pdentry0;
                    nbfreeslots := predCurrentNbFreeSlots;
                    nbprepare := nbprepare pdentry0;
                    parent := parent pdentry0;
                    MPU := MPU pdentry0;
										vidtBlock := vidtBlock pdentry0 |} /\
pdentry0 = {|    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry;
										vidtBlock := vidtBlock pdentry|}
(*/\
(exists olds : state, P olds /\ partitionsIsolation olds /\
       verticalSharing olds /\ consistency olds /\ pdentryFirstFreeSlot pdinsertion newBlockEntryAddr olds /\
    bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr olds)*)

/\ P s0 /\ partitionsIsolation s0 /\
       verticalSharing s0 /\ consistency s0 /\ pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s0 /\
    bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s0 /\ isBE newBlockEntryAddr s0
/\ isPDT pdinsertion s0 /\ (pdentryNbFreeSlots pdinsertion currnbfreeslots s0 /\ currnbfreeslots > 0)

)). 	intros. simpl.  set (s' := {|
      currentPartition :=  _|}).
			(*eexists x. split. rewrite beqAddrTrue.  f_equal.*)
			split.
			- unfold isBE. cbn. intuition.
			(* DUP: show pdinsertion <> newBlockEntryAddr *)
				apply isBELookupEq in H0. destruct H0.
				destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hbeq.
				+ rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
					rewrite Hbeq in *. congruence.
				+ rewrite removeDupIdentity. rewrite H0. trivial.
					rewrite <- beqAddrFalse in Hbeq. intuition.
			- intuition. unfold pdentryNbFreeSlots in *. cbn. rewrite beqAddrTrue.
				destruct (beqAddr newBlockEntryAddr pdinsertion) eqn:Hbeq.
				+ rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
					rewrite Hbeq in *. cbn. congruence.
				+ cbn. rewrite <- beqAddrFalse in Hbeq. intuition.
				+ intuition.
					(*destruct H3.
					destruct H2. destruct H2.*)

					(*destruct H4. destruct H3. destruct H3.*)

					exists x. exists x0. exists x1. eexists. unfold s'.
					rewrite beqAddrTrue. rewrite H2. (*s*) intuition.
}	intros. simpl.

(*
		2 : { intros. exact H. }
		unfold MAL.writePDNbFreeSlots.
		eapply bindRev.
		{ (** get **)
			eapply weaken. apply get.
			intro s. intros. simpl. instantiate (1:= fun s s0 => s = s0 /\
exists pd : PDTable,
      lookup pdinsertion (memory s) beqAddr = Some (PDT pd) /\
      pdentryNbFreeSlots pdinsertion currnbfreeslots s /\
      currnbfreeslots > 0 /\
      (*pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s /\
      bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s /\*)
      StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots /\
      (exists (s0 : state) (pdentry : PDTable),
         s =
         {|
         currentPartition := currentPartition s0;
         memory := add pdinsertion
                     (PDT
                        {|
                        structure := structure pdentry;
                        firstfreeslot := newFirstFreeSlotAddr;
                        nbfreeslots := nbfreeslots pdentry;
                        nbprepare := nbprepare pdentry;
                        parent := parent pdentry;
                        MPU := MPU pdentry |}) (memory s0) beqAddr |})). intuition.
	}
		intro s0. intuition.
		destruct (lookup pdinsertion (memory s0) beqAddr) eqn:Hlookup.
		destruct v eqn:Hv.
		4 : {
		{ (** modify **)
			instantiate (1:= fun _ s => exists pd : PDTable, lookup pdinsertion (memory s) beqAddr = Some (PDT pd) /\
     pdentryNbFreeSlots pdinsertion predCurrentNbFreeSlots s (*/\ predCurrentNbFreeSlots > 0*) /\
     (*pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s /\
    bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s /\*)
   StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots

/\ (exists s0, exists pdentry : PDTable, (*lookup pdinsertion (memory s0) beqAddr = Some (PDT pdentry)
/\*)  exists pdentry0 : PDTable, s = {|
     currentPartition := currentPartition s0;
     memory := add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry0;
                    firstfreeslot := firstfreeslot pdentry0;
                    nbfreeslots := predCurrentNbFreeSlots;
                    nbprepare := nbprepare pdentry0;
                    parent := parent pdentry0;
                    MPU := MPU pdentry0 |})
								(add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry |}) (memory s0) beqAddr) beqAddr |}

)).
			eapply weaken. apply modify.
			intros. simpl.  set (s' := {|
      currentPartition :=  _|}).
			eexists. split. rewrite beqAddrTrue. f_equal.
			split. unfold pdentryNbFreeSlots in *. destruct H. destruct H.
			destruct H0. destruct H. rewrite Hlookup in H0.
			cbn. rewrite beqAddrTrue. cbn. intuition. intuition.
			destruct H1. intuition.
			destruct H1. intuition. destruct H5. destruct H4.
			exists x0. exists x1. exists p. subst. intuition. }
}
			eapply weaken. apply undefined. intros. intuition. destruct H1. intuition. congruence.
eapply weaken. apply undefined. intros. intuition. destruct H1. intuition. congruence.
eapply weaken. apply undefined. intros. intuition. destruct H1. intuition. congruence.
eapply weaken. apply undefined. intros. intuition. destruct H1. intuition. congruence.
eapply weaken. apply undefined. intros. intuition. destruct H1. intuition. congruence. }
intros. simpl.*)

eapply bindRev.
	{ (**  MAL.writeBlockStartFromBlockEntryAddr **)
		eapply weaken. apply WP.writeBlockStartFromBlockEntryAddr.
		intros. intuition.
		destruct H3. intuition. destruct H2. destruct H2. destruct H2.
		assert(HBE : isBE newBlockEntryAddr s) by intuition.
		apply isBELookupEq in HBE.
		destruct HBE as [Hbentry Hlookupbentry]. exists Hbentry.
		assert(HblockNotPD : beqAddr newBlockEntryAddr pdinsertion = false).
		{		destruct (beqAddr newBlockEntryAddr pdinsertion) eqn:Hbeq.
					* rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
						rewrite Hbeq in *. unfold isPDT in *. unfold isBE in *.
						destruct (lookup pdinsertion (memory s) beqAddr) eqn:Hfalse ; try(exfalso ; congruence).
						destruct v eqn:Hvfalse ; try(exfalso ; congruence). intuition. congruence.
					* reflexivity.
		}
		split.
		-- 	intuition. (*rewrite H5. cbn. rewrite beqAddrTrue.
				rewrite beqAddrSym. rewrite HblockNotPD.
						rewrite <- beqAddrFalse in HblockNotPD.
						repeat rewrite removeDupIdentity ; intuition.*)
				(*destruct (beqAddr newBlockEntryAddr pdinsertion) eqn:Hbeq.
					* rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
						rewrite Hbeq in *. unfold isPDT in *. unfold isBE in *.
						destruct (lookup pdinsertion (memory x0) beqAddr) eqn:Hfalse ; try(exfalso ; congruence).
						destruct v eqn:Hvfalse ; try(exfalso ; congruence).
					* rewrite beqAddrSym. rewrite Hbeq.
						rewrite <- beqAddrFalse in Hbeq.
						repeat rewrite removeDupIdentity ; intuition.*)
		-- instantiate (1:= fun _ s => exists pd : PDTable, lookup pdinsertion (memory s) beqAddr = Some (PDT pd) /\
(*isBE newBlockEntryAddr s /\*)
pdentryNbFreeSlots pdinsertion predCurrentNbFreeSlots s (*/\ predCurrentNbFreeSlots > 0*) /\
     (*pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s /\
    bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s /\*)
   StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots

/\ (exists s0, exists pdentry : PDTable, exists pdentry0 pdentry1 : PDTable,
		exists bentry newEntry: BlockEntry,
  s = {|
     currentPartition := currentPartition s0;
     memory := add newBlockEntryAddr
                     (BE
                        (CBlockEntry (read bentry) (write bentry)
                           (exec bentry) (present bentry) (accessible bentry)
                           (blockindex bentry)
                           (CBlock startaddr (endAddr (blockrange bentry)))))
								(add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry0;
                    firstfreeslot := firstfreeslot pdentry0;
                    nbfreeslots := predCurrentNbFreeSlots;
                    nbprepare := nbprepare pdentry0;
                    parent := parent pdentry0;
                    MPU := MPU pdentry0;
										vidtBlock := vidtBlock pdentry0 |})
								(add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry;
										vidtBlock := vidtBlock pdentry |}) (memory s0) beqAddr) beqAddr) beqAddr |}
/\ lookup newBlockEntryAddr (memory s0) beqAddr = Some (BE bentry)
/\ lookup newBlockEntryAddr (memory s) beqAddr = Some (BE newEntry)
/\ newEntry = (CBlockEntry (read bentry) (write bentry)
                           (exec bentry) (present bentry) (accessible bentry)
                           (blockindex bentry)
                           (CBlock startaddr (endAddr (blockrange bentry))))
/\ lookup pdinsertion (memory s0) beqAddr = Some (PDT pdentry)
/\ lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry1) /\
pdentry1 = {|     structure := structure pdentry0;
                    firstfreeslot := firstfreeslot pdentry0;
                    nbfreeslots := predCurrentNbFreeSlots;
                    nbprepare := nbprepare pdentry0;
                    parent := parent pdentry0;
                    MPU := MPU pdentry0;
										vidtBlock := vidtBlock pdentry0 |} /\
pdentry0 = {|    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry;
										vidtBlock := vidtBlock pdentry|}

(*  /\
(exists olds : state, P olds /\ partitionsIsolation olds /\
       verticalSharing olds /\ consistency olds /\ pdentryFirstFreeSlot pdinsertion newBlockEntryAddr olds /\
    bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr olds)*)
/\ P s0 /\ partitionsIsolation s0 /\
       verticalSharing s0 /\ consistency s0 /\ pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s0 /\
    bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s0 /\
(*isBE newBlockEntryAddr s0*)
isPDT pdinsertion s0 /\ (pdentryNbFreeSlots pdinsertion currnbfreeslots s0 /\ currnbfreeslots > 0)
)). 	intros. simpl.  set (s' := {|
      currentPartition :=  _|}).
			exists x2. split.
			- destruct (beqAddr newBlockEntryAddr pdinsertion) eqn:Hbeq.
				+ f_equal. rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
					rewrite Hbeq in *. congruence.
				+ rewrite removeDupIdentity. intuition.
					rewrite <- beqAddrFalse in Hbeq. intuition.
			- split.
			(*unfold isBE. cbn. intuition.
			rewrite beqAddrTrue. trivial.
			intuition.*)
			* unfold pdentryNbFreeSlots in *. cbn.
			destruct (beqAddr newBlockEntryAddr pdinsertion) eqn:Hbeq.
				+ rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
					rewrite Hbeq in *. congruence.
				+ rewrite removeDupIdentity. assumption.
					rewrite <- beqAddrFalse in Hbeq. intuition.
			* intuition.
					(*destruct H4. destruct H3. destruct H3.*)
					assert(HBEs0 : isBE newBlockEntryAddr x) by intuition.
					apply isBELookupEq in HBEs0. destruct HBEs0 as [Hbentry0 HBEs0].
					exists x. exists x0. exists x1. exists x2. eexists. eexists.
					rewrite beqAddrTrue.
					destruct (beqAddr newBlockEntryAddr pdinsertion) eqn:Hbeq.
				+ rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
					rewrite Hbeq in *. congruence.
				+ rewrite removeDupIdentity. intuition.
					unfold s'. rewrite H3. f_equal. intuition.
					assert(Hlookups0 : lookup newBlockEntryAddr (memory s) beqAddr = lookup newBlockEntryAddr (memory x) beqAddr).
					{ rewrite H3. cbn. rewrite <- beqAddrFalse in Hbeq.
						destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hf ; try(exfalso ; congruence).
						rewrite <- DependentTypeLemmas.beqAddrTrue in Hf.
						unfold isBE in H0. rewrite <- Hf. congruence.
						rewrite beqAddrTrue. repeat rewrite removeDupIdentity ; intuition.
					}
					rewrite <- Hlookups0. intuition.
					rewrite <- beqAddrFalse in Hbeq. intuition.
}	intros. simpl.

(*
		2 : { intros. exact H. }
		unfold MAL.writeBlockStartFromBlockEntryAddr.
		eapply bindRev.
		{ (** get **)
			eapply weaken. apply get.
			intro s. intros. simpl. instantiate (1:= fun s s0 => s = s0 /\
exists pd : PDTable,
      lookup pdinsertion (memory s) beqAddr = Some (PDT pd) /\
      pdentryNbFreeSlots pdinsertion predCurrentNbFreeSlots s /\
      (*predCurrentNbFreeSlots > 0 /\
      pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s /\
      bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s /\*)
      StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots /\
      (exists (s0 : state) (pdentry pdentry0 : PDTable),
         s =
         {|
         currentPartition := currentPartition s0;
         memory := add pdinsertion
                     (PDT
                        {|
                        structure := structure pdentry0;
                        firstfreeslot := firstfreeslot pdentry0;
                        nbfreeslots := predCurrentNbFreeSlots;
                        nbprepare := nbprepare pdentry0;
                        parent := parent pdentry0;
                        MPU := MPU pdentry0 |})
                     (add pdinsertion
                        (PDT
                           {|
                           structure := structure pdentry;
                           firstfreeslot := newFirstFreeSlotAddr;
                           nbfreeslots := nbfreeslots pdentry;
                           nbprepare := nbprepare pdentry;
                           parent := parent pdentry;
                           MPU := MPU pdentry |}) (memory s0) beqAddr) beqAddr |})). intuition.
	}
		intro s0. intuition.
		destruct (lookup newBlockEntryAddr (memory s0) beqAddr) eqn:Hlookup.
		destruct v eqn:Hv.
		4 : {
		{ (** modify **)
			instantiate (1:= fun _ s => exists pd : PDTable, lookup pdinsertion (memory s) beqAddr = Some (PDT pd) /\
     pdentryNbFreeSlots pdinsertion predCurrentNbFreeSlots s /\ predCurrentNbFreeSlots > 0 /\
     pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s /\
    bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s /\
   StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots

/\ (exists s0, exists pdentry : PDTable, exists pdentry0 : PDTable,
		exists bentry : BlockEntry,
  s = {|
     currentPartition := currentPartition s0;
     memory := add newBlockEntryAddr
                     (BE
                        (CBlockEntry (read bentry) (write bentry)
                           (exec bentry) (present bentry) (accessible bentry)
                           (blockindex bentry)
                           (CBlock startaddr (endAddr (blockrange bentry)))))
								(add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry0;
                    firstfreeslot := firstfreeslot pdentry0;
                    nbfreeslots := predCurrentNbFreeSlots;
                    nbprepare := nbprepare pdentry0;
                    parent := parent pdentry0;
                    MPU := MPU pdentry0 |})
								(add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry |}) (memory s0) beqAddr) beqAddr) beqAddr |}

)). admit. } }
			eapply weaken. apply modify.
			intros. simpl.  set (s' := {|
      currentPartition :=  _|}). destruct H. destruct H0. exists x.

			split. cbn. admit.
			split. unfold pdentryNbFreeSlots in *. destruct H. destruct H0.
			destruct H0. rewrite H in H0. admit. intuition. intuition.
			admit. admit. destruct H7. destruct H6. destruct H6.
			exists x0. exists x1. exists x2. exists b. subst. intuition.
			admit. admit. admit. admit. }
intros. simpl.*)

eapply bindRev.
	{ (**  MAL.writeBlockEndFromBlockEntryAddr **)
		eapply weaken. apply WP.writeBlockEndFromBlockEntryAddr.
		intros. intuition.
		destruct H. intuition.
		destruct H3. destruct H2. destruct H2. destruct H2. destruct H2. destruct H2.
		exists x5. intuition.
			instantiate (1:= fun _ s => exists pd : PDTable, lookup pdinsertion (memory s) beqAddr = Some (PDT pd) /\
(*isBE newBlockEntryAddr s /\*)
pdentryNbFreeSlots pdinsertion predCurrentNbFreeSlots s (*/\ predCurrentNbFreeSlots > 0*) /\
     (*pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s /\
    bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s /\*)
   StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots

/\ (exists s0, exists pdentry : PDTable, exists pdentry0 pdentry1: PDTable,
		exists bentry bentry0 newEntry: BlockEntry,
  s = {|
     currentPartition := currentPartition s0;
     memory := add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry0) (write bentry0) (exec bentry0)
                       (present bentry0) (accessible bentry0) (blockindex bentry0)
                       (CBlock (startAddr (blockrange bentry0)) endaddr)))
							(add newBlockEntryAddr
                     (BE
                        (CBlockEntry (read bentry) (write bentry)
                           (exec bentry) (present bentry) (accessible bentry)
                           (blockindex bentry)
                           (CBlock startaddr (endAddr (blockrange bentry)))))
								(add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry0;
                    firstfreeslot := firstfreeslot pdentry0;
                    nbfreeslots := predCurrentNbFreeSlots;
                    nbprepare := nbprepare pdentry0;
                    parent := parent pdentry0;
                    MPU := MPU pdentry0;
										vidtBlock := vidtBlock pdentry0 |})
								(add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry;
										vidtBlock := vidtBlock pdentry |}) (memory s0) beqAddr) beqAddr) beqAddr) beqAddr |}
/\ lookup newBlockEntryAddr (memory s0) beqAddr = Some (BE bentry)
/\ lookup newBlockEntryAddr (memory s) beqAddr = Some (BE newEntry) /\
newEntry = (CBlockEntry (read bentry0) (write bentry0) (exec bentry0)
                       (present bentry0) (accessible bentry0) (blockindex bentry0)
                       (CBlock (startAddr (blockrange bentry0)) endaddr))
/\
bentry0 = (CBlockEntry (read bentry) (write bentry)
                           (exec bentry) (present bentry) (accessible bentry)
                           (blockindex bentry)
                           (CBlock startaddr (endAddr (blockrange bentry))))
/\ lookup pdinsertion (memory s0) beqAddr = Some (PDT pdentry)
/\ lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry1) /\
pdentry1 = {|     structure := structure pdentry0;
                    firstfreeslot := firstfreeslot pdentry0;
                    nbfreeslots := predCurrentNbFreeSlots;
                    nbprepare := nbprepare pdentry0;
                    parent := parent pdentry0;
                    MPU := MPU pdentry0;
										vidtBlock := vidtBlock pdentry0 |} /\
pdentry0 = {|    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry;
										vidtBlock := vidtBlock pdentry|}

(*  /\
(exists olds : state, P olds /\ partitionsIsolation olds /\
       verticalSharing olds /\ consistency olds /\ pdentryFirstFreeSlot pdinsertion newBlockEntryAddr olds /\
    bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr olds)*)
/\ P s0 /\ partitionsIsolation s0 /\
       verticalSharing s0 /\ consistency s0 /\ pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s0 /\
    bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s0 (*/\ isBE newBlockEntryAddr s0*)
/\ isPDT pdinsertion s0 /\ (pdentryNbFreeSlots pdinsertion currnbfreeslots s0 /\ currnbfreeslots > 0)
)). 	intros. simpl.  set (s' := {|
      currentPartition :=  _|}).
			intuition. exists x. split.
			- destruct (beqAddr newBlockEntryAddr pdinsertion) eqn:Hbeq.
				+ f_equal. rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
					rewrite Hbeq in *. congruence.
				+ rewrite removeDupIdentity. assumption.
					rewrite <- beqAddrFalse in Hbeq. intuition.
			- split.
				+ (*unfold isBE. cbn. rewrite beqAddrTrue. trivial.*)
					unfold pdentryNbFreeSlots in *. cbn.
					destruct (beqAddr newBlockEntryAddr pdinsertion) eqn:Hbeq.
						* rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
							rewrite Hbeq in *. congruence.
						* rewrite removeDupIdentity. assumption.
							rewrite <- beqAddrFalse in Hbeq. intuition.
				+ intuition.
							exists x0. exists x1. exists x2. exists x3. exists x4. exists x5.
							rewrite beqAddrTrue. eexists. unfold s'. intuition. rewrite H3. intuition.
				destruct (beqAddr newBlockEntryAddr pdinsertion) eqn:Hbeq.
						* rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
							rewrite Hbeq in *. congruence.
						* rewrite removeDupIdentity. assumption.
							rewrite <- beqAddrFalse in Hbeq. intuition.
}	intros. simpl.

(*
		2 : { intros. exact H. }
		unfold MAL.writeBlockEndFromBlockEntryAddr.
		eapply bindRev.
		{ (** get **)
			eapply weaken. apply get.
			intro s. intros. simpl. instantiate (1:= fun s s0 => s = s0 /\
exists pd : PDTable,
      lookup pdinsertion (memory s) beqAddr = Some (PDT pd) /\
      pdentryNbFreeSlots pdinsertion predCurrentNbFreeSlots s /\
      predCurrentNbFreeSlots > 0 /\
      pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s /\
      bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s /\
      StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots /\
      (exists (s0 : state) (pdentry pdentry0 : PDTable) (bentry : BlockEntry),
         s =
         {|
         currentPartition := currentPartition s0;
         memory := add newBlockEntryAddr
                     (BE
                        (CBlockEntry (read bentry) (write bentry)
                           (exec bentry) (present bentry)
                           (accessible bentry) (blockindex bentry)
                           (CBlock startaddr (endAddr (blockrange bentry)))))
                     (add pdinsertion
                        (PDT
                           {|
                           structure := structure pdentry0;
                           firstfreeslot := firstfreeslot pdentry0;
                           nbfreeslots := predCurrentNbFreeSlots;
                           nbprepare := nbprepare pdentry0;
                           parent := parent pdentry0;
                           MPU := MPU pdentry0 |})
                        (add pdinsertion
                           (PDT
                              {|
                              structure := structure pdentry;
                              firstfreeslot := newFirstFreeSlotAddr;
                              nbfreeslots := nbfreeslots pdentry;
                              nbprepare := nbprepare pdentry;
                              parent := parent pdentry;
                              MPU := MPU pdentry |}) (memory s0) beqAddr) beqAddr)
                     beqAddr |})). intuition.
	}
		intro s0. intuition.
		destruct (lookup newBlockEntryAddr (memory s0) beqAddr) eqn:Hlookup.
		destruct v eqn:Hv.
		{ (** modify **)
			instantiate (1:= fun _ s => exists pd : PDTable, lookup pdinsertion (memory s) beqAddr = Some (PDT pd) /\
     pdentryNbFreeSlots pdinsertion predCurrentNbFreeSlots s /\ predCurrentNbFreeSlots > 0 /\
     pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s /\
    bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s /\
   StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots

/\ (exists s0, exists pdentry : PDTable, exists pdentry0 : PDTable,
		exists bentry bentry0: BlockEntry,
  s = {|
     currentPartition := currentPartition s0;
     memory := add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry0) (write bentry0) (exec bentry0)
                       (present bentry0) (accessible bentry0) (blockindex bentry0)
                       (CBlock (startAddr (blockrange bentry0)) endaddr)))
							(add newBlockEntryAddr
                     (BE
                        (CBlockEntry (read bentry) (write bentry)
                           (exec bentry) (present bentry) (accessible bentry)
                           (blockindex bentry)
                           (CBlock startaddr (endAddr (blockrange bentry)))))
								(add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry0;
                    firstfreeslot := firstfreeslot pdentry0;
                    nbfreeslots := predCurrentNbFreeSlots;
                    nbprepare := nbprepare pdentry0;
                    parent := parent pdentry0;
                    MPU := MPU pdentry0 |})
								(add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry |}) (memory s0) beqAddr) beqAddr) beqAddr) beqAddr |}

)).
			eapply weaken. apply modify.
			intros. simpl.  set (s' := {|
      currentPartition :=  _|}). destruct H. destruct H0. exists x.

			split. cbn. admit.
			split. unfold pdentryNbFreeSlots in *. destruct H. destruct H0.
			destruct H0. rewrite H in H0. admit. intuition. intuition.
			admit. admit. destruct H7. destruct H6. destruct H6. destruct H6.
			exists x0. exists x1. exists x2. exists x3. exists b. subst. intuition.
}
			admit. admit. admit. admit. admit. }
intros. simpl.*)



eapply bindRev.
	{ (**  MAL.writeBlockAccessibleFromBlockEntryAddr **)
		eapply weaken. apply WP.writeBlockAccessibleFromBlockEntryAddr.
		intros. intuition.
		destruct H. intuition.
		destruct H3. destruct H2. destruct H2. destruct H2. destruct H2. destruct H2.
		destruct H2.
		 exists x6. intuition.
			instantiate (1:= fun _ s => exists pd : PDTable, lookup pdinsertion (memory s) beqAddr = Some (PDT pd) /\
(*isBE newBlockEntryAddr s /\*)
pdentryNbFreeSlots pdinsertion predCurrentNbFreeSlots s (*/\ predCurrentNbFreeSlots > 0*) /\
     (*pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s /\
    bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s /\*)
   StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots

/\ (exists s0, exists pdentry : PDTable, exists pdentry0 pdentry1: PDTable,
		exists bentry bentry0 bentry1 newEntry: BlockEntry,
  s = {|
     currentPartition := currentPartition s0;
     memory := add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry1) (write bentry1) (exec bentry1)
                       (present bentry1) true (blockindex bentry1) (blockrange bentry1)))
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry0) (write bentry0) (exec bentry0)
                       (present bentry0) (accessible bentry0) (blockindex bentry0)
                       (CBlock (startAddr (blockrange bentry0)) endaddr)))
							(add newBlockEntryAddr
                     (BE
                        (CBlockEntry (read bentry) (write bentry)
                           (exec bentry) (present bentry) (accessible bentry)
                           (blockindex bentry)
                           (CBlock startaddr (endAddr (blockrange bentry)))))
								(add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry0;
                    firstfreeslot := firstfreeslot pdentry0;
                    nbfreeslots := predCurrentNbFreeSlots;
                    nbprepare := nbprepare pdentry0;
                    parent := parent pdentry0;
                    MPU := MPU pdentry0;
										vidtBlock := vidtBlock pdentry0 |})
								(add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry;
										vidtBlock := vidtBlock pdentry |}) (memory s0) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr |}
/\ lookup newBlockEntryAddr (memory s0) beqAddr = Some (BE bentry)
/\ lookup newBlockEntryAddr (memory s) beqAddr = Some (BE newEntry) /\
newEntry = (CBlockEntry (read bentry1) (write bentry1) (exec bentry1)
                       (present bentry1) true (blockindex bentry1) (blockrange bentry1))
/\
bentry1 = (CBlockEntry (read bentry0) (write bentry0) (exec bentry0)
                       (present bentry0) (accessible bentry0) (blockindex bentry0)
                       (CBlock (startAddr (blockrange bentry0)) endaddr))
/\
bentry0 = (CBlockEntry (read bentry) (write bentry)
                           (exec bentry) (present bentry) (accessible bentry)
                           (blockindex bentry)
                           (CBlock startaddr (endAddr (blockrange bentry))))
/\ lookup pdinsertion (memory s0) beqAddr = Some (PDT pdentry)
/\ lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry1) /\
pdentry1 = {|     structure := structure pdentry0;
                    firstfreeslot := firstfreeslot pdentry0;
                    nbfreeslots := predCurrentNbFreeSlots;
                    nbprepare := nbprepare pdentry0;
                    parent := parent pdentry0;
                    MPU := MPU pdentry0;
										vidtBlock := vidtBlock pdentry0 |} /\
pdentry0 = {|    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry;
										vidtBlock := vidtBlock pdentry|}
(*  /\
(exists olds : state, P olds /\ partitionsIsolation olds /\
       verticalSharing olds /\ consistency olds /\ pdentryFirstFreeSlot pdinsertion newBlockEntryAddr olds /\
    bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr olds)*)
/\ P s0 /\ partitionsIsolation s0 /\
       verticalSharing s0 /\ consistency s0 /\ pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s0 /\
    bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s0 (*/\ isBE newBlockEntryAddr s0*)
/\ isPDT pdinsertion s0 /\ (pdentryNbFreeSlots pdinsertion currnbfreeslots s0 /\ currnbfreeslots > 0)
)). 	intros. simpl.  set (s' := {|
      currentPartition :=  _|}).
			exists x. split.
			- (* DUP *)
				destruct (beqAddr newBlockEntryAddr pdinsertion) eqn:Hbeq.
				+ f_equal. rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
					rewrite Hbeq in *. congruence.
				+ rewrite removeDupIdentity. assumption.
					rewrite <- beqAddrFalse in Hbeq. intuition.
			- split.
				(*+ unfold isBE. cbn. rewrite beqAddrTrue. trivial.*)
				+ intuition.
					unfold pdentryNbFreeSlots in *. cbn.
					destruct (beqAddr newBlockEntryAddr pdinsertion) eqn:Hbeq.
						* rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
							rewrite Hbeq in *. congruence.
						* rewrite removeDupIdentity. assumption.
							rewrite <- beqAddrFalse in Hbeq. intuition.
				+ intuition.
							exists x0. exists x1. exists x2. exists x3. exists x4. exists x5.
							exists x6.
							rewrite beqAddrTrue. eexists. unfold s'. intuition. rewrite H3. intuition.
				destruct (beqAddr newBlockEntryAddr pdinsertion) eqn:Hbeq.
						* rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
							rewrite Hbeq in *. congruence.
						* rewrite removeDupIdentity. assumption.
							rewrite <- beqAddrFalse in Hbeq. intuition.
}	intros. simpl.

(*
		2 : { intros. exact H. }
		unfold MAL.writeBlockAccessibleFromBlockEntryAddr.
		eapply bindRev.
		{ (** get **)
			eapply weaken. apply get.
			intro s. intros. simpl. instantiate (1:= fun s s0 => s = s0 /\
exists pd : PDTable,
      lookup pdinsertion (memory s) beqAddr = Some (PDT pd) /\
      pdentryNbFreeSlots pdinsertion predCurrentNbFreeSlots s /\
      predCurrentNbFreeSlots > 0 /\
      pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s /\
      bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s /\
      StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots /\
      (exists
         (s0 : state) (pdentry pdentry0 : PDTable) (bentry bentry0 : BlockEntry),
         s =
         {|
         currentPartition := currentPartition s0;
         memory := add newBlockEntryAddr
                     (BE
                        (CBlockEntry (read bentry0) (write bentry0)
                           (exec bentry0) (present bentry0)
                           (accessible bentry0) (blockindex bentry0)
                           (CBlock (startAddr (blockrange bentry0)) endaddr)))
                     (add newBlockEntryAddr
                        (BE
                           (CBlockEntry (read bentry) (write bentry)
                              (exec bentry) (present bentry)
                              (accessible bentry) (blockindex bentry)
                              (CBlock startaddr (endAddr (blockrange bentry)))))
                        (add pdinsertion
                           (PDT
                              {|
                              structure := structure pdentry0;
                              firstfreeslot := firstfreeslot pdentry0;
                              nbfreeslots := predCurrentNbFreeSlots;
                              nbprepare := nbprepare pdentry0;
                              parent := parent pdentry0;
                              MPU := MPU pdentry0 |})
                           (add pdinsertion
                              (PDT
                                 {|
                                 structure := structure pdentry;
                                 firstfreeslot := newFirstFreeSlotAddr;
                                 nbfreeslots := nbfreeslots pdentry;
                                 nbprepare := nbprepare pdentry;
                                 parent := parent pdentry;
                                 MPU := MPU pdentry |}) (memory s0) beqAddr) beqAddr)
                        beqAddr) beqAddr |})). intuition.
	}
		intro s0. intuition.
		destruct (lookup newBlockEntryAddr (memory s0) beqAddr) eqn:Hlookup.
		destruct v eqn:Hv.
		{ (** modify **)
			instantiate (1:= fun _ s => exists pd : PDTable, lookup pdinsertion (memory s) beqAddr = Some (PDT pd) /\
     pdentryNbFreeSlots pdinsertion predCurrentNbFreeSlots s /\ predCurrentNbFreeSlots > 0 /\
     pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s /\
    bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s /\
   StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots

/\ (exists s0, exists pdentry : PDTable, exists pdentry0 : PDTable,
		exists bentry bentry0 bentry1: BlockEntry,
  s = {|
     currentPartition := currentPartition s0;
     memory := add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry1) (write bentry1) (exec bentry1)
                       (present bentry1) true (blockindex bentry1) (blockrange bentry1)))
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry0) (write bentry0) (exec bentry0)
                       (present bentry0) (accessible bentry0) (blockindex bentry0)
                       (CBlock (startAddr (blockrange bentry0)) endaddr)))
							(add newBlockEntryAddr
                     (BE
                        (CBlockEntry (read bentry) (write bentry)
                           (exec bentry) (present bentry) (accessible bentry)
                           (blockindex bentry)
                           (CBlock startaddr (endAddr (blockrange bentry)))))
								(add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry0;
                    firstfreeslot := firstfreeslot pdentry0;
                    nbfreeslots := predCurrentNbFreeSlots;
                    nbprepare := nbprepare pdentry0;
                    parent := parent pdentry0;
                    MPU := MPU pdentry0 |})
								(add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry |}) (memory s0) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr |}

)).
			eapply weaken. apply modify.
			intros. simpl.  set (s' := {|
      currentPartition :=  _|}). destruct H. destruct H0. exists x.

			split. cbn. admit.
			split. unfold pdentryNbFreeSlots in *. destruct H. destruct H0.
			destruct H0. rewrite H in H0. admit. intuition. intuition.
			admit. admit. destruct H7. destruct H6. destruct H6. destruct H6. destruct H6.
			exists x0. exists x1. exists x2. exists x3. exists x4. exists b. subst. intuition.
}
			admit. admit. admit. admit. admit. }
intros. simpl.*)

eapply bindRev.
	{ (**  MAL.writeBlockPresentFromBlockEntryAddr **)
		eapply weaken. apply WP.writeBlockPresentFromBlockEntryAddr.
		intros. intuition.
		destruct H. intuition.
		destruct H3. destruct H2. destruct H2. destruct H2. destruct H2. destruct H2.
		destruct H2. destruct H2.
		 exists x7. intuition.
			instantiate (1:= fun _ s => exists pd : PDTable, lookup pdinsertion (memory s) beqAddr = Some (PDT pd) /\
(*isBE newBlockEntryAddr s /\*)
pdentryNbFreeSlots pdinsertion predCurrentNbFreeSlots s (*/\ predCurrentNbFreeSlots > 0*) /\
     (*pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s /\
    bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s /\*)
   StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots

/\ (exists s0, exists pdentry : PDTable, exists pdentry0 pdentry1: PDTable,
		exists bentry bentry0 bentry1 bentry2 newEntry: BlockEntry,
  s = {|
     currentPartition := currentPartition s0;
     memory := add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry2) (write bentry2) (exec bentry2) true
                       (accessible bentry2) (blockindex bentry2) (blockrange bentry2)))
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry1) (write bentry1) (exec bentry1)
                       (present bentry1) true (blockindex bentry1) (blockrange bentry1)))
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry0) (write bentry0) (exec bentry0)
                       (present bentry0) (accessible bentry0) (blockindex bentry0)
                       (CBlock (startAddr (blockrange bentry0)) endaddr)))
							(add newBlockEntryAddr
                     (BE
                        (CBlockEntry (read bentry) (write bentry)
                           (exec bentry) (present bentry) (accessible bentry)
                           (blockindex bentry)
                           (CBlock startaddr (endAddr (blockrange bentry)))))
								(add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry0;
                    firstfreeslot := firstfreeslot pdentry0;
                    nbfreeslots := predCurrentNbFreeSlots;
                    nbprepare := nbprepare pdentry0;
                    parent := parent pdentry0;
                    MPU := MPU pdentry0;
										vidtBlock := vidtBlock pdentry0 |})
								(add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry;
										vidtBlock := vidtBlock pdentry|}) (memory s0) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr |}
/\ lookup newBlockEntryAddr (memory s0) beqAddr = Some (BE bentry)
/\ lookup newBlockEntryAddr (memory s) beqAddr = Some (BE newEntry) /\
newEntry = (CBlockEntry (read bentry2) (write bentry2) (exec bentry2) true
                       (accessible bentry2) (blockindex bentry2) (blockrange bentry2))
/\
bentry2 = (CBlockEntry (read bentry1) (write bentry1) (exec bentry1)
                       (present bentry1) true (blockindex bentry1) (blockrange bentry1))
/\
bentry1 = (CBlockEntry (read bentry0) (write bentry0) (exec bentry0)
                       (present bentry0) (accessible bentry0) (blockindex bentry0)
                       (CBlock (startAddr (blockrange bentry0)) endaddr))
/\
bentry0 = (CBlockEntry (read bentry) (write bentry)
                           (exec bentry) (present bentry) (accessible bentry)
                           (blockindex bentry)
                           (CBlock startaddr (endAddr (blockrange bentry))))
/\ lookup pdinsertion (memory s0) beqAddr = Some (PDT pdentry)
/\ lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry1) /\
pdentry1 = {|     structure := structure pdentry0;
                    firstfreeslot := firstfreeslot pdentry0;
                    nbfreeslots := predCurrentNbFreeSlots;
                    nbprepare := nbprepare pdentry0;
                    parent := parent pdentry0;
                    MPU := MPU pdentry0;
										vidtBlock := vidtBlock pdentry0 |} /\
pdentry0 = {|    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry;
										vidtBlock := vidtBlock pdentry|}

(*    /\
(exists olds : state, P olds /\ partitionsIsolation olds /\
       verticalSharing olds /\ consistency olds /\ pdentryFirstFreeSlot pdinsertion newBlockEntryAddr olds /\
    bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr olds)*)
/\ P s0 /\ partitionsIsolation s0 /\
       verticalSharing s0 /\ consistency s0 /\ pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s0 /\
    bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s0 (*/\ isBE newBlockEntryAddr s0*)
/\ isPDT pdinsertion s0 /\ (pdentryNbFreeSlots pdinsertion currnbfreeslots s0 /\ currnbfreeslots > 0)
)). 	intros. simpl.  set (s' := {|
      currentPartition :=  _|}).
			exists x. split.
			- (* DUP *)
				destruct (beqAddr newBlockEntryAddr pdinsertion) eqn:Hbeq.
				+ f_equal. rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
					rewrite Hbeq in *. congruence.
				+ rewrite removeDupIdentity. assumption.
					rewrite <- beqAddrFalse in Hbeq. intuition.
			- split.
				(*+ unfold isBE. cbn. rewrite beqAddrTrue. trivial.*)
				+ intuition.
					unfold pdentryNbFreeSlots in *. cbn.
					destruct (beqAddr newBlockEntryAddr pdinsertion) eqn:Hbeq.
						* rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
							rewrite Hbeq in *. congruence.
						* rewrite removeDupIdentity. assumption.
							rewrite <- beqAddrFalse in Hbeq. intuition.
				+ intuition.
							exists x0. exists x1. exists x2. exists x3. exists x4. exists x5.
							exists x6. exists x7.
							rewrite beqAddrTrue. eexists. unfold s'. intuition. rewrite H3. intuition.
						destruct (beqAddr newBlockEntryAddr pdinsertion) eqn:Hbeq.
						* rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
							rewrite Hbeq in *. congruence.
						* rewrite removeDupIdentity. assumption.
							rewrite <- beqAddrFalse in Hbeq. intuition.
}	intros. simpl.

(*
		2 : { intros. exact H. }
		unfold MAL.writeBlockPresentFromBlockEntryAddr.
		eapply bindRev.
		{ (** get **)
			eapply weaken. apply get.
			intro s. intros. simpl. instantiate (1:= fun s s0 => s = s0 /\
exists pd : PDTable,
      lookup pdinsertion (memory s) beqAddr = Some (PDT pd) /\
      pdentryNbFreeSlots pdinsertion predCurrentNbFreeSlots s /\
      predCurrentNbFreeSlots > 0 /\
      pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s /\
      bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s /\
      StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots /\
      (exists
         (s0 : state) (pdentry pdentry0 : PDTable) (bentry bentry0
                                                    bentry1 : BlockEntry),
         s =
         {|
         currentPartition := currentPartition s0;
         memory := add newBlockEntryAddr
                     (BE
                        (CBlockEntry (read bentry1) (write bentry1)
                           (exec bentry1) (present bentry1) true
                           (blockindex bentry1) (blockrange bentry1)))
                     (add newBlockEntryAddr
                        (BE
                           (CBlockEntry (read bentry0) (write bentry0)
                              (exec bentry0) (present bentry0)
                              (accessible bentry0) (blockindex bentry0)
                              (CBlock (startAddr (blockrange bentry0)) endaddr)))
                        (add newBlockEntryAddr
                           (BE
                              (CBlockEntry (read bentry)
                                 (write bentry) (exec bentry)
                                 (present bentry) (accessible bentry)
                                 (blockindex bentry)
                                 (CBlock startaddr (endAddr (blockrange bentry)))))
                           (add pdinsertion
                              (PDT
                                 {|
                                 structure := structure pdentry0;
                                 firstfreeslot := firstfreeslot pdentry0;
                                 nbfreeslots := predCurrentNbFreeSlots;
                                 nbprepare := nbprepare pdentry0;
                                 parent := parent pdentry0;
                                 MPU := MPU pdentry0 |})
                              (add pdinsertion
                                 (PDT
                                    {|
                                    structure := structure pdentry;
                                    firstfreeslot := newFirstFreeSlotAddr;
                                    nbfreeslots := nbfreeslots pdentry;
                                    nbprepare := nbprepare pdentry;
                                    parent := parent pdentry;
                                    MPU := MPU pdentry |})
                                 (memory s0) beqAddr) beqAddr) beqAddr) beqAddr)
                     beqAddr |})). intuition.
	}
		intro s0. intuition.
		destruct (lookup newBlockEntryAddr (memory s0) beqAddr) eqn:Hlookup.
		destruct v eqn:Hv.
		{ (** modify **)
			instantiate (1:= fun _ s => exists pd : PDTable, lookup pdinsertion (memory s) beqAddr = Some (PDT pd) /\
     pdentryNbFreeSlots pdinsertion predCurrentNbFreeSlots s /\ predCurrentNbFreeSlots > 0 /\
     pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s /\
    bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s /\
   StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots

/\ (exists s0, exists pdentry : PDTable, exists pdentry0 : PDTable,
		exists bentry bentry0 bentry1 bentry2: BlockEntry,
  s = {|
     currentPartition := currentPartition s0;
     memory := add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry2) (write bentry2) (exec bentry2) true
                       (accessible bentry2) (blockindex bentry2) (blockrange bentry2)))
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry1) (write bentry1) (exec bentry1)
                       (present bentry1) true (blockindex bentry1) (blockrange bentry1)))
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry0) (write bentry0) (exec bentry0)
                       (present bentry0) (accessible bentry0) (blockindex bentry0)
                       (CBlock (startAddr (blockrange bentry0)) endaddr)))
							(add newBlockEntryAddr
                     (BE
                        (CBlockEntry (read bentry) (write bentry)
                           (exec bentry) (present bentry) (accessible bentry)
                           (blockindex bentry)
                           (CBlock startaddr (endAddr (blockrange bentry)))))
								(add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry0;
                    firstfreeslot := firstfreeslot pdentry0;
                    nbfreeslots := predCurrentNbFreeSlots;
                    nbprepare := nbprepare pdentry0;
                    parent := parent pdentry0;
                    MPU := MPU pdentry0 |})
								(add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry |}) (memory s0) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr |}

)).
			eapply weaken. apply modify.
			intros. simpl.  set (s' := {|
      currentPartition :=  _|}). destruct H. destruct H0. exists x.

			split. cbn. admit.
			split. unfold pdentryNbFreeSlots in *. destruct H. destruct H0.
			destruct H0. rewrite H in H0. admit. intuition. intuition.
			admit. admit. destruct H7. destruct H6. destruct H6. destruct H6. destruct H6.
			destruct H6.
			exists x0. exists x1. exists x2. exists x3. exists x4. exists x5.
			exists b. subst. intuition.
}
			admit. admit. admit. admit. admit. }
intros. simpl. *)

eapply bindRev.
	{ (**  MAL.writeBlockRFromBlockEntryAddr **)
		eapply weaken. apply WP.writeBlockRFromBlockEntryAddr.
		intros. intuition.
		destruct H. intuition.
		destruct H3. destruct H2. destruct H2. destruct H2. destruct H2. destruct H2.
		destruct H2. destruct H2. destruct H2.
		 exists x8. intuition.
			instantiate (1:= fun _ s => exists pd : PDTable, lookup pdinsertion (memory s) beqAddr = Some (PDT pd) /\
(*isBE newBlockEntryAddr s /\*)
pdentryNbFreeSlots pdinsertion predCurrentNbFreeSlots s (*/\ predCurrentNbFreeSlots > 0*) /\
     (*pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s /\
    bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s /\*)
   StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots

/\ (exists s0, exists pdentry : PDTable, exists pdentry0 pdentry1: PDTable,
		exists bentry bentry0 bentry1 bentry2 bentry3 newEntry: BlockEntry,
  s = {|
     currentPartition := currentPartition s0;
     memory := add newBlockEntryAddr
                 (BE
                    (CBlockEntry r (write bentry3) (exec bentry3) (present bentry3)
                       (accessible bentry3) (blockindex bentry3) (blockrange bentry3)))
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry2) (write bentry2) (exec bentry2) true
                       (accessible bentry2) (blockindex bentry2) (blockrange bentry2)))
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry1) (write bentry1) (exec bentry1)
                       (present bentry1) true (blockindex bentry1) (blockrange bentry1)))
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry0) (write bentry0) (exec bentry0)
                       (present bentry0) (accessible bentry0) (blockindex bentry0)
                       (CBlock (startAddr (blockrange bentry0)) endaddr)))
							(add newBlockEntryAddr
                     (BE
                        (CBlockEntry (read bentry) (write bentry)
                           (exec bentry) (present bentry) (accessible bentry)
                           (blockindex bentry)
                           (CBlock startaddr (endAddr (blockrange bentry)))))
								(add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry0;
                    firstfreeslot := firstfreeslot pdentry0;
                    nbfreeslots := predCurrentNbFreeSlots;
                    nbprepare := nbprepare pdentry0;
                    parent := parent pdentry0;
                    MPU := MPU pdentry0;
										vidtBlock := vidtBlock pdentry0 |})
								(add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry;
										vidtBlock := vidtBlock pdentry |}) (memory s0) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr |}
/\ lookup newBlockEntryAddr (memory s0) beqAddr = Some (BE bentry)
/\ lookup newBlockEntryAddr (memory s) beqAddr = Some (BE newEntry) /\
newEntry = (CBlockEntry r (write bentry3) (exec bentry3) (present bentry3)
                       (accessible bentry3) (blockindex bentry3) (blockrange bentry3))
/\
bentry3 = (CBlockEntry (read bentry2) (write bentry2) (exec bentry2) true
                       (accessible bentry2) (blockindex bentry2) (blockrange bentry2))
/\
bentry2 = (CBlockEntry (read bentry1) (write bentry1) (exec bentry1)
                       (present bentry1) true (blockindex bentry1) (blockrange bentry1))
/\
bentry1 = (CBlockEntry (read bentry0) (write bentry0) (exec bentry0)
                       (present bentry0) (accessible bentry0) (blockindex bentry0)
                       (CBlock (startAddr (blockrange bentry0)) endaddr))
/\
bentry0 = (CBlockEntry (read bentry) (write bentry)
                           (exec bentry) (present bentry) (accessible bentry)
                           (blockindex bentry)
                           (CBlock startaddr (endAddr (blockrange bentry))))
/\ lookup pdinsertion (memory s0) beqAddr = Some (PDT pdentry)
/\ lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry1) /\
pdentry1 = {|     structure := structure pdentry0;
                    firstfreeslot := firstfreeslot pdentry0;
                    nbfreeslots := predCurrentNbFreeSlots;
                    nbprepare := nbprepare pdentry0;
                    parent := parent pdentry0;
                    MPU := MPU pdentry0;
										vidtBlock := vidtBlock pdentry0 |} /\
pdentry0 = {|    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry;
										vidtBlock := vidtBlock pdentry|}

(*      /\
(exists olds : state, P olds /\ partitionsIsolation olds /\
       verticalSharing olds /\ consistency olds /\ pdentryFirstFreeSlot pdinsertion newBlockEntryAddr olds /\
    bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr olds)*)
/\ P s0 /\ partitionsIsolation s0 /\
       verticalSharing s0 /\ consistency s0 /\ pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s0 /\
    bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s0 (*/\ isBE newBlockEntryAddr s0*)
/\ isPDT pdinsertion s0 /\ (pdentryNbFreeSlots pdinsertion currnbfreeslots s0 /\ currnbfreeslots > 0)
)). 	intros. simpl.  set (s' := {|
      currentPartition :=  _|}).
			exists x. split.
			- (* DUP *)
				destruct (beqAddr newBlockEntryAddr pdinsertion) eqn:Hbeq.
				+ f_equal. rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
					rewrite Hbeq in *. congruence.
				+ rewrite removeDupIdentity. assumption.
					rewrite <- beqAddrFalse in Hbeq. intuition.
			- split.
				(*+ unfold isBE. cbn. rewrite beqAddrTrue. trivial.*)
				+ intuition.
					unfold pdentryNbFreeSlots in *. cbn.
					destruct (beqAddr newBlockEntryAddr pdinsertion) eqn:Hbeq.
						* rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
							rewrite Hbeq in *. congruence.
						* rewrite removeDupIdentity. assumption.
							rewrite <- beqAddrFalse in Hbeq. intuition.
				+ intuition.
							exists x0. exists x1. exists x2. exists x3. exists x4. exists x5.
							exists x6. exists x7. exists x8.
							rewrite beqAddrTrue. eexists. unfold s'. intuition. rewrite H3. intuition.
						destruct (beqAddr newBlockEntryAddr pdinsertion) eqn:Hbeq.
						* rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
							rewrite Hbeq in *. congruence.
						* rewrite removeDupIdentity. assumption.
							rewrite <- beqAddrFalse in Hbeq. intuition.
}	intros. simpl.


(*
		2 : { intros. exact H. }
		unfold MAL.writeBlockRFromBlockEntryAddr.
		eapply bindRev.
		{ (** get **)
			eapply weaken. apply get.
			intro s. intros. simpl. instantiate (1:= fun s s0 => s = s0 /\
exists pd : PDTable,
      lookup pdinsertion (memory s) beqAddr = Some (PDT pd) /\
      pdentryNbFreeSlots pdinsertion predCurrentNbFreeSlots s /\
      predCurrentNbFreeSlots > 0 /\
      pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s /\
      bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s /\
      StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots /\
      (exists
         (s0 : state) (pdentry pdentry0 : PDTable) (bentry bentry0 bentry1
                                                    bentry2 : BlockEntry),
         s =
         {|
         currentPartition := currentPartition s0;
         memory := add newBlockEntryAddr
                     (BE
                        (CBlockEntry (read bentry2) (write bentry2)
                           (exec bentry2) true (accessible bentry2)
                           (blockindex bentry2) (blockrange bentry2)))
                     (add newBlockEntryAddr
                        (BE
                           (CBlockEntry (read bentry1) (write bentry1)
                              (exec bentry1) (present bentry1) true
                              (blockindex bentry1) (blockrange bentry1)))
                        (add newBlockEntryAddr
                           (BE
                              (CBlockEntry (read bentry0)
                                 (write bentry0) (exec bentry0)
                                 (present bentry0) (accessible bentry0)
                                 (blockindex bentry0)
                                 (CBlock (startAddr (blockrange bentry0)) endaddr)))
                           (add newBlockEntryAddr
                              (BE
                                 (CBlockEntry (read bentry)
                                    (write bentry) (exec bentry)
                                    (present bentry) (accessible bentry)
                                    (blockindex bentry)
                                    (CBlock startaddr (endAddr (blockrange bentry)))))
                              (add pdinsertion
                                 (PDT
                                    {|
                                    structure := structure pdentry0;
                                    firstfreeslot := firstfreeslot pdentry0;
                                    nbfreeslots := predCurrentNbFreeSlots;
                                    nbprepare := nbprepare pdentry0;
                                    parent := parent pdentry0;
                                    MPU := MPU pdentry0 |})
                                 (add pdinsertion
                                    (PDT
                                       {|
                                       structure := structure pdentry;
                                       firstfreeslot := newFirstFreeSlotAddr;
                                       nbfreeslots := nbfreeslots pdentry;
                                       nbprepare := nbprepare pdentry;
                                       parent := parent pdentry;
                                       MPU := MPU pdentry |})
                                    (memory s0) beqAddr) beqAddr) beqAddr) beqAddr)
                        beqAddr) beqAddr |})). intuition.
	}
		intro s0. intuition.
		destruct (lookup newBlockEntryAddr (memory s0) beqAddr) eqn:Hlookup.
		destruct v eqn:Hv.
		{ (** modify **)
			instantiate (1:= fun _ s => exists pd : PDTable, lookup pdinsertion (memory s) beqAddr = Some (PDT pd) /\
     pdentryNbFreeSlots pdinsertion predCurrentNbFreeSlots s /\ predCurrentNbFreeSlots > 0 /\
     pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s /\
    bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s /\
   StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots

/\ (exists s0, exists pdentry : PDTable, exists pdentry0 : PDTable,
		exists bentry bentry0 bentry1 bentry2 bentry3: BlockEntry,
  s = {|
     currentPartition := currentPartition s0;
     memory := add newBlockEntryAddr
                 (BE
                    (CBlockEntry r (write bentry3) (exec bentry3) (present bentry3)
                       (accessible bentry3) (blockindex bentry3) (blockrange bentry3)))
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry2) (write bentry2) (exec bentry2) true
                       (accessible bentry2) (blockindex bentry2) (blockrange bentry2)))
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry1) (write bentry1) (exec bentry1)
                       (present bentry1) true (blockindex bentry1) (blockrange bentry1)))
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry0) (write bentry0) (exec bentry0)
                       (present bentry0) (accessible bentry0) (blockindex bentry0)
                       (CBlock (startAddr (blockrange bentry0)) endaddr)))
							(add newBlockEntryAddr
                     (BE
                        (CBlockEntry (read bentry) (write bentry)
                           (exec bentry) (present bentry) (accessible bentry)
                           (blockindex bentry)
                           (CBlock startaddr (endAddr (blockrange bentry)))))
								(add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry0;
                    firstfreeslot := firstfreeslot pdentry0;
                    nbfreeslots := predCurrentNbFreeSlots;
                    nbprepare := nbprepare pdentry0;
                    parent := parent pdentry0;
                    MPU := MPU pdentry0 |})
								(add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry |}) (memory s0) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr |}

)).
			eapply weaken. apply modify.
			intros. simpl.  set (s' := {|
      currentPartition :=  _|}). destruct H. destruct H0. exists x.

			split. cbn. admit.
			split. unfold pdentryNbFreeSlots in *. destruct H. destruct H0.
			destruct H0. rewrite H in H0. admit. intuition. intuition.
			admit. admit. destruct H7. destruct H6. destruct H6. destruct H6. destruct H6.
			destruct H6. destruct H6.
			exists x0. exists x1. exists x2. exists x3. exists x4. exists x5. exists x6.
			exists b. subst. intuition.
}
			admit. admit. admit. admit. admit. }
intros. simpl.*)

eapply bindRev.
	{ (**  MAL.writeBlockWFromBlockEntryAddr **)
		eapply weaken. apply WP.writeBlockWFromBlockEntryAddr.
		intros. intuition.
		destruct H. intuition.
		destruct H3. destruct H2. destruct H2. destruct H2. destruct H2. destruct H2.
		destruct H2. destruct H2. destruct H2. destruct H2.
		 exists x9. intuition.
			instantiate (1:= fun _ s => exists pd : PDTable, lookup pdinsertion (memory s) beqAddr = Some (PDT pd) /\
(*isBE newBlockEntryAddr s /\*)
pdentryNbFreeSlots pdinsertion predCurrentNbFreeSlots s (*/\ predCurrentNbFreeSlots > 0*) /\
     (*pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s /\
    bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s /\*)
   StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots

/\ (exists s0, exists pdentry : PDTable, exists pdentry0 pdentry1: PDTable,
		exists bentry bentry0 bentry1 bentry2 bentry3 bentry4 newEntry: BlockEntry,
  s = {|
     currentPartition := currentPartition s0;
     memory := add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry4) w (exec bentry4) (present bentry4)
                       (accessible bentry4) (blockindex bentry4) (blockrange bentry4)))
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry r (write bentry3) (exec bentry3) (present bentry3)
                       (accessible bentry3) (blockindex bentry3) (blockrange bentry3)))
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry2) (write bentry2) (exec bentry2) true
                       (accessible bentry2) (blockindex bentry2) (blockrange bentry2)))
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry1) (write bentry1) (exec bentry1)
                       (present bentry1) true (blockindex bentry1) (blockrange bentry1)))
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry0) (write bentry0) (exec bentry0)
                       (present bentry0) (accessible bentry0) (blockindex bentry0)
                       (CBlock (startAddr (blockrange bentry0)) endaddr)))
							(add newBlockEntryAddr
                     (BE
                        (CBlockEntry (read bentry) (write bentry)
                           (exec bentry) (present bentry) (accessible bentry)
                           (blockindex bentry)
                           (CBlock startaddr (endAddr (blockrange bentry)))))
								(add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry0;
                    firstfreeslot := firstfreeslot pdentry0;
                    nbfreeslots := predCurrentNbFreeSlots;
                    nbprepare := nbprepare pdentry0;
                    parent := parent pdentry0;
                    MPU := MPU pdentry0;
										vidtBlock := vidtBlock pdentry0 |})
								(add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry;
										vidtBlock := vidtBlock pdentry |}) (memory s0) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr |}
/\ lookup newBlockEntryAddr (memory s0) beqAddr = Some (BE bentry)
/\ lookup newBlockEntryAddr (memory s) beqAddr = Some (BE newEntry) /\
newEntry = (CBlockEntry (read bentry4) w (exec bentry4) (present bentry4)
                       (accessible bentry4) (blockindex bentry4) (blockrange bentry4))
/\
bentry4 = (CBlockEntry r (write bentry3) (exec bentry3) (present bentry3)
                       (accessible bentry3) (blockindex bentry3) (blockrange bentry3))
/\
bentry3 = (CBlockEntry (read bentry2) (write bentry2) (exec bentry2) true
                       (accessible bentry2) (blockindex bentry2) (blockrange bentry2))
/\
bentry2 = (CBlockEntry (read bentry1) (write bentry1) (exec bentry1)
                       (present bentry1) true (blockindex bentry1) (blockrange bentry1))
/\
bentry1 = (CBlockEntry (read bentry0) (write bentry0) (exec bentry0)
                       (present bentry0) (accessible bentry0) (blockindex bentry0)
                       (CBlock (startAddr (blockrange bentry0)) endaddr))
/\
bentry0 = (CBlockEntry (read bentry) (write bentry)
                           (exec bentry) (present bentry) (accessible bentry)
                           (blockindex bentry)
                           (CBlock startaddr (endAddr (blockrange bentry))))
/\ lookup pdinsertion (memory s0) beqAddr = Some (PDT pdentry)
/\ lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry1) /\
pdentry1 = {|     structure := structure pdentry0;
                    firstfreeslot := firstfreeslot pdentry0;
                    nbfreeslots := predCurrentNbFreeSlots;
                    nbprepare := nbprepare pdentry0;
                    parent := parent pdentry0;
                    MPU := MPU pdentry0;
										vidtBlock := vidtBlock pdentry0 |} /\
pdentry0 = {|    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry;
										vidtBlock := vidtBlock pdentry|}
(*        /\
(exists olds : state, P olds /\ partitionsIsolation olds /\
       verticalSharing olds /\ consistency olds /\ pdentryFirstFreeSlot pdinsertion newBlockEntryAddr olds /\
    bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr olds)*)
/\ P s0 /\ partitionsIsolation s0 /\
       verticalSharing s0 /\ consistency s0 /\ pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s0 /\
    bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s0 (*/\ isBE newBlockEntryAddr s0*)
/\ isPDT pdinsertion s0 /\ (pdentryNbFreeSlots pdinsertion currnbfreeslots s0 /\ currnbfreeslots > 0)
)). 	intros. simpl.  set (s' := {|
      currentPartition :=  _|}).
			exists x. split.
			- (* DUP *)
				destruct (beqAddr newBlockEntryAddr pdinsertion) eqn:Hbeq.
				+ f_equal. rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
					rewrite Hbeq in *. congruence.
				+ rewrite removeDupIdentity. assumption.
					rewrite <- beqAddrFalse in Hbeq. intuition.
			- split.
				(*+ unfold isBE. cbn. rewrite beqAddrTrue. trivial.*)
				+ intuition.
					unfold pdentryNbFreeSlots in *. cbn.
					destruct (beqAddr newBlockEntryAddr pdinsertion) eqn:Hbeq.
						* rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
							rewrite Hbeq in *. congruence.
						* rewrite removeDupIdentity. assumption.
							rewrite <- beqAddrFalse in Hbeq. intuition.
				+ intuition.
							exists x0. exists x1. exists x2. exists x3. exists x4. exists x5.
							exists x6. exists x7. exists x8. exists x9.
							rewrite beqAddrTrue. eexists. unfold s'. intuition. rewrite H3. intuition.
						destruct (beqAddr newBlockEntryAddr pdinsertion) eqn:Hbeq.
						* rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
							rewrite Hbeq in *. congruence.
						* rewrite removeDupIdentity. assumption.
							rewrite <- beqAddrFalse in Hbeq. intuition.
}	intros. simpl.

(*
		2 : { intros. exact H. }
		unfold MAL.writeBlockWFromBlockEntryAddr.
		eapply bindRev.
		{ (** get **)
			eapply weaken. apply get.
			intro s. intros. simpl. instantiate (1:= fun s s0 => s = s0 /\
exists pd : PDTable,
      lookup pdinsertion (memory s) beqAddr = Some (PDT pd) /\
      pdentryNbFreeSlots pdinsertion predCurrentNbFreeSlots s /\
      predCurrentNbFreeSlots > 0 /\
      pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s /\
      bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s /\
      StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots /\
      (exists
         (s0 : state) (pdentry pdentry0 : PDTable) (bentry bentry0 bentry1 bentry2
                                                    bentry3 : BlockEntry),
         s =
         {|
         currentPartition := currentPartition s0;
         memory := add newBlockEntryAddr
                     (BE
                        (CBlockEntry r (write bentry3) (exec bentry3)
                           (present bentry3) (accessible bentry3)
                           (blockindex bentry3) (blockrange bentry3)))
                     (add newBlockEntryAddr
                        (BE
                           (CBlockEntry (read bentry2) (write bentry2)
                              (exec bentry2) true (accessible bentry2)
                              (blockindex bentry2) (blockrange bentry2)))
                        (add newBlockEntryAddr
                           (BE
                              (CBlockEntry (read bentry1)
                                 (write bentry1) (exec bentry1)
                                 (present bentry1) true (blockindex bentry1)
                                 (blockrange bentry1)))
                           (add newBlockEntryAddr
                              (BE
                                 (CBlockEntry (read bentry0)
                                    (write bentry0) (exec bentry0)
                                    (present bentry0) (accessible bentry0)
                                    (blockindex bentry0)
                                    (CBlock (startAddr (blockrange bentry0)) endaddr)))
                              (add newBlockEntryAddr
                                 (BE
                                    (CBlockEntry (read bentry)
                                       (write bentry) (exec bentry)
                                       (present bentry) (accessible bentry)
                                       (blockindex bentry)
                                       (CBlock startaddr
                                          (endAddr (blockrange bentry)))))
                                 (add pdinsertion
                                    (PDT
                                       {|
                                       structure := structure pdentry0;
                                       firstfreeslot := firstfreeslot pdentry0;
                                       nbfreeslots := predCurrentNbFreeSlots;
                                       nbprepare := nbprepare pdentry0;
                                       parent := parent pdentry0;
                                       MPU := MPU pdentry0 |})
                                    (add pdinsertion
                                       (PDT
                                          {|
                                          structure := structure pdentry;
                                          firstfreeslot := newFirstFreeSlotAddr;
                                          nbfreeslots := nbfreeslots pdentry;
                                          nbprepare := nbprepare pdentry;
                                          parent := parent pdentry;
                                          MPU := MPU pdentry |})
                                       (memory s0) beqAddr) beqAddr) beqAddr) beqAddr)
                           beqAddr) beqAddr) beqAddr |})). intuition.
	}
		intro s0. intuition.
		destruct (lookup newBlockEntryAddr (memory s0) beqAddr) eqn:Hlookup.
		destruct v eqn:Hv.
		{ (** modify **)
			instantiate (1:= fun _ s => exists pd : PDTable, lookup pdinsertion (memory s) beqAddr = Some (PDT pd) /\
     pdentryNbFreeSlots pdinsertion predCurrentNbFreeSlots s /\ predCurrentNbFreeSlots > 0 /\
     pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s /\
    bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s /\
   StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots

/\ (exists s0, exists pdentry : PDTable, exists pdentry0 : PDTable,
		exists bentry bentry0 bentry1 bentry2 bentry3 bentry4: BlockEntry,
  s = {|
     currentPartition := currentPartition s0;
     memory := add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry4) w (exec bentry4) (present bentry4)
                       (accessible bentry4) (blockindex bentry4) (blockrange bentry4)))
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry r (write bentry3) (exec bentry3) (present bentry3)
                       (accessible bentry3) (blockindex bentry3) (blockrange bentry3)))
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry2) (write bentry2) (exec bentry2) true
                       (accessible bentry2) (blockindex bentry2) (blockrange bentry2)))
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry1) (write bentry1) (exec bentry1)
                       (present bentry1) true (blockindex bentry1) (blockrange bentry1)))
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry0) (write bentry0) (exec bentry0)
                       (present bentry0) (accessible bentry0) (blockindex bentry0)
                       (CBlock (startAddr (blockrange bentry0)) endaddr)))
							(add newBlockEntryAddr
                     (BE
                        (CBlockEntry (read bentry) (write bentry)
                           (exec bentry) (present bentry) (accessible bentry)
                           (blockindex bentry)
                           (CBlock startaddr (endAddr (blockrange bentry)))))
								(add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry0;
                    firstfreeslot := firstfreeslot pdentry0;
                    nbfreeslots := predCurrentNbFreeSlots;
                    nbprepare := nbprepare pdentry0;
                    parent := parent pdentry0;
                    MPU := MPU pdentry0 |})
								(add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry |}) (memory s0) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr |}

)).
			eapply weaken. apply modify.
			intros. simpl.  set (s' := {|
      currentPartition :=  _|}). destruct H. destruct H0. exists x.

			split. cbn. admit.
			split. unfold pdentryNbFreeSlots in *. destruct H. destruct H0.
			destruct H0. rewrite H in H0. admit. intuition. intuition.
			admit. admit. destruct H7. destruct H6. destruct H6. destruct H6. destruct H6.
			destruct H6. destruct H6. destruct H6.
			exists x0. exists x1. exists x2. exists x3. exists x4. exists x5. exists x6.
			exists x7.
			exists b. subst. intuition.
}
			admit. admit. admit. admit. admit. }
intros. simpl.*)

eapply bindRev.
	{ (**  MAL.writeBlockXFromBlockEntryAddr **)
		eapply weaken. apply WP.writeBlockXFromBlockEntryAddr.
		intros. intuition.
		destruct H. intuition.
		(*apply isBELookupEq in H.
		destruct H. exists x0. split. assumption.*)
		destruct H3. destruct H2. destruct H2. destruct H2.
		destruct H2. destruct H2. destruct H2. destruct H2. destruct H2. destruct H2.
		destruct H2.
		exists x10. intuition.

			instantiate (1:= fun _ s => exists pd : PDTable, lookup pdinsertion (memory s) beqAddr = Some (PDT pd) /\
(*isBE newBlockEntryAddr s /\*)

pdentryNbFreeSlots pdinsertion predCurrentNbFreeSlots s (*/\ predCurrentNbFreeSlots > 0*) /\
     (*pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s /\
    bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s /\*)
   StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots

/\ (exists s0, ( exists pdentry : PDTable, exists pdentry0 pdentry1: PDTable,
		exists bentry bentry0 bentry1 bentry2 bentry3 bentry4 bentry5 newEntry : BlockEntry,
  s = {|
     currentPartition := currentPartition s0;
     memory := add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry5) (write bentry5) e (present bentry5)
                       (accessible bentry5) (blockindex bentry5) (blockrange bentry5))
											(*newEntry*)
)
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry4) w (exec bentry4) (present bentry4)
                       (accessible bentry4) (blockindex bentry4) (blockrange bentry4)))
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry r (write bentry3) (exec bentry3) (present bentry3)
                       (accessible bentry3) (blockindex bentry3) (blockrange bentry3)))
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry2) (write bentry2) (exec bentry2) true
                       (accessible bentry2) (blockindex bentry2) (blockrange bentry2)))
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry1) (write bentry1) (exec bentry1)
                       (present bentry1) true (blockindex bentry1) (blockrange bentry1)))
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry0) (write bentry0) (exec bentry0)
                       (present bentry0) (accessible bentry0) (blockindex bentry0)
                       (CBlock (startAddr (blockrange bentry0)) endaddr)))
							(add newBlockEntryAddr
                     (BE
                        (CBlockEntry (read bentry) (write bentry)
                           (exec bentry) (present bentry) (accessible bentry)
                           (blockindex bentry)
                           (CBlock startaddr (endAddr (blockrange bentry)))))
								(add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry0;
                    firstfreeslot := firstfreeslot pdentry0;
                    nbfreeslots := predCurrentNbFreeSlots;
                    nbprepare := nbprepare pdentry0;
                    parent := parent pdentry0;
                    MPU := MPU pdentry0;
										vidtBlock := vidtBlock pdentry0 |})
								(add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry;
										vidtBlock := vidtBlock pdentry |}) (memory s0) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr |}
/\ lookup newBlockEntryAddr (memory s0) beqAddr = Some (BE bentry)
/\ lookup newBlockEntryAddr (memory s) beqAddr = Some (BE newEntry) /\
newEntry = (CBlockEntry (read bentry5) (write bentry5) e (present bentry5)
                       (accessible bentry5) (blockindex bentry5) (blockrange bentry5))
/\
bentry5 = (CBlockEntry (read bentry4) w (exec bentry4) (present bentry4)
                       (accessible bentry4) (blockindex bentry4) (blockrange bentry4))
/\
bentry4 = (CBlockEntry r (write bentry3) (exec bentry3) (present bentry3)
                       (accessible bentry3) (blockindex bentry3) (blockrange bentry3))
/\
bentry3 = (CBlockEntry (read bentry2) (write bentry2) (exec bentry2) true
                       (accessible bentry2) (blockindex bentry2) (blockrange bentry2))
/\
bentry2 = (CBlockEntry (read bentry1) (write bentry1) (exec bentry1)
                       (present bentry1) true (blockindex bentry1) (blockrange bentry1))
/\
bentry1 = (CBlockEntry (read bentry0) (write bentry0) (exec bentry0)
                       (present bentry0) (accessible bentry0) (blockindex bentry0)
                       (CBlock (startAddr (blockrange bentry0)) endaddr))
/\
bentry0 = (CBlockEntry (read bentry) (write bentry)
                           (exec bentry) (present bentry) (accessible bentry)
                           (blockindex bentry)
                           (CBlock startaddr (endAddr (blockrange bentry))))
/\ lookup pdinsertion (memory s0) beqAddr = Some (PDT pdentry)
/\ lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry1) /\
pdentry1 = {|     structure := structure pdentry0;
                    firstfreeslot := firstfreeslot pdentry0;
                    nbfreeslots := predCurrentNbFreeSlots;
                    nbprepare := nbprepare pdentry0;
                    parent := parent pdentry0;
                    MPU := MPU pdentry0;
										vidtBlock := vidtBlock pdentry0 |} /\
pdentry0 = {|    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry;
										vidtBlock := vidtBlock pdentry|}
(*/\ (*exists newEntry : BlockEntry,*)
(*lookup newBlockEntryAddr (memory s) beqAddr = (*Some (BE newEntry)*)*)
bentry5 =
(CBlockEntry (read bentry4) w (exec bentry4) (present bentry4)
    (accessible bentry4) (blockindex bentry4) (blockrange bentry4))*)
)          /\
(*(exists olds : state, P olds /\ partitionsIsolation olds /\
       verticalSharing olds /\ consistency olds /\ pdentryFirstFreeSlot pdinsertion newBlockEntryAddr olds /\
    bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr olds)*)
P s0 /\ partitionsIsolation s0 /\
       verticalSharing s0 /\ consistency s0 /\ pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s0 /\
    bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s0 (*/\ isBE newBlockEntryAddr s0*)
/\ isPDT pdinsertion s0 /\ (pdentryNbFreeSlots pdinsertion currnbfreeslots s0 /\ currnbfreeslots > 0)

)). 	intros. simpl.  set (s' := {|
      currentPartition :=  _|}).
			exists x. split.
			- (* DUP *)
				destruct (beqAddr newBlockEntryAddr pdinsertion) eqn:Hbeq.
				+ f_equal. rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
					rewrite Hbeq in *. congruence.
				+ rewrite removeDupIdentity. assumption.
					rewrite <- beqAddrFalse in Hbeq. intuition.
			- split.
				(*+ unfold isBE. cbn. rewrite beqAddrTrue. trivial.*)
				+ intuition.
					unfold pdentryNbFreeSlots in *. cbn.
					destruct (beqAddr newBlockEntryAddr pdinsertion) eqn:Hbeq.
						* rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
							rewrite Hbeq in *. congruence.
						* rewrite removeDupIdentity. assumption.
							rewrite <- beqAddrFalse in Hbeq. intuition.
				+ intuition.
							exists x0. intuition. exists x1. exists x2. exists x3. exists x4. exists x5.
							exists x6. exists x7. exists x8. exists x9. exists x10.
							rewrite beqAddrTrue. eexists.
							intuition. unfold s'. rewrite H3. f_equal.
						destruct (beqAddr newBlockEntryAddr pdinsertion) eqn:Hbeq.
						* rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
							rewrite Hbeq in *. congruence.
						* rewrite removeDupIdentity. assumption.
							rewrite <- beqAddrFalse in Hbeq. intuition.

(*
							cbn in H. repeat rewrite beqAddrTrue in H.
							lia. rewrite f_equal in H.
							contradict H. rewrite H4.
							unfold not. f_equal. contradict H4.
							destruct H4 as [HHH].
							pose (HHHHH := f_equal None H4).

apply (f_equal option) in H4. reflexivity.
About f_equal.
							apply Some in H.
							assert(blockindex x0 = blockindex x5).
							apply (f_equal Some) in H.
							destruct x0. unfold CBlockEntry in H.
							destruct (lt_dec (ADT.blockindex x9) kernelStructureEntriesNb) eqn:Htest ; try(exfalso ; congruence).
							simpl in H.

							Search (Some ?x = Some ?y). destruct Some eqn:HSome in H .
							destruct v eqn:Hvv in H.

rewrite f_equal in H.
							(*unfold s'. subst. f_equal.*)*)
}	intros. simpl.


(*
		2 : { intros. exact H. }
		unfold MAL.writeBlockXFromBlockEntryAddr.
		eapply bindRev.
		{ (** get **)
			eapply weaken. apply get.
			intro s. intros. simpl. instantiate (1:= fun s s0 => s = s0 /\
exists pd : PDTable,
      lookup pdinsertion (memory s) beqAddr = Some (PDT pd) /\
      pdentryNbFreeSlots pdinsertion predCurrentNbFreeSlots s /\
      predCurrentNbFreeSlots > 0 /\
      pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s /\
      bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s /\
      StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots /\
      (exists
         (s0 : state) (pdentry pdentry0 : PDTable) (bentry bentry0 bentry1 bentry2
                                                    bentry3 bentry4 : BlockEntry),
         s =
         {|
         currentPartition := currentPartition s0;
         memory := add newBlockEntryAddr
                     (BE
                        (CBlockEntry (read bentry4) w (exec bentry4)
                           (present bentry4) (accessible bentry4)
                           (blockindex bentry4) (blockrange bentry4)))
                     (add newBlockEntryAddr
                        (BE
                           (CBlockEntry r (write bentry3)
                              (exec bentry3) (present bentry3)
                              (accessible bentry3) (blockindex bentry3)
                              (blockrange bentry3)))
                        (add newBlockEntryAddr
                           (BE
                              (CBlockEntry (read bentry2)
                                 (write bentry2) (exec bentry2) true
                                 (accessible bentry2) (blockindex bentry2)
                                 (blockrange bentry2)))
                           (add newBlockEntryAddr
                              (BE
                                 (CBlockEntry (read bentry1)
                                    (write bentry1) (exec bentry1)
                                    (present bentry1) true
                                    (blockindex bentry1)
                                    (blockrange bentry1)))
                              (add newBlockEntryAddr
                                 (BE
                                    (CBlockEntry (read bentry0)
                                       (write bentry0) (exec bentry0)
                                       (present bentry0)
                                       (accessible bentry0)
                                       (blockindex bentry0)
                                       (CBlock (startAddr (blockrange bentry0))
                                          endaddr)))
                                 (add newBlockEntryAddr
                                    (BE
                                       (CBlockEntry (read bentry)
                                          (write bentry)
                                          (exec bentry) (present bentry)
                                          (accessible bentry)
                                          (blockindex bentry)
                                          (CBlock startaddr
                                             (endAddr (blockrange bentry)))))
                                    (add pdinsertion
                                       (PDT
                                          {|
                                          structure := structure pdentry0;
                                          firstfreeslot := firstfreeslot pdentry0;
                                          nbfreeslots := predCurrentNbFreeSlots;
                                          nbprepare := nbprepare pdentry0;
                                          parent := parent pdentry0;
                                          MPU := MPU pdentry0 |})
                                       (add pdinsertion
                                          (PDT
                                             {|
                                             structure := structure pdentry;
                                             firstfreeslot := newFirstFreeSlotAddr;
                                             nbfreeslots := nbfreeslots pdentry;
                                             nbprepare := nbprepare pdentry;
                                             parent := parent pdentry;
                                             MPU := MPU pdentry |})
                                          (memory s0) beqAddr) beqAddr) beqAddr)
                                 beqAddr) beqAddr) beqAddr) beqAddr) beqAddr |})). intuition.
	}
		intro s0. intuition.
		destruct (lookup newBlockEntryAddr (memory s0) beqAddr) eqn:Hlookup.
		destruct v eqn:Hv.
		{ (** modify **)
			instantiate (1:= fun _ s => exists pd : PDTable, lookup pdinsertion (memory s) beqAddr = Some (PDT pd) /\
     pdentryNbFreeSlots pdinsertion predCurrentNbFreeSlots s /\ predCurrentNbFreeSlots > 0 /\
     pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s /\
    bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s /\
   StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots

/\ (exists s0, exists pdentry : PDTable, exists pdentry0 : PDTable,
		exists bentry bentry0 bentry1 bentry2 bentry3 bentry4 bentry5: BlockEntry,
  s = {|
     currentPartition := currentPartition s0;
     memory := add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry5) (write bentry5) e (present bentry5)
                       (accessible bentry5) (blockindex bentry5) (blockrange bentry5)))
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry4) w (exec bentry4) (present bentry4)
                       (accessible bentry4) (blockindex bentry4) (blockrange bentry4)))
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry r (write bentry3) (exec bentry3) (present bentry3)
                       (accessible bentry3) (blockindex bentry3) (blockrange bentry3)))
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry2) (write bentry2) (exec bentry2) true
                       (accessible bentry2) (blockindex bentry2) (blockrange bentry2)))
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry1) (write bentry1) (exec bentry1)
                       (present bentry1) true (blockindex bentry1) (blockrange bentry1)))
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry0) (write bentry0) (exec bentry0)
                       (present bentry0) (accessible bentry0) (blockindex bentry0)
                       (CBlock (startAddr (blockrange bentry0)) endaddr)))
							(add newBlockEntryAddr
                     (BE
                        (CBlockEntry (read bentry) (write bentry)
                           (exec bentry) (present bentry) (accessible bentry)
                           (blockindex bentry)
                           (CBlock startaddr (endAddr (blockrange bentry)))))
								(add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry0;
                    firstfreeslot := firstfreeslot pdentry0;
                    nbfreeslots := predCurrentNbFreeSlots;
                    nbprepare := nbprepare pdentry0;
                    parent := parent pdentry0;
                    MPU := MPU pdentry0 |})
								(add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry |}) (memory s0) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr |}

)).
			eapply weaken. apply modify.
			intros. simpl.  set (s' := {|
      currentPartition :=  _|}). destruct H. destruct H0. exists x.

			split. cbn. admit.
			split. unfold pdentryNbFreeSlots in *. destruct H. destruct H0.
			destruct H0. rewrite H in H0. admit. intuition. intuition.
			admit. admit. destruct H7. destruct H6. destruct H6. destruct H6. destruct H6.
			destruct H6. destruct H6. destruct H6. destruct H6.
			exists x0. exists x1. exists x2. exists x3. exists x4. exists x5. exists x6.
			exists x7. exists x8.
			exists b. subst. intuition.
}
			admit. admit. admit. admit. admit. }
intros. simpl.*)

eapply bindRev.
	{ (**  MAL.writeSCOriginFromBlockEntryAddr **)
		eapply weaken. apply writeSCOriginFromBlockEntryAddr.
		intros. simpl. destruct H. destruct H.
		assert(HSCE : wellFormedShadowCutIfBlockEntry s).
		{ unfold wellFormedShadowCutIfBlockEntry. intros. simpl.
			exists (CPaddr (pa + scoffset)). intuition.

			intuition. destruct H4 as [s0].
		destruct H3. destruct H3. destruct H3. destruct H3. destruct H3. destruct H3.
		destruct H3. destruct H3. destruct H3. destruct H3. destruct H3. destruct H3.
			assert(HSCEEq : isSCE (CPaddr (pa + scoffset)) s = isSCE (CPaddr (pa + scoffset)) s0).
			{
				intuition. rewrite H5. unfold isSCE. cbn.
				destruct (beqAddr newBlockEntryAddr (CPaddr (pa + scoffset))) eqn:Hbeq.
			rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
			rewrite <- Hbeq.
			assert (HBE : lookup newBlockEntryAddr (memory s0) beqAddr = Some (BE x3)) by intuition.
			rewrite HBE.
			destruct (lookup newBlockEntryAddr (memory s0) beqAddr) eqn:Hlookup ; try (exfalso ; congruence).
			destruct v eqn:Hv ; try congruence. intuition.

			repeat rewrite beqAddrTrue.
			destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hbeqpdblock.
			rewrite <- DependentTypeLemmas.beqAddrTrue in *.
			unfold isPDT in *. unfold isBE in *. rewrite <- beqAddrFalse in *.
			repeat rewrite removeDupIdentity ; intuition.
			rewrite Hbeqpdblock in *.
			destruct (lookup newBlockEntryAddr (memory s0) beqAddr) eqn:Hlookup ; try congruence.
			rewrite Hbeqpdblock in *.
			destruct (lookup newBlockEntryAddr (memory s0) beqAddr) eqn:Hlookup ; try congruence.
			rewrite <- beqAddrFalse in *.
			repeat rewrite removeDupIdentity ; intuition.
			cbn.

			destruct (beqAddr pdinsertion (CPaddr (pa + scoffset))) eqn:Hbeqpdpa ; try congruence.
			rewrite <- DependentTypeLemmas.beqAddrTrue in *.
			rewrite <- Hbeqpdpa. assert(HPDT : isPDT pdinsertion s0) by intuition.
			apply isPDTLookupEq in HPDT. destruct HPDT as [Hpdentry HPDT].
			rewrite HPDT. trivial.

				rewrite <- beqAddrFalse in *.
				repeat rewrite removeDupIdentity ; intuition.
			}
			rewrite HSCEEq.
			assert(Hcons : wellFormedShadowCutIfBlockEntry s0) by
			(unfold consistency in * ; intuition).
			unfold wellFormedShadowCutIfBlockEntry in Hcons.
			assert(HBEEq : isBE pa s = isBE pa s0).
			{
				intuition. rewrite H5. unfold isBE. cbn. repeat rewrite beqAddrTrue.

				destruct (beqAddr newBlockEntryAddr pa) eqn:Hbeq.
				rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
				rewrite <- Hbeq.
				assert (HBE : lookup newBlockEntryAddr (memory s0) beqAddr = Some (BE x3)) by intuition.
			rewrite HBE. trivial.

				rewrite <- beqAddrFalse in *.

				destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hbeqpdblock.
				rewrite <- DependentTypeLemmas.beqAddrTrue in *.
				unfold isPDT in *. unfold isBE in *. (* subst.*)
				destruct (lookup pa (memory s) beqAddr) eqn:Hpa ; try(exfalso ; congruence).
				repeat rewrite removeDupIdentity ; intuition.

				cbn.
				(*rewrite Hbeqpdblock.
				repeat rewrite removeDupIdentity ; intuition.
				cbn.*)

				destruct (beqAddr pdinsertion pa) eqn:Hbeqpdpa.
				rewrite <- DependentTypeLemmas.beqAddrTrue in *.
				rewrite <- Hbeqpdpa.
				assert(HPDT : isPDT pdinsertion s0) by intuition.
				apply isPDTLookupEq in HPDT. destruct HPDT as [Hpdentry HPDT].
				rewrite HPDT. trivial.


				rewrite <- beqAddrFalse in *.

				repeat rewrite removeDupIdentity ; intuition.
			}
			rewrite HBEEq in *.
			specialize (Hcons pa H1).
			destruct Hcons. intuition.
			rewrite H9 in *. intuition.
}
intuition.
- 	destruct H3 as [s0].
		destruct H2. destruct H2. destruct H2. destruct H2. destruct H2. destruct H2.
		destruct H2. destruct H2. destruct H2. destruct H2. destruct H2. destruct H2.
		apply isBELookupEq.
		assert(Hnewblocks : lookup newBlockEntryAddr (memory s) beqAddr = Some (BE x10)) by intuition.
		exists x10. intuition.
	- unfold KernelStructureStartFromBlockEntryAddrIsKS. intros. simpl.
		destruct H3 as [s0].
		destruct H3. destruct H3. destruct H3. destruct H3. destruct H3. destruct H3.
		destruct H3. destruct H3. destruct H3. destruct H3. destruct H3. destruct H3.
		intuition.

		assert(Hblockindex1 : blockindex x10 = blockindex x8).
		{ subst x10. subst x9.
		 unfold CBlockEntry.
		destruct(lt_dec (blockindex x8) kernelStructureEntriesNb) eqn:Hdec ; try(exfalso ; congruence).
		intuition. simpl. intuition.
		destruct(lt_dec (blockindex x8) kernelStructureEntriesNb) eqn:Hdec' ; try(exfalso ; congruence).
		cbn. reflexivity. destruct blockentry_d. destruct x8.
		intuition.
		}
		assert(Hblockindex2 : blockindex x8 = blockindex x6).
		{ subst x8. subst x7.
		 unfold CBlockEntry.
		destruct(lt_dec (blockindex x6) kernelStructureEntriesNb) eqn:Hdec ; try(exfalso ; congruence).
		intuition. simpl. intuition.
		destruct(lt_dec (blockindex x6) kernelStructureEntriesNb) eqn:Hdec' ; try(exfalso ; congruence).
		cbn. reflexivity. destruct blockentry_d. destruct x6.
		intuition.
		}
		assert(Hblockindex3 : blockindex x6 = blockindex x4).
		{ subst x6. subst x5.
		 unfold CBlockEntry.
		destruct(lt_dec (blockindex x4) kernelStructureEntriesNb) eqn:Hdec ; try(exfalso ; congruence).
		intuition. simpl. intuition.
		destruct(lt_dec (blockindex x4) kernelStructureEntriesNb) eqn:Hdec' ; try(exfalso ; congruence).
		cbn. reflexivity. destruct blockentry_d. destruct x4.
		intuition.
		}
		assert(Hblockindex4 : blockindex x4 = blockindex x3).
		{ subst x4.
		 unfold CBlockEntry.
		destruct(lt_dec (blockindex x3) kernelStructureEntriesNb) eqn:Hdec ; try(exfalso ; congruence).
		intuition. simpl. intuition.
		destruct(lt_dec (blockindex x3) kernelStructureEntriesNb) eqn:Hdec' ; try(exfalso ; congruence).
		cbn. destruct blockentry_d. destruct x3.
		intuition.
		}
		assert(isKS (CPaddr (blockentryaddr - blockidx)) s = isKS (CPaddr (blockentryaddr - blockidx)) s0).
		{
			intuition. rewrite H6. unfold isKS. cbn. rewrite beqAddrTrue.

			destruct (beqAddr newBlockEntryAddr (CPaddr (blockentryaddr - blockidx))) eqn:Hbeq.
			rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
			rewrite <- Hbeq.
			assert (HBE :  lookup newBlockEntryAddr (memory s0) beqAddr = Some (BE x3)) by intuition.
			rewrite HBE ; trivial.
			(*destruct (lookup newBlockEntryAddr (memory s0) beqAddr) eqn:Hlookup ; try (exfalso ; congruence).
			destruct v eqn:Hv ; try congruence ; intuition.*)
			f_equal.
			assert(Hblockindex : blockindex x9 = blockindex x8).
			{ subst x9.
			 	unfold CBlockEntry.
				destruct(lt_dec (blockindex x8) kernelStructureEntriesNb) eqn:Hdec ; try(exfalso ; congruence).
				intuition. simpl. intuition.
				destruct(lt_dec (blockindex x8) kernelStructureEntriesNb) eqn:Hdec' ; try(exfalso ; congruence).
				cbn. destruct blockentry_d. destruct x8.
				intuition.
			}
			rewrite <- Hblockindex4. rewrite <- Hblockindex3. rewrite <- Hblockindex2.
			rewrite <- Hblockindex. intuition.
			unfold CBlockEntry. destruct (lt_dec (blockindex x9) kernelStructureEntriesNb) eqn:Hdec ; try(exfalso ; congruence).
			intuition.
			destruct blockentry_d. destruct x9.
			intuition.

			destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hbeqpdblock.
			rewrite <- DependentTypeLemmas.beqAddrTrue in *.
			unfold isPDT in *. unfold isKS in *. rewrite <- beqAddrFalse in *.
			repeat rewrite removeDupIdentity ; intuition.
			rewrite Hbeqpdblock in *.
			destruct (lookup newBlockEntryAddr (memory s0) beqAddr) eqn:Hlookup ; try congruence.
			cbn. rewrite Hbeqpdblock in *.
			destruct (lookup newBlockEntryAddr (memory s0) beqAddr) eqn:Hlookup ; try congruence.
			rewrite <- beqAddrFalse in *.
			repeat rewrite removeDupIdentity ; intuition.
			cbn.

			destruct (beqAddr pdinsertion (CPaddr (blockentryaddr - blockidx))) eqn:Hbeqpdpa ; try congruence.
			rewrite <- DependentTypeLemmas.beqAddrTrue in *.
			rewrite <- Hbeqpdpa.
			assert(HPDTs0 : isPDT pdinsertion s0) by intuition.
			apply isPDTLookupEq in HPDTs0. destruct HPDTs0 as [pds0 HPDTs0].
			rewrite HPDTs0. trivial.
			rewrite beqAddrTrue.
			rewrite <- beqAddrFalse in *.
			repeat rewrite removeDupIdentity ; intuition.
		}
			rewrite H26.
			assert(Hcons0 : KernelStructureStartFromBlockEntryAddrIsKS s0)
				by (unfold consistency in *; intuition).
			unfold KernelStructureStartFromBlockEntryAddrIsKS in *.

			(*rewrite H6.*)
			(*assert(HHcons : forall blockentryaddr : paddr,
isBE blockentryaddr s0 ->
exists entry : BlockEntry, isBE (CPaddr (blockentryaddr - entry.(blockindex))) s0).
			admit.*)

			(*rewrite H6.*)





		(*	assert(Hcons2 : forall blockentryaddr : paddr, forall entry : BlockEntry,
lookup blockentryaddr (memory s0) beqAddr = Some (BE entry)->
exists entry' : BlockEntry,
lookup (CPaddr (blockentryaddr - entry.(blockindex))) (memory s0) beqAddr = Some (BE entry')).
admit.

			assert (exists entry' : BlockEntry,
lookup (CPaddr (blockentryaddr - entry.(blockindex))) (memory s) beqAddr = Some (BE entry')).
			(*eexists.*)
{*)

			(*destruct (beqAddr newBlockEntryAddr (CPaddr (blockentryaddr - blockindex entry)) ) eqn:Hbeq ; try intuition.*)
			(*+ (* newBlockEntryAddr = (CPaddr (blockentryaddr - blockindex x9)) *)
				rewrite <- DependentTypeLemmas.beqAddrTrue in *.
				rewrite <- Hbeq in *. assumption.*)
			(* pdinsertion <> newBlockEntryAddr *)
				destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hbeqpdblock ; try (exfalso ; congruence).
				++ (* pdinsertion = newBlockEntryAddr *)
						rewrite <- DependentTypeLemmas.beqAddrTrue in *.
						(*assert(HBE : isBE newBlockEntryAddr s0) by intuition.
						apply isBELookupEq in HBE. destruct HBE as [HBEx HBE'].*)
						assert(HBE : lookup newBlockEntryAddr (memory s0) beqAddr = Some (BE x3)) by intuition.
						unfold isPDT in *. rewrite Hbeqpdblock in *. rewrite HBE in *. intuition.
				++ (* pdinsertion <> newBlockEntryAddr *)
						destruct (beqAddr pdinsertion blockentryaddr) eqn:Hbeqpdaddr ; try (exfalso ; congruence).
					+++ (* pdinsertion = blockentryaddr *)
							rewrite <- DependentTypeLemmas.beqAddrTrue in *.
							rewrite <- Hbeqpdaddr in *.
							unfold isPDT in *.
							unfold isBE in *.
							destruct(lookup pdinsertion (memory s) beqAddr) ; try(exfalso ; congruence).
							destruct v ; try(exfalso ; congruence).
					+++ (* pdinsertion <> blockentryaddr *)
							destruct (beqAddr newBlockEntryAddr blockentryaddr) eqn:Hbeqnewblock ; try (exfalso ; congruence).
							++++ (* newBlockEntryAddr = blockentryaddr) *)
									rewrite <- DependentTypeLemmas.beqAddrTrue in *.
									rewrite <- Hbeqnewblock in *. intuition.
									assert(HBEs0 : lookup newBlockEntryAddr (memory s0) beqAddr = Some (BE x3)) by intuition.
									assert(HisBEs0 : isBE newBlockEntryAddr s0) by (unfold isBE ; rewrite HBEs0 ; trivial).
									assert (HbentryIdxEq : bentryBlockIndex newBlockEntryAddr blockidx s = bentryBlockIndex newBlockEntryAddr blockidx s0).
									{ unfold bentryBlockIndex. rewrite HBEs0. intuition. rewrite H8.
										f_equal. rewrite <- Hblockindex4. rewrite <- Hblockindex3.
										rewrite <- Hblockindex2. rewrite <- Hblockindex1. reflexivity.
									}
									assert(Hbentry : bentryBlockIndex newBlockEntryAddr blockidx s) by intuition.
									rewrite HbentryIdxEq in *.
									specialize (Hcons0 newBlockEntryAddr blockidx HisBEs0 Hbentry).
									intuition.
							++++ (* newBlockEntryAddr <> blockentryaddr) *)
									assert(HBEEq : isBE blockentryaddr s = isBE blockentryaddr s0).
									{ unfold isBE.
										rewrite H6.
										cbn.
										rewrite beqAddrTrue.
										rewrite Hbeqnewblock.
										cbn.
										rewrite <- beqAddrFalse in *.
										repeat rewrite removeDupIdentity ; intuition.
										destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hf ; try(exfalso ; congruence).
										rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
										cbn.
										destruct (beqAddr pdinsertion blockentryaddr) eqn:Hff ; try(exfalso ; congruence).
										rewrite <- DependentTypeLemmas.beqAddrTrue in Hff. congruence.
										cbn.
										rewrite beqAddrTrue.
										rewrite <- beqAddrFalse in *.
										repeat rewrite removeDupIdentity ; intuition.
									}
									assert(HBlocks0 : isBE blockentryaddr s0) by (rewrite HBEEq in * ; intuition).
									assert(HLookupEq: lookup blockentryaddr (memory s) beqAddr = lookup blockentryaddr (memory s0) beqAddr).
									{
										rewrite H6.
										cbn.
										rewrite beqAddrTrue.
										rewrite Hbeqnewblock.
										cbn.
										rewrite <- beqAddrFalse in *.
										repeat rewrite removeDupIdentity ; intuition.
										destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hf ; try(exfalso ; congruence).
										rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
										cbn.
										destruct (beqAddr pdinsertion blockentryaddr) eqn:Hff ; try(exfalso ; congruence).
										rewrite <- DependentTypeLemmas.beqAddrTrue in Hff. congruence.
										cbn.
										rewrite beqAddrTrue.
										rewrite <- beqAddrFalse in *.
										repeat rewrite removeDupIdentity ; intuition.
									}
									assert(HBentryIndexEq : bentryBlockIndex blockentryaddr blockidx s = bentryBlockIndex blockentryaddr blockidx s0).
									{
										apply isBELookupEq in H2. destruct H2 as [blockentrys HBlockLookups].
										apply isBELookupEq in HBlocks0. destruct HBlocks0 as [blockentrys0 HBlockLookups0].
										unfold bentryBlockIndex. rewrite HBlockLookups. rewrite HBlockLookups0.
										rewrite HLookupEq in *.
										rewrite HBlockLookups in HBlockLookups0.
										injection HBlockLookups0 as HblockentryEq.
										f_equal.
										rewrite HblockentryEq. reflexivity.
									}
									assert(HBentryIndex : bentryBlockIndex blockentryaddr blockidx s0)
										by (rewrite HBentryIndexEq in * ; intuition).
									specialize(Hcons0 blockentryaddr blockidx HBlocks0 HBentryIndex).
									intuition.
- (* we know newBlockEntryAddr is BE and that the ShadoCut is well formed, so we
			know SCE exists *)
		unfold wellFormedShadowCutIfBlockEntry in *.
		destruct H3 as [s0].
		destruct H2. destruct H2. destruct H2. destruct H2. destruct H2. destruct H2.
		destruct H2. destruct H2. destruct H2. destruct H2. destruct H2. destruct H2.
		intuition.
		assert(HBE : lookup newBlockEntryAddr (memory s) beqAddr = Some (BE x10)) by intuition.
		specialize (HSCE newBlockEntryAddr).
		unfold isBE in HSCE. rewrite HBE in *. destruct HSCE as [scentryaddr (HSCE& Hsceeq)] ; trivial.
		intuition. apply isSCELookupEq in HSCE. destruct HSCE as [Hscentry HSCE].
		rewrite Hsceeq in *.
		exists Hscentry. intuition.




		(*2 : { intros. exact H. }
		unfold MAL.writeSCOriginFromBlockEntryAddr.
		eapply bindRev.
		{ (** MAL.getSCEntryAddrFromBlockEntryAddr **)
			eapply weaken. apply getSCEntryAddrFromBlockEntryAddr.
			intros. split. apply H.
			destruct H. intuition.
			destruct H4. destruct H3. destruct H3. destruct H3. destruct H3. destruct H3.
			destruct H3. destruct H3. destruct H3. destruct H3. intuition.
			- unfold wellFormedShadowCutIfBlockEntry.
				intros. eexists.
				split. unfold isSCE.
				unfold consistency in *. unfold wellFormedShadowCutIfBlockEntry in *. intuition.
				specialize (H16 pa). simpl in *.
				apply isBELookupEq in H9. destruct H9.
				destruct (lookup pa (memory s) beqAddr)  eqn:Hlookup in * ; try(congruence).
				destruct v eqn:Hv ; try(congruence).
				rewrite H4 in Hlookup. cbn in *.
				destruct (beqAddr newBlockEntryAddr pa) eqn:Hbeq.
				cbn in *. instantiate(1:= CPaddr (pa + scoffset)).
				cbn.
				destruct (lookup (CPaddr (pa + scoffset)) (memory s) beqAddr) eqn:Hbeq2.
				destruct v0 eqn:hv2 ; try congruence.
				destruct H16.
				unfold isBE. cbn. apply beqAddrTrue in Hbeq.
				cbn in *. rewrite H4 in Hbeq2. cbn in *.

specialize (H16 H9). rewrite H4. cbn.
				+ intuition. cbn. case_eq (beqAddr).
					* destruct (beqAddr) eqn:Hbeq.
					rewrite beqAddrTrue in Hbeq.

			admit.
			- admit.
			- apply isBELookupEq in H. destruct H. exists x0. assumption.*)
(*		}
		intro SCEAddr.
	{ (**  MAL.writeSCOriginFromBlockEntryAddr2 **)
		eapply weaken. apply WP.writeSCOriginFromBlockEntryAddr2.
		intros. intuition.
		destruct H1 as [scentry]. exists scentry. intuition.*)
instantiate (1:= fun _ s => exists pd : PDTable, lookup pdinsertion (memory s) beqAddr = Some (PDT pd) /\
(*isBE newBlockEntryAddr s /\*)
pdentryNbFreeSlots pdinsertion predCurrentNbFreeSlots s (*/\ predCurrentNbFreeSlots > 0*) /\
     (*pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s /\
    bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s /\*)
   StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots

/\ (exists s0, exists pdentry : PDTable, exists pdentry0 pdentry1: PDTable,
		exists bentry bentry0 bentry1 bentry2 bentry3 bentry4 bentry5 bentry6: BlockEntry,
		exists sceaddr, exists scentry : SCEntry,
  s = {|
     currentPartition := currentPartition s0;
     memory := add sceaddr
									(SCE {| origin := origin; next := next scentry |})
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry5) (write bentry5) e (present bentry5)
                       (accessible bentry5) (blockindex bentry5) (blockrange bentry5)))
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry4) w (exec bentry4) (present bentry4)
                       (accessible bentry4) (blockindex bentry4) (blockrange bentry4)))
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry r (write bentry3) (exec bentry3) (present bentry3)
                       (accessible bentry3) (blockindex bentry3) (blockrange bentry3)))
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry2) (write bentry2) (exec bentry2) true
                       (accessible bentry2) (blockindex bentry2) (blockrange bentry2)))
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry1) (write bentry1) (exec bentry1)
                       (present bentry1) true (blockindex bentry1) (blockrange bentry1)))
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry0) (write bentry0) (exec bentry0)
                       (present bentry0) (accessible bentry0) (blockindex bentry0)
                       (CBlock (startAddr (blockrange bentry0)) endaddr)))
							(add newBlockEntryAddr
                     (BE
                        (CBlockEntry (read bentry) (write bentry)
                           (exec bentry) (present bentry) (accessible bentry)
                           (blockindex bentry)
                           (CBlock startaddr (endAddr (blockrange bentry)))))
								(add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry0;
                    firstfreeslot := firstfreeslot pdentry0;
                    nbfreeslots := predCurrentNbFreeSlots;
                    nbprepare := nbprepare pdentry0;
                    parent := parent pdentry0;
                    MPU := MPU pdentry0;
										vidtBlock := vidtBlock pdentry0 |})
								(add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry;
										vidtBlock := vidtBlock pdentry |}) (memory s0) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr |}

/\ lookup newBlockEntryAddr (memory s0) beqAddr = Some (BE bentry)
/\ lookup newBlockEntryAddr (memory s) beqAddr = Some (BE bentry6) /\
bentry6 = (CBlockEntry (read bentry5) (write bentry5) e (present bentry5)
                       (accessible bentry5) (blockindex bentry5) (blockrange bentry5))
/\
bentry5 = (CBlockEntry (read bentry4) w (exec bentry4) (present bentry4)
                       (accessible bentry4) (blockindex bentry4) (blockrange bentry4))
/\
bentry4 = (CBlockEntry r (write bentry3) (exec bentry3) (present bentry3)
                       (accessible bentry3) (blockindex bentry3) (blockrange bentry3))
/\
bentry3 = (CBlockEntry (read bentry2) (write bentry2) (exec bentry2) true
                       (accessible bentry2) (blockindex bentry2) (blockrange bentry2))
/\
bentry2 = (CBlockEntry (read bentry1) (write bentry1) (exec bentry1)
                       (present bentry1) true (blockindex bentry1) (blockrange bentry1))
/\
bentry1 = (CBlockEntry (read bentry0) (write bentry0) (exec bentry0)
                       (present bentry0) (accessible bentry0) (blockindex bentry0)
                       (CBlock (startAddr (blockrange bentry0)) endaddr))
/\
bentry0 = (CBlockEntry (read bentry) (write bentry)
                           (exec bentry) (present bentry) (accessible bentry)
                           (blockindex bentry)
                           (CBlock startaddr (endAddr (blockrange bentry))))
/\ sceaddr = (CPaddr (newBlockEntryAddr + scoffset))
/\ lookup pdinsertion (memory s0) beqAddr = Some (PDT pdentry)
/\ lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry1) /\
pdentry1 = {|     structure := structure pdentry0;
                    firstfreeslot := firstfreeslot pdentry0;
                    nbfreeslots := predCurrentNbFreeSlots;
                    nbprepare := nbprepare pdentry0;
                    parent := parent pdentry0;
                    MPU := MPU pdentry0;
										vidtBlock := vidtBlock pdentry0 |} /\
pdentry0 = {|    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry;
										vidtBlock := vidtBlock pdentry|}
(* (exists olds : state, P olds /\ partitionsIsolation olds /\
       verticalSharing olds /\ consistency olds /\ pdentryFirstFreeSlot pdinsertion newBlockEntryAddr olds /\
    bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr olds)*)
/\ P s0 /\ partitionsIsolation s0 /\
       verticalSharing s0 /\ consistency s0 /\ pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s0 /\
    bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s0 (*/\ isBE newBlockEntryAddr s0*)
/\ isPDT pdinsertion s0 /\ (pdentryNbFreeSlots pdinsertion currnbfreeslots s0 /\ currnbfreeslots > 0)
)). 	intros. simpl.  set (s' := {|
      currentPartition :=  _|}).
			exists x. split.
			+ destruct (beqAddr (CPaddr (newBlockEntryAddr + scoffset)) pdinsertion) eqn:Hbeqpdx10.
				rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeqpdx10.
				unfold isPDT in *.
				rewrite Hbeqpdx10 in *. rewrite H18 in *. exfalso. congruence.
				rewrite removeDupIdentity. intuition.
				rewrite beqAddrFalse in *. intuition.
				rewrite beqAddrSym. congruence.
			(*+ split.
				+ unfold isBE. intuition. rewrite isBELookupEq in *. destruct H.
					cbn. destruct (beqAddr x10 newBlockEntryAddr) eqn:Hbeq.
					* rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
						destruct H10. rewrite Hbeq in *. congruence.
					* rewrite removeDupIdentity. rewrite H. trivial.
						rewrite <- beqAddrFalse in Hbeq. intuition.*)
				+ unfold pdentryNbFreeSlots in *. cbn. rewrite <- Hsceeq in *.
					destruct (beqAddr scentryaddr pdinsertion) eqn:Hbeq.
					* (* scentryaddr = pdinsertion *)
						rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
						assert(HPDT : isPDT pdinsertion s0) by intuition.
						apply isPDTLookupEq in HPDT. destruct HPDT.
						rewrite Hbeq in *. congruence.
					* (* scentryaddr <> pdinsertion *)
						intuition.
						++ rewrite removeDupIdentity. assumption.
								rewrite <- beqAddrFalse in Hbeq. intuition.
						++ 	exists s0. exists x0. exists x1. exists x2. exists x3. exists x4. exists x5. exists x6.
					exists x7. exists x8. exists x9. exists x10. exists scentryaddr. exists Hscentry.
					intuition.
					unfold s'. rewrite H4. rewrite <- Hsceeq in *.
					+++ intuition.
					+++ destruct (beqAddr scentryaddr newBlockEntryAddr) eqn:HnewSCEq ; try(exfalso ; congruence).
					** rewrite <- DependentTypeLemmas.beqAddrTrue in HnewSCEq.
						rewrite HnewSCEq in *. congruence.
					** rewrite <- beqAddrFalse in HnewSCEq.
						rewrite removeDupIdentity ; intuition.
					+++	rewrite removeDupIdentity ; intuition.
							subst pdinsertion. congruence.

			(*- (* DUP *) intuition.
				destruct (beqAddr SCEAddr pdinsertion) eqn:Hbeq.
				+ f_equal. rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
					subst. congruence.
				+ rewrite removeDupIdentity. assumption.
					rewrite <- beqAddrFalse in Hbeq. intuition.
			- split.
				+ unfold isBE. intuition. rewrite isBELookupEq in *. destruct H.
					cbn. destruct (beqAddr SCEAddr newBlockEntryAddr) eqn:Hbeq.
					* rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
					subst. congruence.
					* rewrite removeDupIdentity. rewrite H. trivial.
						rewrite <- beqAddrFalse in Hbeq. intuition.
				+ intuition.
					unfold pdentryNbFreeSlots in *. cbn.
					destruct (beqAddr SCEAddr pdinsertion) eqn:Hbeq.
						* rewrite <- DependentTypeLemmas.beqAddrTrue in Hbeq.
							subst. congruence.
						* rewrite removeDupIdentity. assumption.
							rewrite <- beqAddrFalse in Hbeq. intuition.
						* destruct H6. destruct H5. destruct H5. destruct H5. destruct H5.
							destruct H5. destruct H5. destruct H5. destruct H5. destruct H5.
							exists x0. exists x1. exists x2. exists x3. exists x4. exists x5. exists x6.
							exists x7. exists x8. exists x9. exists SCEAddr. exists scentry.
							subst. intuition.
							unfold s'. subst. f_equal.
	}*)
}	intros. simpl.

(*

				unfold MAL.writeSCOriginFromBlockEntryAddr2.
			eapply bindRev.
		eapply weaken. apply get.
		intro s. intros. simpl. instantiate (1:= fun s s0 => s = s0 /\
(exists pd : PDTable,
       lookup pdinsertion (memory s) beqAddr = Some (PDT pd) /\
       pdentryNbFreeSlots pdinsertion predCurrentNbFreeSlots s /\
       predCurrentNbFreeSlots > 0 /\
       pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s /\
       bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s /\
       StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots /\
       (exists
          (s0 : state) (pdentry pdentry0 : PDTable) (bentry bentry0 bentry1 bentry2
                                                     bentry3 bentry4
                                                     bentry5 : BlockEntry),
          s =
          {|
          currentPartition := currentPartition s0;
          memory := add newBlockEntryAddr
                      (BE
                         (CBlockEntry (read bentry5) (write bentry5) e
                            (present bentry5) (accessible bentry5)
                            (blockindex bentry5) (blockrange bentry5)))
                      (add newBlockEntryAddr
                         (BE
                            (CBlockEntry (read bentry4) w
                               (exec bentry4) (present bentry4)
                               (accessible bentry4) (blockindex bentry4)
                               (blockrange bentry4)))
                         (add newBlockEntryAddr
                            (BE
                               (CBlockEntry r (write bentry3)
                                  (exec bentry3) (present bentry3)
                                  (accessible bentry3) (blockindex bentry3)
                                  (blockrange bentry3)))
                            (add newBlockEntryAddr
                               (BE
                                  (CBlockEntry (read bentry2)
                                     (write bentry2) (exec bentry2) true
                                     (accessible bentry2)
                                     (blockindex bentry2)
                                     (blockrange bentry2)))
                               (add newBlockEntryAddr
                                  (BE
                                     (CBlockEntry (read bentry1)
                                        (write bentry1) (exec bentry1)
                                        (present bentry1) true
                                        (blockindex bentry1)
                                        (blockrange bentry1)))
                                  (add newBlockEntryAddr
                                     (BE
                                        (CBlockEntry (read bentry0)
                                           (write bentry0)
                                           (exec bentry0)
                                           (present bentry0)
                                           (accessible bentry0)
                                           (blockindex bentry0)
                                           (CBlock (startAddr (blockrange bentry0))
                                              endaddr)))
                                     (add newBlockEntryAddr
                                        (BE
                                           (CBlockEntry (read bentry)
                                              (write bentry)
                                              (exec bentry)
                                              (present bentry)
                                              (accessible bentry)
                                              (blockindex bentry)
                                              (CBlock startaddr
                                                 (endAddr (blockrange bentry)))))
                                        (add pdinsertion
                                           (PDT
                                              {|
                                              structure := structure pdentry0;
                                              firstfreeslot := firstfreeslot pdentry0;
                                              nbfreeslots := predCurrentNbFreeSlots;
                                              nbprepare := nbprepare pdentry0;
                                              parent := parent pdentry0;
                                              MPU := MPU pdentry0 |})
                                           (add pdinsertion
                                              (PDT
                                                 {|
                                                 structure := structure pdentry;
                                                 firstfreeslot := newFirstFreeSlotAddr;
                                                 nbfreeslots := nbfreeslots pdentry;
                                                 nbprepare := nbprepare pdentry;
                                                 parent := parent pdentry;
                                                 MPU := MPU pdentry |})
                                              (memory s0) beqAddr) beqAddr) beqAddr)
                                     beqAddr) beqAddr) beqAddr) beqAddr) beqAddr)
                      beqAddr |})) /\
    (exists entry : SCEntry,
       lookup SCEAddr (memory s) beqAddr = Some (SCE entry) /\
       scentryAddr newBlockEntryAddr SCEAddr s)). intuition.
		intro s0. intuition.
		destruct (lookup SCEAddr (memory s0) beqAddr) eqn:Hlookup.
		destruct v eqn:Hv.
		3: { (** modify **)
			instantiate (1:= fun _ s => exists pd : PDTable, lookup pdinsertion (memory s) beqAddr = Some (PDT pd) /\
     pdentryNbFreeSlots pdinsertion predCurrentNbFreeSlots s /\ predCurrentNbFreeSlots > 0 /\
     pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s /\
    bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s /\
   StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots

/\ (exists s0, exists pdentry : PDTable, exists pdentry0 : PDTable,
		exists bentry bentry0 bentry1 bentry2 bentry3 bentry4 bentry5: BlockEntry,
		exists sceaddr, exists scentry : SCEntry,
  s = {|
     currentPartition := currentPartition s0;
     memory := add sceaddr
									(SCE {| origin := origin; next := next scentry |})
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry5) (write bentry5) e (present bentry5)
                       (accessible bentry5) (blockindex bentry5) (blockrange bentry5)))
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry4) w (exec bentry4) (present bentry4)
                       (accessible bentry4) (blockindex bentry4) (blockrange bentry4)))
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry r (write bentry3) (exec bentry3) (present bentry3)
                       (accessible bentry3) (blockindex bentry3) (blockrange bentry3)))
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry2) (write bentry2) (exec bentry2) true
                       (accessible bentry2) (blockindex bentry2) (blockrange bentry2)))
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry1) (write bentry1) (exec bentry1)
                       (present bentry1) true (blockindex bentry1) (blockrange bentry1)))
							(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry0) (write bentry0) (exec bentry0)
                       (present bentry0) (accessible bentry0) (blockindex bentry0)
                       (CBlock (startAddr (blockrange bentry0)) endaddr)))
							(add newBlockEntryAddr
                     (BE
                        (CBlockEntry (read bentry) (write bentry)
                           (exec bentry) (present bentry) (accessible bentry)
                           (blockindex bentry)
                           (CBlock startaddr (endAddr (blockrange bentry)))))
								(add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry0;
                    firstfreeslot := firstfreeslot pdentry0;
                    nbfreeslots := predCurrentNbFreeSlots;
                    nbprepare := nbprepare pdentry0;
                    parent := parent pdentry0;
                    MPU := MPU pdentry0 |})
								(add pdinsertion
                 (PDT
                    {|
                    structure := structure pdentry;
                    firstfreeslot := newFirstFreeSlotAddr;
                    nbfreeslots := nbfreeslots pdentry;
                    nbprepare := nbprepare pdentry;
                    parent := parent pdentry;
                    MPU := MPU pdentry |}) (memory s0) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr) beqAddr |}

)).
			eapply weaken. apply modify.
			intros. simpl.  set (s' := {|
      currentPartition :=  _|}). destruct H. destruct H0. destruct H0. exists x.

			split. cbn. admit.
			split. unfold pdentryNbFreeSlots in *. destruct H. destruct H0.
			destruct H0. rewrite H in H0. admit. intuition. intuition.
			admit. admit. destruct H8. destruct H7. destruct H7. destruct H7. destruct H7.
			destruct H7. destruct H7. destruct H7. destruct H7. destruct H7.
			exists x0. exists x1. exists x2. exists x3. exists x4. exists x5. exists x6.
			exists x7. exists x8. exists x9.
			exists SCEAddr. exists s. subst. intuition.
			admit. admit. admit. admit. admit. }
intros. simpl.*)

	eapply weaken. apply ret.
	intros.
destruct H as [newpd]. destruct H. destruct H0.
destruct H1.
destruct H2 as [s0 [pdentry [pdentry0 [pdentry1 [bentry [bentry0 [bentry1 [bentry2
               [bentry3 [bentry4 [bentry5 [bentry6 [sceaddr [scentry [Hs Hpropag]]]]]]]]]]]]]]].

(* Global knowledge on current state and at s0 *)
assert(Hblockindex1 : blockindex bentry6 = blockindex bentry5).
{ intuition. subst bentry6.
 	unfold CBlockEntry.
	destruct(lt_dec (blockindex bentry5) kernelStructureEntriesNb) eqn:Hdec ; try(exfalso ; congruence).
	intuition. simpl. intuition.
	destruct blockentry_d. destruct bentry5.
	intuition.
}
assert(Hblockindex2 : blockindex bentry5 = blockindex bentry4).
{ intuition. subst bentry5.
 	unfold CBlockEntry.
	destruct(lt_dec (blockindex bentry4) kernelStructureEntriesNb) eqn:Hdec ; try(exfalso ; congruence).
	intuition. simpl. intuition.
	destruct blockentry_d. destruct bentry4.
	intuition.
}
assert(Hblockindex3 : blockindex bentry4 = blockindex bentry3).
{ intuition. subst bentry4.
 	unfold CBlockEntry.
	destruct(lt_dec (blockindex bentry3) kernelStructureEntriesNb) eqn:Hdec ; try(exfalso ; congruence).
	intuition. simpl. intuition.
	destruct blockentry_d. destruct bentry3.
	intuition.
}
assert(Hblockindex4 : blockindex bentry3 = blockindex bentry2).
{ intuition. subst bentry3.
 	unfold CBlockEntry.
	destruct(lt_dec (blockindex bentry2) kernelStructureEntriesNb) eqn:Hdec ; try(exfalso ; congruence).
	intuition. simpl. intuition.
	destruct blockentry_d. destruct bentry2.
	intuition.
}
assert(Hblockindex5 : blockindex bentry2 = blockindex bentry1).
{ intuition. subst bentry2.
 	unfold CBlockEntry.
	destruct(lt_dec (blockindex bentry1) kernelStructureEntriesNb) eqn:Hdec ; try(exfalso ; congruence).
	intuition. simpl. intuition.
	destruct blockentry_d. destruct bentry1.
	intuition.
}
assert(Hblockindex6 : blockindex bentry1 = blockindex bentry0).
{ intuition. subst bentry1.
 	unfold CBlockEntry.
	destruct(lt_dec (blockindex bentry0) kernelStructureEntriesNb) eqn:Hdec ; try(exfalso ; congruence).
	intuition. simpl. intuition.
	destruct blockentry_d. destruct bentry0.
	intuition.
}
assert(Hblockindex7 : blockindex bentry0 = blockindex bentry).
{ intuition. subst bentry0.
 	unfold CBlockEntry.
	destruct(lt_dec (blockindex bentry) kernelStructureEntriesNb) eqn:Hdec ; try(exfalso ; congruence).
	intuition. simpl. intuition.
	destruct blockentry_d. destruct bentry.
	intuition.
}

assert(Hblockindex : blockindex bentry6 = blockindex bentry).
{ rewrite Hblockindex1. rewrite Hblockindex2. rewrite Hblockindex3.
	rewrite Hblockindex4. rewrite Hblockindex5. rewrite Hblockindex6.
	intuition.
}

assert(HBEs0 : isBE newBlockEntryAddr s0).
{ intuition. unfold isBE. rewrite H2. intuition. }
assert(HBEs : isBE newBlockEntryAddr s).
{ intuition. unfold isBE. rewrite H4. intuition. }
intuition.
	- exists s0. intuition.
	- unfold consistency. split.
		{ (* wellFormedFstShadowIfBlockEntry *)
			unfold wellFormedFstShadowIfBlockEntry.
			intros pa HBEaddrs.

			(* 1) isBE pa s in hypothesis: eliminate impossible values for pa *)
			destruct (beqAddr pdinsertion pa) eqn:beqpdpa in HBEaddrs ; try(exfalso ; congruence).
			* (* pdinsertion = pa *)
				rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdpa.
				rewrite <- beqpdpa in *.
				unfold isPDT in *. unfold isBE in *. rewrite H in *.
				exfalso ; congruence.
			* (* pdinsertion <> pa *)
				apply isBELookupEq in HBEaddrs. rewrite Hs in HBEaddrs. cbn in HBEaddrs. destruct HBEaddrs as [entry HBEaddrs].
				destruct (beqAddr sceaddr pa) eqn:beqpasce in HBEaddrs ; try(exfalso ; congruence).
				(* sceaddr <> pa *)
				destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:beqpdnewblock in HBEaddrs ; try(exfalso ; congruence).
				**	(* pdinsertion = newBlockEntryAddr *)
						rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdnewblock.
						rewrite beqpdnewblock in *.
						unfold isPDT in *. unfold isBE in *. rewrite H in *.
						congruence.
				** 	(* pdinsertion <> newBlockEntryAddr *)
						destruct (beqAddr newBlockEntryAddr sceaddr) eqn:beqnewblocksce in HBEaddrs ; try(exfalso ; congruence).
						*** (* newBlockEntryAddr = sceaddr *)
								rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewblocksce.
								rewrite beqnewblocksce in *.
								rewrite Hs in H4. cbn in H4. repeat rewrite beqAddrTrue in H4.
								congruence.
						*** (* newBlockEntryAddr <> sceaddr *)
								repeat rewrite beqAddrTrue in HBEaddrs.
								cbn in HBEaddrs.
								destruct (beqAddr newBlockEntryAddr pa) eqn:beqnewblockpa in HBEaddrs ; try(exfalso ; congruence).
							**** 	(* 2) treat special case where newBlockEntryAddr = pa *)
										rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewblockpa.
										rewrite <- beqnewblockpa in *.
										assert(Hcons : wellFormedFstShadowIfBlockEntry s0)
														by (unfold consistency in *; intuition).
										unfold wellFormedFstShadowIfBlockEntry in *.
										specialize (Hcons newBlockEntryAddr).
										unfold isBE in Hcons.
										assert(HBE : lookup newBlockEntryAddr (memory s0) beqAddr = Some (BE bentry))
													by intuition.
										rewrite HBE in *.
										apply isSHELookupEq.
										rewrite Hs. cbn.
										(* 3) eliminate impossible values for (CPaddr (newBlockEntryAddr + sh1offset)) *)
										destruct (beqAddr sceaddr (CPaddr (newBlockEntryAddr + sh1offset))) eqn:beqsceoffset ; try(exfalso ; congruence).
										++++ (* sceaddr = (CPaddr (newBlockEntryAddr + sh1offset)) *)
													rewrite <- DependentTypeLemmas.beqAddrTrue in beqsceoffset.
													assert(HSCE : wellFormedShadowCutIfBlockEntry s0)
																	by (unfold consistency in *; intuition).
													specialize(HSCE newBlockEntryAddr).
													unfold isBE in HSCE.
													rewrite HBE in *. destruct HSCE ; trivial.
													intuition. subst x.
													unfold isSCE in *. unfold isSHE in *.
													rewrite <- beqsceoffset in *.
													rewrite <- H11 in *.
													destruct (lookup sceaddr (memory s0) beqAddr) eqn:Hlookup ; try(exfalso ; congruence).
													destruct v eqn:Hv ; try(exfalso ; congruence).
										++++ (*sceaddr <> (CPaddr (newBlockEntryAddr + sh1offset))*)
													repeat rewrite beqAddrTrue.
													rewrite <- beqAddrFalse in *. intuition.
													repeat rewrite removeDupIdentity; intuition.
													destruct (beqAddr newBlockEntryAddr sceaddr) eqn:Hfalse. (*proved before *)
													rewrite <- DependentTypeLemmas.beqAddrTrue in Hfalse ; congruence.
													cbn.
													destruct (beqAddr newBlockEntryAddr (CPaddr (newBlockEntryAddr + sh1offset))) eqn:newblocksh1offset.
													+++++ (* newBlockEntryAddr = (CPaddr (newBlockEntryAddr + sh1offset))*)
																rewrite <- DependentTypeLemmas.beqAddrTrue in newblocksh1offset.
																rewrite <- newblocksh1offset in *.
																unfold isSHE in *. rewrite HBE in *.
																exfalso ; congruence.
													+++++ (* newBlockEntryAddr <> (CPaddr (newBlockEntryAddr + sh1offset))*)
																cbn.
																rewrite <- beqAddrFalse in *. intuition.
																repeat rewrite removeDupIdentity; intuition.
																destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hffalse. (*proved before *)
																rewrite <- DependentTypeLemmas.beqAddrTrue in Hffalse ; congruence.
																cbn.
																destruct (beqAddr pdinsertion (CPaddr (newBlockEntryAddr + sh1offset))) eqn:pdsh1offset.
																++++++ (* pdinsertion = (CPaddr (newBlockEntryAddr + sh1offset))*)
																				rewrite <- DependentTypeLemmas.beqAddrTrue in *.
																				rewrite <- pdsh1offset in *.
																				unfold isSHE in *. unfold isPDT in *.
																				destruct (lookup pdinsertion (memory s0) beqAddr) eqn:Hlookup ; try(exfalso ; congruence).
																				destruct v eqn:Hv ; try(exfalso ; congruence).
																++++++ (* pdinsertion <> (CPaddr (newBlockEntryAddr + sh1offset))*)
																				rewrite <- beqAddrFalse in *.
																				repeat rewrite removeDupIdentity; intuition.
																				assert(HSHEs0: isSHE (CPaddr (newBlockEntryAddr + sh1offset)) s0)
																					by intuition.
																				apply isSHELookupEq in HSHEs0. destruct HSHEs0 as [shentry HSHEs0].
																				(* 4) resolve the only true case *)
																				exists shentry. easy.

							**** (* 4) treat special case where pa is not equal to any modified entries*)
										(* newBlockEntryAddr <> pa *)
										cbn in HBEaddrs.
										destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hfalse ; try(exfalso ; congruence).
										rewrite <- beqAddrFalse in *.
										do 6 rewrite removeDupIdentity in HBEaddrs; intuition.
										cbn in HBEaddrs.
										destruct (beqAddr pdinsertion pa) eqn:Hffalse ; try(exfalso ; congruence).
										do 4 rewrite removeDupIdentity in HBEaddrs; intuition.
										(* no modifictions of SHE so what is true at s0 is still true at s *)
										assert(HSHEEq : isSHE (CPaddr (pa + sh1offset)) s = isSHE (CPaddr (pa + sh1offset)) s0).
										{
											assert(HSHE : wellFormedFstShadowIfBlockEntry s0)
																		by (unfold consistency in *; intuition).
											specialize(HSHE pa).
											unfold isBE in HSHE.
											assert(HSCE : wellFormedShadowCutIfBlockEntry s0)
																		by (unfold consistency in *; intuition).
											specialize(HSCE pa).
											unfold isBE in HSCE.
											rewrite HBEaddrs in *. intuition.
											destruct H26 as [scentryaddr]. intuition. subst scentryaddr.
											rewrite Hs. unfold isSHE. cbn.
											repeat rewrite beqAddrTrue.
											rewrite <- beqAddrFalse in *. intuition.
											repeat rewrite removeDupIdentity; intuition.
											assert(HBE : lookup newBlockEntryAddr (memory s0) beqAddr = Some (BE bentry))
																		by intuition.
											(* eliminate impossible values for (CPaddr (pa + sh1offset)) *)
											destruct (beqAddr sceaddr (CPaddr (pa + sh1offset))) eqn:Hscesh1offset.
											 - 	(* sceaddr = (CPaddr (pa + sh1offset)) *)
													rewrite <- DependentTypeLemmas.beqAddrTrue in Hscesh1offset.
													rewrite <- Hscesh1offset in *.
													assert(HSCE : isSCE sceaddr s0).
													{ rewrite H11.
														assert(HSCE : wellFormedShadowCutIfBlockEntry s0)
																					by (unfold consistency in *; intuition).
														specialize(HSCE newBlockEntryAddr).
														unfold isBE in HSCE.
														rewrite HBE in *. intuition.
														destruct H26. intuition. subst x.
														rewrite <- H11 in *.
														unfold isSHE in *. unfold isSCE in *.
														congruence.
													}
													apply isSCELookupEq in HSCE. destruct HSCE.
													rewrite H26. trivial.
													(* almost DUP with previous step *)
												- (* sceaddr <> (CPaddr (pa + sh1offset))*)
														destruct(beqAddr newBlockEntryAddr sceaddr) eqn:Hnewblocksce. (* Proved before *)
														rewrite <- DependentTypeLemmas.beqAddrTrue in Hnewblocksce ; congruence.
														cbn.
														rewrite <- beqAddrFalse in *.
														destruct (beqAddr newBlockEntryAddr (CPaddr (pa + sh1offset))) eqn:newblocksh1offset.
														+ (* newBlockEntryAddr = (CPaddr (pa + sh1offset))*)
															rewrite <- DependentTypeLemmas.beqAddrTrue in newblocksh1offset.
															rewrite <- newblocksh1offset in *.
															unfold isSHE in *. rewrite HBE in *.
															exfalso ; congruence.
														+ (* newBlockEntryAddr <> (CPaddr (pa + sh1offset))*)
															cbn.
															rewrite <- beqAddrFalse in *.
															repeat rewrite removeDupIdentity; intuition.
															destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hfffalse. (*proved before *)
															rewrite <- DependentTypeLemmas.beqAddrTrue in Hfffalse ; congruence.
															cbn.
															destruct (beqAddr pdinsertion (CPaddr (pa + sh1offset))) eqn:pdsh1offset.
															* (* pdinsertion = (CPaddr (pa + sh1offset))*)
																rewrite <- DependentTypeLemmas.beqAddrTrue in *.
																rewrite <- pdsh1offset in *.
																unfold isSHE in *. unfold isPDT in *.
																destruct (lookup pdinsertion (memory s0) beqAddr) eqn:Hlookup ; try(exfalso ; congruence).
																destruct v eqn:Hv ; try(exfalso ; congruence).
															* (* pdinsertion <> (CPaddr (pa + sh1offset))*)
																rewrite <- beqAddrFalse in *.
																(* resolve the only true case *)
																repeat rewrite removeDupIdentity; intuition.
									}
									rewrite HSHEEq.
									assert(HSHE : wellFormedFstShadowIfBlockEntry s0)
																by (unfold consistency in *; intuition).
									specialize(HSHE pa).
									unfold isBE in HSHE.
									rewrite HBEaddrs in *. intuition.
			}
	assert(beqAddr pdinsertion newBlockEntryAddr = false).
	{
		destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:beqpdnewblock; try(exfalso ; congruence).
		*	(* pdinsertion = newBlockEntryAddr *)
			rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdnewblock.
			rewrite beqpdnewblock in *.
			unfold isPDT in *. unfold isBE in *. rewrite H in *.
			congruence.
		* (* pdinsertion <> newBlockEntryAddr *)
			reflexivity.
	}
	assert(beqAddr newBlockEntryAddr sceaddr = false).
	{
		destruct (beqAddr newBlockEntryAddr sceaddr) eqn:beqnewblocksce ; try(exfalso ; congruence).
		* (* newBlockEntryAddr = sceaddr *)
								rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewblocksce.
								rewrite beqnewblocksce in *.
								rewrite Hs in H4. cbn in H4. repeat rewrite beqAddrTrue in H4.
								congruence.
		* (* newBlockEntryAddr <> sceaddr *)
			reflexivity.
	}
	assert(HSCE : isSCE sceaddr s0).
	{ rewrite H11.
		assert(HSCE : wellFormedShadowCutIfBlockEntry s0)
									by (unfold consistency in *; intuition).
		specialize(HSCE newBlockEntryAddr).
		unfold isBE in HSCE.
		rewrite H2 in *. intuition.
		destruct H27. intuition. subst x.
		rewrite <- H11 in *.
		unfold isSHE in *. unfold isSCE in *.
		congruence.
	}
	assert(beqAddr pdinsertion sceaddr = false).
	{
		destruct (beqAddr pdinsertion sceaddr) eqn:beqpdsce; try(exfalso ; congruence).
		*	(* pdinsertion = sceaddr *)
			rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdsce.
			rewrite beqpdsce in *.
			unfold isPDT in *.
			apply isSCELookupEq in HSCE. destruct HSCE.
			rewrite H27 in *. exfalso;congruence.
		* (* pdinsertion <> sceaddr *)
			reflexivity.
	}
	assert(isSCE sceaddr s).
	{
		unfold isSCE. rewrite Hs. cbn.
		rewrite beqAddrTrue. trivial.
	}
	split.
	{ (* PDTIfPDFlag s *)
		assert(Hcons0 : PDTIfPDFlag s0) by (unfold consistency in * ; intuition).
		unfold PDTIfPDFlag.
		intros idPDchild sh1entryaddr HcheckChilds.
		destruct HcheckChilds as [HcheckChilds Hsh1entryaddr].
		(* develop idPDchild *)
		unfold checkChild in HcheckChilds.
		unfold entryPDT.
		unfold bentryStartAddr.

		(* Force BE type for idPDchild*)
		destruct(lookup idPDchild (memory s) beqAddr) eqn:Hlookup in HcheckChilds ; try(exfalso ; congruence).
		destruct v eqn:Hv ; try(exfalso ; congruence).
		eexists. intuition. rewrite Hlookup. intuition.
		(* check all possible values of idPDchild in s -> only newBlock is OK
				1) if idPDchild == newBlock then contradiction because
						- we read the pdflag value of newBlock which is not modified in s so equal to s0
						- at s0 newBlock was a freeSlot so the flag was default to false
						- here we look for a flag to true, so idPDchild can't be newBlock
				2) if idPDchild <> any modified address then
						- lookup idPDchild s == lookup idPDchild s0
						- we didn't change the pdflag
						- explore all possible values of idPdchild's startaddr which must be a PDT
								- only possible match is with pdinsertion -> ok in this case, it means
									another entry in s0 points to pdinsertion
								- for the rest, PDTIfPDFlag at s0 prevales *)
		destruct (beqAddr pdinsertion idPDchild) eqn:beqpdidpd; try(exfalso ; congruence).
		*	(* pdinsertion = idPDchild *)
			rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdidpd.
			rewrite beqpdidpd in *.
			congruence.
		* (* pdinsertion <> pdinsertion *)
			destruct (beqAddr sceaddr idPDchild) eqn:beqsceidpd; try(exfalso ; congruence).
			**	(* sceaddr = idPDchild *)
				rewrite <- DependentTypeLemmas.beqAddrTrue in beqsceidpd.
				unfold isSCE in *.
				rewrite <- beqsceidpd in *.
				rewrite Hlookup in *.
				exfalso; congruence.
			** (* sceaddr <> idPDchild *)
					assert(HidPDs0 : isBE idPDchild s0).
					{ rewrite Hs in Hlookup. cbn in Hlookup.
						rewrite beqAddrTrue in Hlookup.
						rewrite beqsceidpd in Hlookup.
						rewrite H24 in Hlookup. (*newBlock <> sce *)
						rewrite H26 in Hlookup. (*pd <> newblock*)
						rewrite beqAddrTrue in Hlookup.
						cbn in Hlookup.
						destruct (beqAddr newBlockEntryAddr idPDchild) eqn:beqnewidpd; try(exfalso ; congruence).
						* (* newBlockEntryAddr = idPDchild *)
							rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewidpd.
							rewrite <- beqnewidpd.
							apply isBELookupEq. exists bentry. intuition.
						* (* newBlockEntryAddr <> idPDchild *)
							assert(HpdnewNotEq : beqAddr pdinsertion newBlockEntryAddr = false) by intuition.
							rewrite HpdnewNotEq in Hlookup. (*pd <> newblock*)
							rewrite <- beqAddrFalse in *.
							do 6 rewrite removeDupIdentity in Hlookup; intuition.
							cbn in Hlookup.
							destruct (beqAddr pdinsertion idPDchild) eqn:Hff ;try (exfalso;congruence).
							do 4 rewrite removeDupIdentity in Hlookup; intuition.
							unfold isBE. rewrite Hlookup ; trivial.
					}
					intuition.
					(* PDflag was false at s0 *)
					assert(HfreeSlot : FirstFreeSlotPointerIsBEAndFreeSlot s0)
													by (unfold consistency in *; intuition).
					unfold FirstFreeSlotPointerIsBEAndFreeSlot in *.
					assert(HPDTs0 : isPDT pdinsertion s0) by intuition.
					apply isPDTLookupEq in HPDTs0. destruct HPDTs0 as [pds0 HPDTs0].
					assert(HfreeSlots0 : pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s0)
						 by intuition.
					specialize (HfreeSlot pdinsertion pds0 HPDTs0).
					unfold pdentryFirstFreeSlot in HfreeSlots0.
					rewrite HPDTs0 in HfreeSlots0.
					assert(HfreeSlotNotNull : FirstFreeSlotPointerNotNullEq s0)
													by (unfold consistency in *; intuition).
					unfold FirstFreeSlotPointerNotNullEq in *.
					specialize (HfreeSlotNotNull pdinsertion currnbfreeslots).
					destruct HfreeSlotNotNull as [HLeft HRight].
					(*intuition.*)

					assert(Hsh1s0 : isSHE sh1entryaddr s0).
					{ destruct (lookup sh1entryaddr (memory s) beqAddr) eqn:Hsh1 ; try(exfalso ; congruence).
						destruct v0 eqn:Hv0 ; try(exfalso ; congruence).
						(* prove flag didn't change *)
						rewrite Hs in Hsh1.
						cbn in Hsh1.
						rewrite beqAddrTrue in Hsh1.
						destruct (beqAddr sceaddr sh1entryaddr) eqn:beqscesh1; try(exfalso ; congruence).
						assert(HnewsceNotEq : beqAddr newBlockEntryAddr sceaddr = false) by intuition.
						rewrite HnewsceNotEq in *. (* newblock <> sce *)
						cbn in Hsh1.
						destruct (beqAddr newBlockEntryAddr sh1entryaddr) eqn:beqnewsh1; try(exfalso ; congruence).
						destruct (beqAddr pdinsertion sh1entryaddr) eqn:beqpdsh1; try(exfalso ; congruence).
						* (* pdinsertion = sh1entryaddr *)
								rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdsh1.
								rewrite <- beqpdsh1 in *.
								rewrite beqAddrTrue in Hsh1.
								rewrite <- beqAddrFalse in *.
								do 7 rewrite removeDupIdentity in Hsh1; intuition.
								destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:beqnewpd; try(exfalso ; congruence).
								rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewpd.
								congruence.
								cbn in Hsh1.
								rewrite beqAddrTrue in Hsh1.
								congruence.
						* (* pdinsertion <> sh1entryaddr *)
								cbn in Hsh1.
								(*rewrite H18 in Hsh1.*)
								rewrite beqAddrTrue in Hsh1.
								rewrite <- beqAddrFalse in *.
								do 7 rewrite removeDupIdentity in Hsh1; intuition.
								cbn in Hsh1.
								destruct (beqAddr pdinsertion sh1entryaddr) eqn:Hfff ; try (exfalso ; congruence).
								rewrite <- DependentTypeLemmas.beqAddrTrue in Hfff. congruence.
								destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:beqnewpd; try(exfalso ; congruence).
								rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewpd.
								congruence.
								cbn in Hsh1; intuition.
								destruct (beqAddr pdinsertion sh1entryaddr) eqn:Hffff; try(exfalso ; congruence).
								do 3 rewrite removeDupIdentity in Hsh1; intuition.
								unfold isSHE. rewrite Hsh1 in *. trivial.
					}
					 (*assert(Hsh1eq : isSHE sh1entryaddr s0 = isSHE sh1entryaddr s).
					{ (* Partial DUP *)
						rewrite Hs. unfold isSHE.
						cbn.
						rewrite beqAddrTrue.
						apply isSHELookupEq in Hsh1s0. destruct Hsh1s0 as [xsh1 Hsh1s0].
						rewrite Hsh1s0.
						destruct (beqAddr sceaddr sh1entryaddr) eqn:beqscesh1; try(exfalso ; congruence).
						* (* sceaddr = sh1entryaddr *)
							rewrite <- DependentTypeLemmas.beqAddrTrue in beqscesh1.
							rewrite <- beqscesh1 in *.
							apply isSCELookupEq in HSCE. destruct HSCE as [x HSCE].
							rewrite HSCE in *; congruence.
						*	(* sceaddr <> sh1entryaddr *)
							rewrite H20 in *. (* newblock <> sce *)
							cbn.
							destruct (beqAddr newBlockEntryAddr sh1entryaddr) eqn:beqnewsh1; try(exfalso ; congruence).
							** (* newBlockEntryAddr = sh1entryaddr *)
									rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewsh1.
									rewrite <- beqnewsh1 in *.
									congruence.
							** (* newBlockEntryAddr <> sh1entryaddr *)
									rewrite H20. (*pd <> newblock *)
									rewrite <- beqAddrFalse in *.
									repeat rewrite removeDupIdentity; intuition.
									cbn.
									destruct (beqAddr pdinsertion sh1entryaddr) eqn:beqpdsh1; try(exfalso ; congruence).
									*** (* pdinsertion = sh1entryaddr *)
											rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdsh1.
											rewrite <- beqpdsh1 in *.
											unfold isPDT in *.
											rewrite Hsh1s0 in *. exfalso ; congruence.
									*** (* pdinsertion <> sh1entryaddr *)
											cbn.
											rewrite <- beqAddrFalse in *.
											rewrite beqAddrTrue.
											destruct (beqAddr newBlockEntryAddr sceaddr) eqn:Hf; try(exfalso ; congruence).
											rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
											repeat rewrite removeDupIdentity; intuition.
											cbn.
											destruct (beqAddr newBlockEntryAddr sh1entryaddr) eqn:Hff; try(exfalso ; congruence).
											rewrite <- DependentTypeLemmas.beqAddrTrue in Hff. congruence.
											repeat rewrite removeDupIdentity; intuition.
											cbn.
											destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hfff; try(exfalso ; congruence).
											rewrite <- DependentTypeLemmas.beqAddrTrue in Hfff. congruence.
											repeat rewrite removeDupIdentity; intuition.
											cbn.
											destruct (beqAddr pdinsertion sh1entryaddr) eqn:Hffff; try(exfalso ; congruence).
											rewrite <- DependentTypeLemmas.beqAddrTrue in Hffff. congruence.
											repeat rewrite removeDupIdentity; intuition.
											cbn.
											rewrite Hsh1s0. trivial.
					}
					assert(Hsh1s : isSHE sh1entryaddr s).
					{ (*DUP of eq*)
						destruct (lookup sh1entryaddr (memory s) beqAddr) eqn:Hsh1 ; try(exfalso ; congruence).
						destruct v0 eqn:Hv0 ; try(exfalso ; congruence).
						rewrite Hs. unfold isSHE.
						cbn.
						rewrite beqAddrTrue.
						destruct (beqAddr sceaddr sh1entryaddr) eqn:beqscesh1; try(exfalso ; congruence).
						* (* sceaddr = sh1entryaddr *)
							rewrite <- DependentTypeLemmas.beqAddrTrue in beqscesh1.
							rewrite <- beqscesh1 in *.
							assert(HSCEs : isSCE sceaddr s) by intuition.
							apply isSCELookupEq in HSCEs. destruct HSCEs as [x HSCEs].
							rewrite HSCEs in *; congruence.
						*	(* sceaddr <> sh1entryaddr *)
							rewrite H20 in *. (* newblock <> sce *)
							cbn.
							destruct (beqAddr newBlockEntryAddr sh1entryaddr) eqn:beqnewsh1; try(exfalso ; congruence).
							** (* newBlockEntryAddr = sh1entryaddr *)
									rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewsh1.
									rewrite <- beqnewsh1 in *.
									congruence.
							** (* newBlockEntryAddr <> sh1entryaddr *)
									rewrite H20. (* pd <> newblock *)
									rewrite <- beqAddrFalse in *.
									repeat rewrite removeDupIdentity; intuition.
									cbn.
									destruct (beqAddr pdinsertion sh1entryaddr) eqn:beqpdsh1; try(exfalso ; congruence).
									*** (* pdinsertion = sh1entryaddr *)
											rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdsh1.
											rewrite <- beqpdsh1 in *.
											unfold isPDT in *.
											exfalso ; congruence.
									*** (* pdinsertion <> sh1entryaddr *)
											cbn.
											rewrite <- beqAddrFalse in *.
											rewrite beqAddrTrue.
											repeat rewrite removeDupIdentity; intuition.
											cbn.
											destruct (beqAddr newBlockEntryAddr sceaddr) eqn:Hf; try(exfalso ; congruence).
											rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
											repeat rewrite removeDupIdentity; intuition.
											cbn.
											destruct (beqAddr newBlockEntryAddr sh1entryaddr) eqn:Hff; try(exfalso ; congruence).
											rewrite <- DependentTypeLemmas.beqAddrTrue in Hff. congruence.
											repeat rewrite removeDupIdentity; intuition.
											cbn.
											destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hfff; try(exfalso ; congruence).
											rewrite <- DependentTypeLemmas.beqAddrTrue in Hfff. congruence.
											repeat rewrite removeDupIdentity; intuition.
											cbn.
											destruct (beqAddr pdinsertion sh1entryaddr) eqn:Hffff; try(exfalso ; congruence).
											rewrite <- DependentTypeLemmas.beqAddrTrue in Hffff. congruence.
											repeat rewrite removeDupIdentity; intuition.
	}*)

					specialize(Hcons0 idPDchild sh1entryaddr).
					unfold checkChild in Hcons0.
					apply isBELookupEq in HidPDs0. destruct HidPDs0 as [x HidPDs0].
					rewrite HidPDs0 in Hcons0.
					apply isSHELookupEq in Hsh1s0. destruct Hsh1s0 as [y Hsh1s0].
					rewrite Hsh1s0 in *.
					destruct (beqAddr newBlockEntryAddr idPDchild) eqn:beqnewidpd; try(exfalso ; congruence).
					*** (* 1) newBlockEntryAddr = idPDchild *)
							(* newBlockEntryAddr at s0 is firstfreeslot, so flag is false *)
						rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewidpd.
						rewrite <- beqnewidpd.
						rewrite <- HfreeSlots0 in HfreeSlot.
						destruct HfreeSlot as [isBEs0 isFreeSlots0].
						destruct HLeft ; intuition (*right part of FirstFreeSlotPointerNotNullEq, exists freeslotpointer : paddr,...*).
						unfold pdentryFirstFreeSlot in *. rewrite HPDTs0 in *.
						intuition.
						congruence.

						unfold isFreeSlot in isFreeSlots0.
						rewrite H2 in isFreeSlots0.
						unfold sh1entryAddr in Hsh1entryaddr.
						rewrite Hlookup in Hsh1entryaddr.
						rewrite <- beqnewidpd in Hsh1entryaddr.
						rewrite <- Hsh1entryaddr in isFreeSlots0.
						rewrite Hsh1s0 in isFreeSlots0.
						rewrite <- H11 in isFreeSlots0.
						apply isSCELookupEq in HSCE. destruct HSCE as [scentrys0 HSCEs0].
						rewrite HSCEs0 in isFreeSlots0.
						(*Trial with isFreSlot in recursion
						unfold isFreeSlot in isFreeSlots0.
						unfold isFreeSlotAux in *.
						revert isFreeSlots0. simpl.
						rewrite H2.
						unfold sh1entryAddr in Hsh1entryaddr.
						rewrite Hlookup in Hsh1entryaddr.
						rewrite <- beqnewidpd in Hsh1entryaddr.
						rewrite <- Hsh1entryaddr.
						rewrite Hsh1s0.
						rewrite <- H11.
						apply isSCELookupEq in HSCE. destruct HSCE as [scentrys0 HSCEs0].
						rewrite HSCEs0. intro isFreeSlots0. intuition. clear H30. (* don't need recursion *)
*)


						exfalso. (* Prove false in hypothesis -> flag is false *)

						destruct (beqAddr sceaddr sh1entryaddr) eqn:beqscesh1; try(exfalso ; congruence).
						-- (* sceaddr = sh1entryaddr *)
							rewrite <- DependentTypeLemmas.beqAddrTrue in beqscesh1.
							rewrite <- beqscesh1 in *.
							assert(HSCEs : isSCE sceaddr s) by intuition.
							apply isSCELookupEq in HSCEs. destruct HSCEs as [scentrys HSCEs].
							rewrite HSCEs in *; congruence.
						--	(* sceaddr <> sh1entryaddr *)
							destruct (beqAddr newBlockEntryAddr sh1entryaddr) eqn:beqnewsh1; try(exfalso ; congruence).
							--- (* newBlockEntryAddr = sh1entryaddr *)
									rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewsh1.
									rewrite <- beqnewsh1 in *.
									congruence.
							--- (* newBlockEntryAddr <> sh1entryaddr *)
									rewrite <- beqAddrFalse in *.
									repeat rewrite removeDupIdentity; intuition.
									cbn.
									destruct (beqAddr pdinsertion sh1entryaddr) eqn:beqpdsh1; try(exfalso ; congruence).
									---- (* pdinsertion = sh1entryaddr *)
											rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdsh1.
											rewrite <- beqpdsh1 in *.
											unfold isPDT in *.
											exfalso ; congruence.
									---- (* pdinsertion <> sh1entryaddr *)
											rewrite Hs in HcheckChilds.
											cbn in HcheckChilds.
											rewrite <- beqAddrFalse in *.
											rewrite beqAddrTrue in HcheckChilds.
											repeat rewrite removeDupIdentity in HcheckChilds; intuition.
											cbn in HcheckChilds.
											destruct (beqAddr sceaddr sh1entryaddr) eqn:Hf; try(exfalso ; congruence).
											destruct (beqAddr newBlockEntryAddr sh1entryaddr) eqn:Hff; try(exfalso ; congruence).
											rewrite <- DependentTypeLemmas.beqAddrTrue in Hff. congruence.
											destruct (beqAddr newBlockEntryAddr sceaddr) eqn:Hfff; try(exfalso ; congruence).
											rewrite <- DependentTypeLemmas.beqAddrTrue in Hfff. congruence.
											cbn in HcheckChilds.

											destruct (beqAddr newBlockEntryAddr sh1entryaddr) eqn:Hfffff; try(exfalso ; congruence).
											do 7 rewrite removeDupIdentity in HcheckChilds; intuition.
											destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hffff; try(exfalso ; congruence).
											rewrite <- DependentTypeLemmas.beqAddrTrue in Hffff. congruence.
											cbn in HcheckChilds.
											destruct (beqAddr pdinsertion sh1entryaddr) eqn:Hffffff; try(exfalso ; congruence).
											rewrite beqAddrTrue in HcheckChilds.
											do 3 rewrite removeDupIdentity in HcheckChilds; intuition.
											rewrite Hsh1s0 in HcheckChilds.
											(* expected contradiction *)
											congruence.
						*** (* 2) newBlockEntryAddr <> idPDchild *)
								assert(HidPDchildEq : lookup idPDchild (memory s) beqAddr = lookup idPDchild (memory s0) beqAddr).
								{
									rewrite Hs.
									cbn.
									rewrite beqAddrTrue.
									rewrite beqsceidpd.
									assert(HpdnewNotEq : beqAddr pdinsertion newBlockEntryAddr = false)
											by intuition.
									assert(HnewsceNotEq : beqAddr newBlockEntryAddr sceaddr = false)
											by intuition.
									rewrite HpdnewNotEq.
									cbn.
									rewrite HnewsceNotEq. cbn. rewrite beqnewidpd.
									rewrite <- beqAddrFalse in *.
									repeat rewrite removeDupIdentity ; intuition.
									cbn.
									destruct (beqAddr pdinsertion idPDchild) eqn:Hf; try(exfalso ; congruence).
									rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
									rewrite beqAddrTrue.
									destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hff; try(exfalso ; congruence).
									rewrite <- DependentTypeLemmas.beqAddrTrue in Hff. congruence.
									cbn. rewrite Hf.
									repeat rewrite removeDupIdentity ; intuition.
								}
								rewrite HidPDchildEq.
								rewrite HidPDs0.
								rewrite HidPDs0 in HidPDchildEq.
								rewrite Hlookup in HidPDchildEq.
								injection HidPDchildEq ; intro bentryEq.
								(* PDflag can only be true for anything except the modified state, because
										the only candidate is newBlockEntryAddr which was a free slot so
										flag is null -> contra*)
								destruct Hcons0. (* extract the flag information at s0 *)
								{ rewrite Hs in HcheckChilds.
									cbn in HcheckChilds.
									rewrite <- beqAddrFalse in *.
									rewrite beqAddrTrue in HcheckChilds.
									destruct (beqAddr sceaddr sh1entryaddr) eqn:Hf; try(exfalso ; congruence).
									rewrite <- beqAddrFalse in *.
									cbn in HcheckChilds.
									destruct (beqAddr newBlockEntryAddr sceaddr) eqn:Hff; try(exfalso ; congruence).
									rewrite <- DependentTypeLemmas.beqAddrTrue in Hff. congruence.
									cbn in HcheckChilds.
									destruct (beqAddr newBlockEntryAddr sh1entryaddr) eqn:Hfff; try(exfalso ; congruence).
									cbn in HcheckChilds.
									rewrite <- beqAddrFalse in *.
									do 7 rewrite removeDupIdentity in HcheckChilds; intuition.
									destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hffff; try(exfalso ; congruence).
									rewrite <- DependentTypeLemmas.beqAddrTrue in Hffff. congruence.
									cbn in HcheckChilds.
									destruct (beqAddr pdinsertion sh1entryaddr) eqn:Hfffff; try(exfalso ; congruence).
									cbn in HcheckChilds.
									rewrite beqAddrTrue in HcheckChilds.
									rewrite <- beqAddrFalse in *.
									do 3 rewrite removeDupIdentity in HcheckChilds; intuition.
									rewrite Hsh1s0 in HcheckChilds.
									congruence.
									unfold sh1entryAddr.
									rewrite HidPDs0.
									unfold sh1entryAddr in Hsh1entryaddr.
									rewrite Hlookup in Hsh1entryaddr.
									assumption.
								}
								unfold bentryStartAddr in H29. unfold entryPDT in H29.
								rewrite HidPDs0 in H29. intuition.
								rewrite <- H30 in *.
							(* explore all possible values for idPdchild's startAddr
									- only possible value is pdinsertion because must be a PDT
									-> ok in this case, it means another entry in s0 points to it *)
							rewrite Hs. cbn.
							rewrite beqAddrTrue.
							destruct (beqAddr sceaddr x0) eqn:beqscex0; try(exfalso ; congruence).
							- (* sceaddr = x0 *)
								rewrite <- DependentTypeLemmas.beqAddrTrue in beqscex0.
								rewrite <- beqscex0 in *.
								apply isSCELookupEq in HSCE. destruct HSCE as [sceaddr' HSCE].
								rewrite HSCE in *; congruence.
							-	(* sceaddr <> x0 *)
								rewrite <- beqscex0 in *. (* newblock <> sce *)
								cbn.
								destruct (beqAddr newBlockEntryAddr sceaddr) eqn:beqnewsce; try(exfalso ; congruence).
								cbn.
								destruct (beqAddr newBlockEntryAddr x0) eqn:beqnewx0; try(exfalso ; congruence).
								-- (* newBlockEntryAddr = x0 *)
										rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewx0.
										rewrite <- beqnewx0 in *. rewrite H2 in H31.
										congruence.
								-- (* newBlockEntryAddr <> x0 *)
										rewrite <- beqAddrFalse in *.
										repeat rewrite removeDupIdentity; intuition.
										cbn.
										destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:beqpdnew; try(exfalso ; congruence).
										cbn.
										destruct (beqAddr pdinsertion x0) eqn:beqpdx0; try(exfalso ; congruence).
										--- (* pdinsertion = x0 *)
												rewrite bentryEq. intuition.
										--- (* pdinsertion <> x0 *)
												rewrite beqAddrTrue.
												rewrite <- beqAddrFalse in *.
												repeat rewrite removeDupIdentity; intuition.
												destruct (lookup x0 (memory s0) beqAddr) eqn:Hlookupx0 ; try (exfalso ; congruence).
												destruct v0 eqn:Hv0 ; try (exfalso ; congruence).
												rewrite bentryEq. intuition.
} (* end PDTIfPDFlag*)

split.
	{ (* nullAddrExists s *)
		assert(Hcons0 : nullAddrExists s0) by (unfold consistency in * ; intuition).
		unfold nullAddrExists in Hcons0.
		unfold isPADDR in Hcons0.

		unfold nullAddrExists.
		unfold isPADDR.

		destruct (lookup nullAddr (memory s0) beqAddr) eqn:Hlookup ; try (exfalso ; congruence).
		destruct v eqn:Hv ; try (exfalso ; congruence).

		destruct (beqAddr sceaddr newBlockEntryAddr) eqn:beqscenew; try(exfalso ; congruence).
		-	(* sceaddr = newBlockEntryAddr *)
			rewrite <- DependentTypeLemmas.beqAddrTrue in beqscenew.
			rewrite <- beqscenew in *.
			unfold isSCE in *.
			unfold isBE in *.
			destruct (lookup sceaddr (memory s0) beqAddr) eqn:Hlookup'; try (exfalso ; congruence).
			destruct v0 eqn:Hv' ; try (exfalso ; congruence).
		-	(* sceaddr <> newBlockEntryAddr *)
		(* check all possible values of nullAddr in s -> nothing changed a PADDR
				so nullAddrExists at s0 prevales *)
		destruct (beqAddr pdinsertion nullAddr) eqn:beqpdnull; try(exfalso ; congruence).
		*	(* pdinsertion = nullAddr *)
			rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdnull.
			rewrite beqpdnull in *.
			unfold isPDT in *.
			rewrite Hlookup in *.
			exfalso ; congruence.
		* (* pdinsertion <> nullAddr *)
			destruct (beqAddr sceaddr nullAddr) eqn:beqscenull; try(exfalso ; congruence).
			**	(* sceaddr = nullAddr *)
				rewrite <- DependentTypeLemmas.beqAddrTrue in beqscenull.
				unfold isSCE in *.
				rewrite <- beqscenull in *.
				rewrite Hlookup in *.
				exfalso; congruence.
			** (* sceaddr <> nullAddr *)
						destruct (beqAddr newBlockEntryAddr nullAddr) eqn:beqnewnull; try(exfalso ; congruence).
						*** (* newBlockEntryAddr = nullAddr *)
							rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewnull.
							unfold isBE in *.
							rewrite <- beqnewnull in *.
							rewrite Hlookup in *.
							exfalso; congruence.
						*** (* newBlockEntryAddr <> nullAddr *)
							rewrite Hs.
							simpl.
							destruct (beqAddr sceaddr nullAddr) eqn:Hf; try(exfalso ; congruence).
							rewrite beqAddrTrue.
							rewrite beqAddrSym in beqscenew.
							rewrite beqscenew.
							rewrite beqAddrTrue.
							rewrite <- beqAddrFalse in *.
							simpl.
							rewrite beqAddrFalse in beqnewnull.
							rewrite beqnewnull.
							simpl.
							rewrite beqAddrFalse in *.
							assert(HpdnewNotEq : beqAddr pdinsertion newBlockEntryAddr = false)
									by intuition.
							rewrite HpdnewNotEq.
							rewrite <- beqAddrFalse in *.
							repeat rewrite removeDupIdentity ; intuition.
							simpl.
							destruct (beqAddr pdinsertion nullAddr) eqn:Hff; try(exfalso ; congruence).
							contradict beqpdnull. { rewrite DependentTypeLemmas.beqAddrTrue. intuition. }
							repeat rewrite removeDupIdentity ; intuition.
							rewrite Hlookup. trivial.
} (* end of nullAddrExists *)
split.
	{ (* FirstFreeSlotPointerIsBEAndFreeSlot s *)
		assert(Hcons0 : FirstFreeSlotPointerIsBEAndFreeSlot s0) by (unfold consistency in * ; intuition).
		unfold FirstFreeSlotPointerIsBEAndFreeSlot in Hcons0.

		unfold FirstFreeSlotPointerIsBEAndFreeSlot.
		intros entryaddrpd entrypd Hentrypd Hfirstfreeslotentrypd.

		(* check all possible values for entryaddrpd in the modified state s
				-> only possible is pdinsertion
			1) if entryaddrpd == pdinsertion :
					- newBlockEntryAddr was firstfreeslot at s0 and newFirstFreeSlotAddr is
						the new firstfreeslot at s
					- check all possible values for (firstfree pdinsertion) in the modified state s
							1.1) only possible is newblockEntryAddr but it can't be a
									FreeSlot because :
									we know newFirstFreeSlotAddr = endAddr newBlockEntryAddr
									1.1.1) BUT if newFirstFreeSlotAddr = newBlockEntryAddr
													-> newBlockEntryAddr = endAddr newBlockEntryAddr
													-> cycles in the free slots list -> impossible by consistency
									1.1.1.2)	newFirstFreeSlotAddr s = newFirstFreeSlot s0
													-> leads to s0 and isBE and isFreeSlot at s0 -> OK
			2) if entryaddrpd <> pdinsertion :
					- newBlockEntryAddr and newFirstFreeSlotAddr do not relate to entryaddrpd
							(firstfree pdinsertion <> firstfree entryaddrpd)
							-> newBlockEntryAddr <> (firstfree entryaddrpd) and
									newFirstFreeSlotAddr <> (firstfree entryaddrpd)
						since all the free slots list must be disjoint by consistency
					- check all possible values for (firstfreeslot entrypd) in the modified state s
							-> nothing possible -> leads to s0 because -> OK
*)
		(* Check all values except pdinsertion *)
		destruct (beqAddr sceaddr entryaddrpd) eqn:beqsceentry; try(exfalso ; congruence).
		-	(* sceaddr = entryaddrpd *)
			rewrite <- DependentTypeLemmas.beqAddrTrue in beqsceentry.
			rewrite <- beqsceentry in *.
			unfold isSCE in *.
			rewrite Hentrypd in *.
			exfalso ; congruence.
		-	(* sceaddr <> entryaddrpd *)
			destruct (beqAddr newBlockEntryAddr entryaddrpd) eqn:beqnewblockentry; try(exfalso ; congruence).
			-- (* newBlockEntryAddr = entryaddrpd *)
					rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewblockentry.
					rewrite <- beqnewblockentry in *.
					unfold isBE in *.
					rewrite Hentrypd in *.
					exfalso ; congruence.
			-- (* newBlockEntryAddr <> entryaddrpd *)
					destruct (beqAddr pdinsertion entryaddrpd) eqn:beqpdentry; try(exfalso ; congruence).
					--- (* pdinsertion = entryaddrpd *)
							rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdentry.
							rewrite <- beqpdentry in *.
							assert(Hpdinsertions0 : lookup pdinsertion (memory s0) beqAddr = Some (PDT pdentry))
								by intuition.
							specialize (Hcons0 pdinsertion pdentry Hpdinsertions0). Search pdentry.
							destruct Hcons0 as [HRR HHH].
							* unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in H20.
							unfold bentryEndAddr in *. rewrite H2 in *.
							assert(HFirstFreeSlotPtNotNulls0 : FirstFreeSlotPointerNotNullEq s0)
									by (unfold consistency in * ; intuition).
							pose (H_slotnotnulls0 := HFirstFreeSlotPtNotNulls0 pdinsertion currnbfreeslots).
							destruct H_slotnotnulls0 as [Hleft Hright].
							pose (H_conj := conj H23 H25). (* pdentryNbFreeSlots pdinsertion currnbfreeslots s0 /\ currnbfreeslots > 0 *)
							destruct Hleft as [Hslotpointer Hnull]. assumption.
							unfold pdentryFirstFreeSlot in Hnull.
							rewrite Hpdinsertions0 in Hnull. destruct Hnull. congruence.
							* (* rewrite (firstfreeslot pdentry at s0) = newBlockEntryAddr *)
								assert(HnewFirstFrees0 : firstfreeslot pdentry = newBlockEntryAddr).
								{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
								assert(HnewFirstEq : bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s0)
									by intuition.
								rewrite HnewFirstFrees0 in *.
								unfold bentryEndAddr in HnewFirstEq. rewrite H2 in *.
								(* develop chainedFreeSlots at s0 *)
								assert(Hpdeq : entrypd = pdentry1).
								{ rewrite H13 in *. (*lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry1) *)
									injection Hentrypd. intuition. }
								rewrite Hpdeq in *.
								assert(HnewFirstFree : firstfreeslot pdentry1 = newFirstFreeSlotAddr).
								{ rewrite H14. cbn. rewrite H15. cbn. reflexivity. }
								rewrite HnewFirstFree in *.
								assert(HchainedFreeSlots : chainedFreeSlots s0)
										by (unfold consistency in * ; intuition).
								assert(HbentryEndAddrNewFirst : bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s0)
									by intuition.
								specialize(HchainedFreeSlots newBlockEntryAddr newFirstFreeSlotAddr HHH Hfirstfreeslotentrypd HbentryEndAddrNewFirst).
								destruct (beqAddr sceaddr newFirstFreeSlotAddr) eqn:beqscefirstfree; try(exfalso ; congruence).
								rewrite <- DependentTypeLemmas.beqAddrTrue in beqscefirstfree.
						---- (* sceaddr = newFirstFreeSlotAddr *)
									rewrite <- beqscefirstfree in *.
									assert(HSCEs0 : isSCE sceaddr s0) by intuition.
									apply isSCELookupEq in HSCEs0. destruct HSCEs0 as [Hsceaddr Hscelookup].
									unfold isFreeSlot in HchainedFreeSlots.
									rewrite Hscelookup in *. exfalso ; congruence.
						---- (* sceaddr <> newFirstFreeSlotAddr *)
							destruct (beqAddr pdinsertion newFirstFreeSlotAddr) eqn:beqpdfirstfree; try(exfalso ; congruence).
							rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdfirstfree.
							-----	(* pdinsertion = newFirstFreeSlotAddr *)
									rewrite beqpdfirstfree in *.
									unfold isFreeSlot in HchainedFreeSlots.
									rewrite Hpdinsertions0 in *. exfalso ; congruence.
							----- (* pdinsertion <> newFirstFreeSlotAddr *)
										(* remaining is newBlockEntryAddr -> use noDup*)
										destruct (beqAddr newBlockEntryAddr newFirstFreeSlotAddr) eqn:beqnewfirstfree; try(exfalso ; congruence).
										rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewfirstfree.
										------ (* newBlockEntryAddr = newFirstFreeSlotAddr *)
														assert(HNoDupFreeSlotsLists0 : NoDupInFreeSlotsList s0)
															by (unfold consistency in * ; intuition).
														unfold NoDupInFreeSlotsList in *.
														pose (H_NoDups0 := HNoDupFreeSlotsLists0 pdinsertion pdentry Hpdinsertions0).
														unfold getFreeSlotsList in H_NoDups0.
														rewrite Hpdinsertions0 in *. rewrite HnewFirstFrees0 in *.
														rewrite FreeSlotsListRec_unroll in H_NoDups0.
														unfold getFreeSlotsListAux in *.
														rewrite H2 in *. rewrite <- HnewFirstEq in *.
														rewrite beqAddrFalse in Hfirstfreeslotentrypd.

														destruct H_NoDups0 as [optionlist H_NoDups0].

														induction MAL.N. (* false induction because of fixpoint constraints *)
														** (* N=0 -> NotWellFormed *)
															destruct H_NoDups0 as [HoptionList (HwellFormedList& HNoDupList)].
															rewrite HoptionList in *.
															cbn in HwellFormedList.
															congruence.
														** (* N>0 *)
															clear IHn.
															assert(eqbNewFirstFreeNotNull : PeanoNat.Nat.eqb newFirstFreeSlotAddr nullAddr = false)
															 by intuition.
															rewrite eqbNewFirstFreeNotNull in *.
															(* 2nd recursion -> show cycle *)
															rewrite <- beqnewfirstfree in *.
															rewrite FreeSlotsListRec_unroll in H_NoDups0.
															unfold getFreeSlotsListAux in *.
															rewrite H2 in *. rewrite <- HnewFirstEq in *.
															induction n. (* false induction because of fixpoint constraints *)
														*** (* N=0 -> NotWellFormed *)
															destruct H_NoDups0 as [HoptionList (HwellFormedList& HNoDupList)].
															rewrite HoptionList in *.
															cbn in HwellFormedList.
															congruence.
														*** (* N>0 -> cycle so contradictions *)
															clear IHn.
															rewrite eqbNewFirstFreeNotNull in *.
															destruct H_NoDups0 as [HoptionList (HwellFormedList& HNoDupList)].
															rewrite HoptionList in *.
															cbn in HNoDupList.
															rewrite NoDup_cons_iff in HNoDupList.
															cbn in HNoDupList.
															contradict HNoDupList. intuition.
									------ (* newBlockEntryAddr <> newFirstFreeSlotAddr *)
													assert(HfirstfreeEq : lookup newFirstFreeSlotAddr (memory s) beqAddr = lookup newFirstFreeSlotAddr (memory s0) beqAddr).
													{
														rewrite Hs.
														rewrite <- beqAddrFalse in *.
														cbn.
														rewrite beqAddrTrue.
														destruct (beqAddr sceaddr newFirstFreeSlotAddr) eqn:Hf; try(exfalso ; congruence).
														rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
														(* sceaddr <> newFirstFreeSlotAddr *)
														destruct (beqAddr newBlockEntryAddr sceaddr) eqn:Hff; try(exfalso ; congruence).
														rewrite <- DependentTypeLemmas.beqAddrTrue in Hff. congruence.
														cbn. rewrite beqAddrTrue.
														destruct (beqAddr newBlockEntryAddr newFirstFreeSlotAddr) eqn:Hfff; try(exfalso ; congruence).
														rewrite <- DependentTypeLemmas.beqAddrTrue in Hfff. congruence.
														cbn.
														destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hffff; try(exfalso ; congruence).
														rewrite <- DependentTypeLemmas.beqAddrTrue in Hffff. congruence.
														rewrite <- beqAddrFalse in *.
														repeat rewrite removeDupIdentity; intuition.
														cbn.
														destruct (beqAddr pdinsertion newFirstFreeSlotAddr) eqn:Hfffff; try(exfalso ; congruence).
														rewrite <- DependentTypeLemmas.beqAddrTrue in Hfffff. congruence.
														repeat rewrite removeDupIdentity; intuition.
													}
													split.
													** (* isBE *)
														unfold isBE. rewrite HfirstfreeEq.
														unfold isFreeSlot in HchainedFreeSlots.
														destruct (lookup newFirstFreeSlotAddr (memory s0) beqAddr) eqn:Hlookupfirst ; try(exfalso ; congruence).
														destruct v eqn:Hv ; try(exfalso ; congruence).
														trivial.
													** (* isFreeSlot *)
															unfold isFreeSlot. rewrite HfirstfreeEq.
															unfold isFreeSlot in HchainedFreeSlots.
															destruct (lookup newFirstFreeSlotAddr (memory s0) beqAddr) eqn:Hlookupfirst ; try(exfalso ; congruence).
															destruct v eqn:Hv ; try(exfalso ; congruence).

															assert(HnewFirstFreeSh1 : lookup (CPaddr (newFirstFreeSlotAddr + sh1offset)) (memory s) beqAddr = lookup (CPaddr (newFirstFreeSlotAddr + sh1offset)) (memory s0) beqAddr).
															{ rewrite Hs.
																cbn. rewrite beqAddrTrue.
																destruct (beqAddr sceaddr (CPaddr (newFirstFreeSlotAddr + sh1offset))) eqn:beqscenewsh1 ; try(exfalso ; congruence).
																- (* sce = (CPaddr (newFirstFreeSlotAddr + sh1offset)) *)
																	rewrite <- DependentTypeLemmas.beqAddrTrue in beqscenewsh1.
																	rewrite <- beqscenewsh1 in *.
																	unfold isSCE in *.
																	destruct (lookup sceaddr (memory s0) beqAddr) eqn:Hf; try(exfalso ; congruence).
																	destruct v0 eqn:Hv0 ; try(exfalso ; congruence).
																- (* sce <> (CPaddr (newFirstFreeSlotAddr + sh1offset)) *)
																	destruct (beqAddr newBlockEntryAddr sceaddr) eqn:beqnewsce ; try(exfalso ; congruence).
																	cbn.
																	destruct (beqAddr newBlockEntryAddr (CPaddr (newFirstFreeSlotAddr + sh1offset))) eqn:beqnewfirstfreesh1 ; try(exfalso ; congruence).
																	-- (* newBlockEntryAddr = (CPaddr (newFirstFreeSlotAddr + sh1offset)) *)
																		rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewfirstfreesh1.
																		rewrite <- beqnewfirstfreesh1 in *.
																		unfold isBE in *.
																		destruct (lookup newBlockEntryAddr (memory s0) beqAddr) eqn:Hf; try(exfalso ; congruence).
																		destruct v0 eqn:Hv0 ; try(exfalso ; congruence).
																	-- (* newBlockEntryAddr <> (CPaddr (newFirstFreeSlotAddr + sh1offset)) *)
																			cbn.
																			rewrite <- beqAddrFalse in *.
																			repeat rewrite removeDupIdentity; intuition.
																			cbn.
																			destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hfffff; try(exfalso ; congruence).
																			rewrite <- DependentTypeLemmas.beqAddrTrue in Hfffff. congruence.
																			repeat rewrite removeDupIdentity; intuition.
																			cbn.
																			destruct (beqAddr pdinsertion (CPaddr (newFirstFreeSlotAddr + sh1offset))) eqn:beqpdfirstfreesh1 ; try(exfalso ; congruence).
																			--- (* pdinsertion = (CPaddr (newFirstFreeSlotAddr + sh1offset)) *)
																					rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdfirstfreesh1.
																					rewrite <- beqpdfirstfreesh1 in *.
																					unfold isPDT in *.
																					destruct (lookup pdinsertion (memory s0) beqAddr) eqn:Hf; try(exfalso ; congruence).
																					destruct v0 eqn:Hv0 ; try(exfalso ; congruence).
																			--- (* pdinsertion <> (CPaddr (newFirstFreeSlotAddr + sh1offset)) *)
																					cbn. rewrite beqAddrTrue.
																					rewrite <- beqAddrFalse in *.
																					repeat rewrite removeDupIdentity; intuition.
																	}
																	rewrite HnewFirstFreeSh1.
																	destruct (lookup (CPaddr (newFirstFreeSlotAddr + sh1offset)) (memory s0) beqAddr) eqn:Hlookupfirstsh1 ; try(exfalso ; congruence).
																	destruct v0 eqn:Hv0 ; try(exfalso ; congruence).

																	assert(HnewFirstFreeSCE : lookup (CPaddr (newFirstFreeSlotAddr + scoffset)) (memory s) beqAddr = lookup (CPaddr (newFirstFreeSlotAddr + scoffset)) (memory s0) beqAddr).
																	{ rewrite Hs.
																		cbn. rewrite beqAddrTrue.
																		destruct (beqAddr sceaddr (CPaddr (newFirstFreeSlotAddr + scoffset))) eqn:beqscenewsc ; try(exfalso ; congruence).
																		- (* sce = (CPaddr (newFirstFreeSlotAddr + scoffset)) *)
																			(* can't discriminate by type, must do by showing it must be equal to newBlockEntryAddr and creates a contradiction *)
																			rewrite <- DependentTypeLemmas.beqAddrTrue in beqscenewsc.
																			rewrite <- beqscenewsc in *.
																			unfold isFreeSlot in HHH.
																			rewrite H11 in *.
																			assert(HnullAddrExistss0 : nullAddrExists s0)
																					by (unfold consistency in *; intuition).
																			unfold nullAddrExists in *. unfold isPADDR in *.
																			unfold CPaddr in beqscenewsc.
																			destruct (le_dec (newBlockEntryAddr + scoffset) maxAddr) eqn:Hj.
																			* destruct (le_dec (newFirstFreeSlotAddr + scoffset) maxAddr) eqn:Hk.
																				** simpl in *.
																					inversion beqscenewsc as [Heq].
																					rewrite PeanoNat.Nat.add_cancel_r in Heq.
																					rewrite <- beqAddrFalse in beqnewfirstfree.
																					apply CPaddrInjectionNat in Heq.
																					repeat rewrite paddrEqId in Heq.
																					congruence.
																				** inversion beqscenewsc as [Heq].
																					rewrite Heq in *.
																					rewrite <- nullAddrIs0 in *.
																					rewrite <- beqAddrFalse in H26. (* newBlockEntryAddr <> nullAddr *)
																					destruct (lookup nullAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
																					destruct v1 ; try(exfalso ; congruence).
																			* assert(Heq : CPaddr(newBlockEntryAddr + scoffset) = nullAddr).
																				{ rewrite nullAddrIs0.
																					unfold CPaddr. rewrite Hj.
																					destruct (le_dec 0 maxAddr) ; intuition.
																					f_equal. apply proof_irrelevance.
																				}
																				rewrite Heq in *.
																				destruct (lookup nullAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
																				destruct v1 ; try(exfalso ; congruence).
																 	- (* sce <> (CPaddr (newFirstFreeSlotAddr + scoffset)) *)
																		destruct (beqAddr newBlockEntryAddr sceaddr) eqn:beqnewsce ; try(exfalso ; congruence).
																		cbn.
																		destruct (beqAddr newBlockEntryAddr (CPaddr (newFirstFreeSlotAddr + scoffset))) eqn:beqnewfirstfreesc ; try(exfalso ; congruence).
																		-- (* newBlockEntryAddr = (CPaddr (newFirstFreeSlotAddr + scoffset)) *)
																			rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewfirstfreesc.
																			rewrite <- beqnewfirstfreesc in *.
																			unfold isBE in *.
																			destruct (lookup newBlockEntryAddr (memory s0) beqAddr) eqn:Hf; try(exfalso ; congruence).
																			destruct v1 eqn:Hv1 ; try(exfalso ; congruence).
																		-- (* newBlockEntryAddr <> (CPaddr (newFirstFreeSlotAddr + scoffset)) *)
																				cbn.
																				rewrite <- beqAddrFalse in *.
																				repeat rewrite removeDupIdentity; intuition.
																				cbn.
																				destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hfffff; try(exfalso ; congruence).
																				rewrite <- DependentTypeLemmas.beqAddrTrue in Hfffff. congruence.
																				repeat rewrite removeDupIdentity; intuition.
																				cbn.
																				destruct (beqAddr pdinsertion (CPaddr (newFirstFreeSlotAddr + scoffset))) eqn:beqpdfirstfreesc ; try(exfalso ; congruence).
																				--- (* pdinsertion = (CPaddr (newFirstFreeSlotAddr + scoffset)) *)
																						rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdfirstfreesc.
																						rewrite <- beqpdfirstfreesc in *.
																						unfold isPDT in *.
																						destruct (lookup pdinsertion (memory s0) beqAddr) eqn:Hf; try(exfalso ; congruence).
																						destruct v1 eqn:Hv1 ; try(exfalso ; congruence).
																				--- (* pdinsertion <> (CPaddr (newFirstFreeSlotAddr + scoffset)) *)
																						cbn. rewrite beqAddrTrue.
																						rewrite <- beqAddrFalse in *.
																						repeat rewrite removeDupIdentity; intuition.
																}
																rewrite HnewFirstFreeSCE.
																destruct (lookup (CPaddr (newFirstFreeSlotAddr + scoffset))
																		      (memory s0) beqAddr) eqn:Hlookupfirstsc ; try(exfalso ; congruence).
																destruct v1 eqn:Hv1 ; try(exfalso ; congruence).
																intuition.
							--- (* pdinsertion <> entryaddrpd *)
									assert(HlookupEq : lookup entryaddrpd (memory s) beqAddr = lookup entryaddrpd (memory s0) beqAddr).
									{ rewrite Hs.
										cbn. rewrite beqAddrTrue.
										destruct (beqAddr sceaddr entryaddrpd) eqn:beqsceentrypd ; try(exfalso ; congruence).
										destruct (beqAddr newBlockEntryAddr sceaddr) eqn:beqnewsce ; try(exfalso ; congruence).
										cbn.
										destruct (beqAddr newBlockEntryAddr entryaddrpd) eqn:beqnewentrypd ; try(exfalso ; congruence).
										destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:beqpdnewblock ; try(exfalso ; congruence).
										rewrite <- beqAddrFalse in *.
										rewrite beqAddrTrue.
										repeat rewrite removeDupIdentity ; intuition.
										cbn.
										destruct (beqAddr pdinsertion entryaddrpd) eqn:beqpdentrypd ; try(exfalso ; congruence).
										rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdentrypd.
										rewrite <- beqpdentrypd in *.
										congruence.
										repeat rewrite removeDupIdentity ; intuition.
									}
									assert(Hentrypds0 : lookup entryaddrpd (memory s0) beqAddr = Some (PDT entrypd)).
									{ rewrite <- HlookupEq. intuition. }
									specialize (Hcons0 entryaddrpd entrypd Hentrypds0 Hfirstfreeslotentrypd).
									assert(HnewFirstEq : bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s0)
										by intuition.
									unfold bentryEndAddr in HnewFirstEq. rewrite H2 in *.
									destruct (beqAddr sceaddr (firstfreeslot entrypd)) eqn:beqscefirstfree; try(exfalso ; congruence).
									rewrite <- DependentTypeLemmas.beqAddrTrue in beqscefirstfree.
									---- (* sceaddr = firstfreeslot entrypd *)
												rewrite <- beqscefirstfree in *.
												assert(HSCEs0 : isSCE sceaddr s0) by intuition.
												apply isSCELookupEq in HSCEs0. destruct HSCEs0 as [Hsceaddr Hscelookup].
												unfold isBE in Hcons0. rewrite Hscelookup in *.
												intuition.
									---- (* sceaddr <> firstfreeslot entrypd *)
										assert(HPDTs0 : isPDT pdinsertion s0) by intuition.
										destruct (beqAddr pdinsertion (firstfreeslot entrypd)) eqn:beqpdfirstfree; try(exfalso ; congruence).
										rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdfirstfree.
										-----	(* pdinsertion = firstfreeslot entrypd *)
												rewrite beqpdfirstfree in *.
												unfold isBE in Hcons0.
												apply isPDTLookupEq in HPDTs0. destruct HPDTs0 as [Hpdaddr Hpdlookup].
												rewrite Hpdlookup in *.
												intuition.
										----- (* pdinsertion <> firstfreeslot entrypd *)
													(* remaining is newBlockEntryAddr -> use Disjoint *)
													destruct (beqAddr newBlockEntryAddr (firstfreeslot entrypd)) eqn:beqnewfirstfree; try(exfalso ; congruence).
													rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewfirstfree.
													------ (* newBlockEntryAddr = firstfreeslot entrypd *)
															(* Case : other pdentry but firstfreeslot points to newBlockEntryAddr anyways -> impossible *)
															assert(Hfreeslotsdisjoints0 : DisjointFreeSlotsLists s0)
																by (unfold consistency in *; intuition).
															unfold DisjointFreeSlotsLists in *.
															assert(Hpdinsertions0 : lookup pdinsertion (memory s0) beqAddr = Some (PDT pdentry))
																	by intuition.
															assert(HPDTentrypds0 : isPDT entryaddrpd s0).
															{ unfold isPDT. rewrite Hentrypds0. trivial. }
															rewrite <- beqAddrFalse in beqpdentry.
															pose (H_Disjoints0 := Hfreeslotsdisjoints0 pdinsertion entryaddrpd HPDTs0 HPDTentrypds0 beqpdentry).
															destruct H_Disjoints0 as [listoption1 (listoption2 & H_Disjoints0)].
															destruct H_Disjoints0 as [Hlistoption1 (HwellFormedList1 & (Hlistoption2 & (HwellFormedList2 & H_Disjoints0)))].
															unfold getFreeSlotsList in Hlistoption1.
															unfold getFreeSlotsList in Hlistoption2.
															rewrite Hpdinsertions0 in *.
															rewrite Hentrypds0 in *.
															rewrite <- beqnewfirstfree in *.
															assert(HnewFirstFrees0 : firstfreeslot pdentry = newBlockEntryAddr).
															{ unfold pdentryFirstFreeSlot in *. rewrite Hpdinsertions0 in *. intuition. }
			 													rewrite HnewFirstFrees0 in *.
																rewrite FreeSlotsListRec_unroll in Hlistoption1.
																rewrite FreeSlotsListRec_unroll in Hlistoption2.
																unfold getFreeSlotsListAux in *.
																rewrite H2 in *. rewrite <- HnewFirstEq in *.
																rewrite beqAddrFalse in Hfirstfreeslotentrypd.
																induction MAL.N. (* false induction because of fixpoint constraints *)
																** (* N=0 -> NotWellFormed *)
																	rewrite Hlistoption1 in *.
																	cbn in HwellFormedList1.
																	congruence.
																** (* N>0 *)
																	clear IHn. Search newFirstFreeSlotAddr.
																	destruct (PeanoNat.Nat.eqb newFirstFreeSlotAddr nullAddr) eqn:newIsNull.
																	*** rewrite Hlistoption1 in *.
																			cbn in HwellFormedList1.
																			rewrite Hlistoption2 in *.
																			cbn in HwellFormedList2.
																			cbn in H_Disjoints0.
																			unfold Lib.disjoint in H_Disjoints0.
																			specialize(H_Disjoints0 newBlockEntryAddr).
																			simpl in H_Disjoints0.
																			intuition.
																	*** rewrite Hlistoption1 in *.
																			cbn in HwellFormedList1.
																			rewrite Hlistoption2 in *.
																			cbn in HwellFormedList2.
																			cbn in H_Disjoints0.
																			unfold Lib.disjoint in H_Disjoints0.
																			specialize(H_Disjoints0 newBlockEntryAddr).
																			simpl in H_Disjoints0.
																			intuition.
												------ (* newBlockEntryAddr <> firstfreeslot entrypd *)
																assert(HfirstfreeEq : lookup (firstfreeslot entrypd) (memory s) beqAddr = lookup (firstfreeslot entrypd) (memory s0) beqAddr).
																{
																	rewrite Hs. cbn. rewrite beqAddrTrue.
																	destruct (beqAddr sceaddr (firstfreeslot entrypd)) eqn:scefirst ; try(exfalso ; congruence).
																	destruct (beqAddr newBlockEntryAddr sceaddr) eqn:newsce ; try(exfalso ; congruence).
																	rewrite beqAddrTrue.
																	cbn.
																	destruct (beqAddr newBlockEntryAddr (firstfreeslot entrypd)) eqn:newfirst ; try(exfalso ; congruence).
																	destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:pdnew ; try(exfalso ; congruence).
																	rewrite <- beqAddrFalse in *.
																	repeat rewrite removeDupIdentity ; intuition.
																	cbn.
																	destruct (beqAddr pdinsertion (firstfreeslot entrypd)) eqn:pdfirst ; try(exfalso ; congruence).
																	rewrite <- DependentTypeLemmas.beqAddrTrue in pdfirst.
																	congruence.
																	rewrite <- beqAddrFalse in *.
																	repeat rewrite removeDupIdentity ; intuition.
																}
																split.
																** (* isBE *)
																	unfold isBE. rewrite HfirstfreeEq. intuition.
																** (* isFreeSlot *)
																		unfold isFreeSlot. rewrite HfirstfreeEq.
																		unfold isFreeSlot in Hcons0. destruct Hcons0.
																		destruct (lookup (firstfreeslot entrypd) (memory s0) beqAddr) eqn:Hlookupfirst ; try(exfalso ; congruence).
																		destruct v eqn:Hv ; try(exfalso ; congruence).
																		(* DUP *)
																		assert(HnewFirstFreeSh1 : lookup (CPaddr (firstfreeslot entrypd + sh1offset)) (memory s) beqAddr = lookup (CPaddr (firstfreeslot entrypd + sh1offset)) (memory s0) beqAddr).
																		{ rewrite Hs.
																			cbn. rewrite beqAddrTrue.
																			destruct (beqAddr sceaddr (CPaddr (firstfreeslot entrypd + sh1offset))) eqn:beqscenewsh1 ; try(exfalso ; congruence).
																			- (* sce = (CPaddr (newFirstFreeSlotAddr + sh1offset)) *)
																				rewrite <- DependentTypeLemmas.beqAddrTrue in beqscenewsh1.
																				rewrite <- beqscenewsh1 in *.
																				unfold isSCE in *.
																				destruct (lookup sceaddr (memory s0) beqAddr) eqn:Hf; try(exfalso ; congruence).
																				destruct v0 eqn:Hv0 ; try(exfalso ; congruence).
																			- (* sce <> (CPaddr (newFirstFreeSlotAddr + sh1offset)) *)
																				destruct (beqAddr newBlockEntryAddr sceaddr) eqn:beqnewsce ; try(exfalso ; congruence).
																				cbn.
																				destruct (beqAddr newBlockEntryAddr (CPaddr (firstfreeslot entrypd + sh1offset))) eqn:beqnewfirstfreesh1 ; try(exfalso ; congruence).
																				-- (* newBlockEntryAddr = (CPaddr (newFirstFreeSlotAddr + sh1offset)) *)
																					rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewfirstfreesh1.
																					rewrite <- beqnewfirstfreesh1 in *.
																					unfold isBE in *.
																					destruct (lookup newBlockEntryAddr (memory s0) beqAddr) eqn:Hf; try(exfalso ; congruence).
																					destruct v0 eqn:Hv0 ; try(exfalso ; congruence).
																				-- (* newBlockEntryAddr <> (CPaddr (newFirstFreeSlotAddr + sh1offset)) *)
																						cbn.
																						rewrite <- beqAddrFalse in *.
																						repeat rewrite removeDupIdentity; intuition.
																						cbn.
																						destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hfffff; try(exfalso ; congruence).
																						rewrite <- DependentTypeLemmas.beqAddrTrue in Hfffff. congruence.
																						repeat rewrite removeDupIdentity; intuition.
																						cbn.
																						destruct (beqAddr pdinsertion (CPaddr (firstfreeslot entrypd + sh1offset))) eqn:beqpdfirstfreesh1 ; try(exfalso ; congruence).
																						--- (* pdinsertion = (CPaddr (newFirstFreeSlotAddr + sh1offset)) *)
																								rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdfirstfreesh1.
																								rewrite <- beqpdfirstfreesh1 in *.
																								unfold isPDT in *.
																								destruct (lookup pdinsertion (memory s0) beqAddr) eqn:Hf; try(exfalso ; congruence).
																								destruct v0 eqn:Hv0 ; try(exfalso ; congruence).
																						--- (* pdinsertion <> (CPaddr (newFirstFreeSlotAddr + sh1offset)) *)
																								cbn. rewrite beqAddrTrue.
																								rewrite <- beqAddrFalse in *.
																								repeat rewrite removeDupIdentity; intuition.
																				}
																				rewrite HnewFirstFreeSh1.
																				destruct (lookup (CPaddr (firstfreeslot entrypd + sh1offset)) (memory s0) beqAddr) eqn:Hlookupfirstsh1 ; try(exfalso ; congruence).
																				destruct v0 eqn:Hv0 ; try(exfalso ; congruence).

																				assert(HnewFirstFreeSCE : lookup (CPaddr (firstfreeslot entrypd + scoffset)) (memory s) beqAddr = lookup (CPaddr (firstfreeslot entrypd + scoffset)) (memory s0) beqAddr).
																				{ rewrite Hs.
																					cbn. rewrite beqAddrTrue.
																					destruct (beqAddr sceaddr (CPaddr (firstfreeslot entrypd + scoffset))) eqn:beqscenewsc ; try(exfalso ; congruence).
																					- (* sce = (CPaddr (newFirstFreeSlotAddr + scoffset)) *)
																						(* can't discriminate by type, must do by showing it must be equal to newBlockEntryAddr and creates a contradiction *)
																						rewrite <- DependentTypeLemmas.beqAddrTrue in beqscenewsc.
																						rewrite <- beqscenewsc in *.
																						rewrite H11 in *.
																						assert(HnullAddrExistss0 : nullAddrExists s0)
																								by (unfold consistency in *; intuition).
																						unfold nullAddrExists in *. unfold isPADDR in *.
																						unfold CPaddr in beqscenewsc.
																						destruct (le_dec (newBlockEntryAddr + scoffset) maxAddr) eqn:Hj.
																						* destruct (le_dec (firstfreeslot entrypd + scoffset) maxAddr) eqn:Hk.
																							** simpl in *.
																								inversion beqscenewsc as [Heq].
																								rewrite PeanoNat.Nat.add_cancel_r in Heq.
																								rewrite <- beqAddrFalse in beqnewfirstfree.
																								apply CPaddrInjectionNat in Heq.
																								repeat rewrite paddrEqId in Heq.
																								congruence.
																							** inversion beqscenewsc as [Heq].
																									rewrite Heq in *.
																									rewrite <- nullAddrIs0 in *.
																									rewrite <- beqAddrFalse in H26. (* newBlockEntryAddr <> nullAddr *)
																								destruct (lookup nullAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
																								destruct v1 ; try(exfalso ; congruence).
																						* assert(Heq : CPaddr(newBlockEntryAddr + scoffset) = nullAddr).
																							{ rewrite nullAddrIs0.
																								unfold CPaddr. rewrite Hj.
																								destruct (le_dec 0 maxAddr) ; intuition.
																								f_equal. apply proof_irrelevance.
																							}
																							rewrite Heq in *.
																							destruct (lookup nullAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
																							destruct v1 ; try(exfalso ; congruence).
																			 	- (* sce <> (CPaddr (newFirstFreeSlotAddr + scoffset)) *)
																						destruct (beqAddr newBlockEntryAddr sceaddr) eqn:beqnewsce ; try(exfalso ; congruence).
																						cbn.
																						destruct (beqAddr newBlockEntryAddr (CPaddr (firstfreeslot entrypd + scoffset))) eqn:beqnewfirstfreesc ; try(exfalso ; congruence).
																						-- (* newBlockEntryAddr = (CPaddr (newFirstFreeSlotAddr + scoffset)) *)
																							rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewfirstfreesc.
																							rewrite <- beqnewfirstfreesc in *.
																							unfold isBE in *.
																							destruct (lookup newBlockEntryAddr (memory s0) beqAddr) eqn:Hf; try(exfalso ; congruence).
																							destruct v1 eqn:Hv1 ; try(exfalso ; congruence).
																						-- (* newBlockEntryAddr <> (CPaddr (newFirstFreeSlotAddr + scoffset)) *)
																								cbn.
																								rewrite <- beqAddrFalse in *.
																								repeat rewrite removeDupIdentity; intuition.
																								cbn.
																								destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hfffff; try(exfalso ; congruence).
																								rewrite <- DependentTypeLemmas.beqAddrTrue in Hfffff. congruence.
																								repeat rewrite removeDupIdentity; intuition.
																								cbn.
																								destruct (beqAddr pdinsertion (CPaddr (firstfreeslot entrypd + scoffset))) eqn:beqpdfirstfreesc ; try(exfalso ; congruence).
																								--- (* pdinsertion = (CPaddr (newFirstFreeSlotAddr + scoffset)) *)
																										rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdfirstfreesc.
																										rewrite <- beqpdfirstfreesc in *.
																										unfold isPDT in *.
																										destruct (lookup pdinsertion (memory s0) beqAddr) eqn:Hf; try(exfalso ; congruence).
																										destruct v1 eqn:Hv1 ; try(exfalso ; congruence).
																								--- (* pdinsertion <> (CPaddr (newFirstFreeSlotAddr + scoffset)) *)
																										cbn. rewrite beqAddrTrue.
																										rewrite <- beqAddrFalse in *.
																										repeat rewrite removeDupIdentity; intuition.
																			}
																			rewrite HnewFirstFreeSCE.
																			destruct (lookup (CPaddr (firstfreeslot entrypd + scoffset))
																								(memory s0) beqAddr) eqn:Hlookupfirstsc ; try(exfalso ; congruence).
																			destruct v1 eqn:Hv1 ; try(exfalso ; congruence).
																			intuition.
} (* end of FirstFreeSlotPointerIsBEAndFreeSlot *)
split.
{ (* CurrentPartIsPDT s *)
	assert(Hcons0 : CurrentPartIsPDT s0) by (unfold consistency in * ; intuition).
	unfold CurrentPartIsPDT in Hcons0.

	intros entryaddrpd HcurrentPart.
	rewrite Hs in HcurrentPart.
	cbn in HcurrentPart.
	unfold isPDT.

	(* check all possible values for entryaddrpd in the modified state s
			-> only possible is pdinsertion
		1) if entryaddrpd == pdinsertion :
				- pdinsertion could be the current partition and insert in itself
				- we know isPDT pdinsertion s -> OK
		2) if entryaddrpd <> pdinsertion :
				- could be another partition inserting in pdinsertion
				- -> leads to s0 -> OK
*)
	specialize(Hcons0 entryaddrpd HcurrentPart).
	(* DUP *)
	(* Check all values except pdinsertion *)
	destruct (beqAddr sceaddr entryaddrpd) eqn:beqsceentry; try(exfalso ; congruence).
	-	(* sceaddr = entryaddrpd *)
		rewrite <- DependentTypeLemmas.beqAddrTrue in beqsceentry.
		rewrite <- beqsceentry in *.
		unfold isSCE in *.
		unfold isPDT in Hcons0.
		destruct (lookup sceaddr (memory s0) beqAddr) ; try(exfalso ; congruence).
		destruct v ; try(exfalso ; congruence).
	-	(* sceaddr <> entryaddrpd *)
		destruct (beqAddr newBlockEntryAddr entryaddrpd) eqn:beqnewblockentry; try(exfalso ; congruence).
		-- (* newBlockEntryAddr = entryaddrpd *)
			rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewblockentry.
			rewrite <- beqnewblockentry in *.
			unfold isBE in *.
			unfold isPDT in Hcons0.
			destruct (lookup newBlockEntryAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
			destruct v ; try(exfalso ; congruence).
		-- (* newBlockEntryAddr <> entryaddrpd *)
			rewrite Hs.
			cbn. rewrite beqAddrTrue.
			destruct (beqAddr sceaddr entryaddrpd) eqn:sceentrypd ; try(exfalso ; congruence).
			destruct (beqAddr newBlockEntryAddr sceaddr) eqn:newsce ; try(exfalso ; congruence).
			rewrite beqAddrTrue.
			cbn.
			destruct (beqAddr newBlockEntryAddr entryaddrpd) eqn:newentrypd ; try(exfalso ; congruence).
			destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:pdnew ; try(exfalso ; congruence).
			rewrite <- beqAddrFalse in *.
			repeat rewrite removeDupIdentity ; intuition.
			cbn.
			destruct (beqAddr pdinsertion entryaddrpd) eqn:pdentrypd ; try(exfalso ; congruence).
			--- (* pdinsertion = entryaddrpd *)
					trivial.
			---	(* pdinsertion <> entryaddrpd *)
					rewrite <- beqAddrFalse in *.
					repeat rewrite removeDupIdentity ; intuition.
} (* end of CurrentPartIsPDT *)
split.
{ (* wellFormedShadowCutIfBlockEntry s*)
	(* Almost DUP of wellFormedFstShadowIfBlockEntry *)
	unfold wellFormedShadowCutIfBlockEntry.
	intros pa HBEaddrs.

	(* Check all possible values for pa
			-> only possible is newBlockEntryAddr
			2) if pa == newBlockEntryAddr :
					-> exists scentryaddr in modified state -> OK
			3) if pa <> newBlockEntryAddr :
					- relates to another bentry than newBlockentryAddr
						that was not modified
						(either in the same structure or another)
					- pa + scoffset either is
								- scentryaddr -> newBlockEntryAddr = pa -> contradiction
								- some other entry -> leads to s0 -> OK
	*)

	(* 1) isBE pa s in hypothesis: eliminate impossible values for pa *)
	destruct (beqAddr pdinsertion pa) eqn:beqpdpa in HBEaddrs ; try(exfalso ; congruence).
	* (* pdinsertion = pa *)
		rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdpa.
		rewrite <- beqpdpa in *.
		unfold isPDT in *. unfold isBE in *. rewrite H in *.
		exfalso ; congruence.
	* (* pdinsertion <> pa *)
		destruct (beqAddr sceaddr pa) eqn:beqpasce in HBEaddrs ; try(exfalso ; congruence).
		** (* sceaddr = pa *)
				rewrite <- DependentTypeLemmas.beqAddrTrue in beqpasce.
				rewrite <- beqpasce in *.
				unfold isSCE in *. unfold isBE in *.
				destruct (lookup sceaddr (memory s) beqAddr) ; try(exfalso ; congruence).
				destruct v ; try(exfalso ; congruence).
		** (* sceaddr <> pa *)
						destruct (beqAddr newBlockEntryAddr pa) eqn:beqnewblockpa in HBEaddrs ; try(exfalso ; congruence).
						*** 	(* 2) treat special case where newBlockEntryAddr = pa *)
									rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewblockpa.
									rewrite <- beqnewblockpa in *.
									exists sceaddr. intuition.
						*** (* Partial DUP of FirstFreeSlotPointerIsBEAndFreeSlot *)
									(* 3) treat special case where pa is not equal to any modified entries*)
									(* newBlockEntryAddr <> pa *)
									(* eliminate impossible values for (CPaddr (pa + scoffset)) *)
										destruct (beqAddr sceaddr (CPaddr (pa + scoffset))) eqn:beqscenewsc.
										 - 	(* sceaddr = (CPaddr (pa + scoffset)) *)
												(* can't discriminate by type, must do by showing it must be equal to newBlockEntryAddr and creates a contradiction *)
												rewrite <- DependentTypeLemmas.beqAddrTrue in beqscenewsc.
												rewrite <- beqscenewsc in *.
												rewrite H11 in *. (* sceaddr = CPaddr (newBlockEntryAddr + scoffset) *)
												assert(HnullAddrExistss0 : nullAddrExists s0)
														by (unfold consistency in *; intuition).
												unfold nullAddrExists in *. unfold isPADDR in *.
												unfold CPaddr in beqscenewsc.
												destruct (le_dec (newBlockEntryAddr + scoffset) maxAddr) eqn:Hj.
												-- destruct (le_dec (pa + scoffset) maxAddr) eqn:Hk.
													--- simpl in *.
															inversion beqscenewsc as [Heq].
															rewrite PeanoNat.Nat.add_cancel_r in Heq.
															rewrite <- beqAddrFalse in beqnewblockpa.
															apply CPaddrInjectionNat in Heq.
															repeat rewrite paddrEqId in Heq.
															congruence.
													--- inversion beqscenewsc as [Heq].
															rewrite Heq in *.
															rewrite <- nullAddrIs0 in *.
															rewrite <- beqAddrFalse in H26. (* newBlockEntryAddr <> nullAddr *)
															apply CPaddrInjectionNat in Heq.
															repeat rewrite paddrEqId in Heq.
															rewrite <- nullAddrIs0 in Heq.
															unfold isSCE in *.
															destruct (lookup nullAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
															destruct v ; try(exfalso ; congruence).
											--  assert(Heq : CPaddr(newBlockEntryAddr + scoffset) = nullAddr).
													{ rewrite nullAddrIs0.
														unfold CPaddr. rewrite Hj.
														destruct (le_dec 0 maxAddr) ; intuition.
														f_equal. apply proof_irrelevance.
													}
													rewrite Heq in *.
													unfold isSCE in *.
													destruct (lookup nullAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
													destruct v ; try(exfalso ; congruence).
									 - (* sce <> (CPaddr (pa + scoffset)) *)
											(* leads to s0 *)
											assert(Hcons0 : wellFormedShadowCutIfBlockEntry s0)
													by (unfold consistency in *; intuition).
											unfold wellFormedShadowCutIfBlockEntry in *.
											assert(HBEeq : isBE pa s = isBE pa s0).
											{
												unfold isBE.
												rewrite Hs. cbn.
												rewrite beqAddrTrue.
												rewrite beqpasce. rewrite H26. rewrite H24.
												cbn in HBEaddrs. rewrite beqAddrTrue. cbn.
												rewrite beqnewblockpa. rewrite H24.
												rewrite <- beqAddrFalse in *.
												repeat rewrite removeDupIdentity; intuition.
												cbn.
												destruct (beqAddr pdinsertion pa) eqn:Hf ; try (exfalso ; congruence).
												rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
												repeat rewrite removeDupIdentity; intuition.
											}
											assert(HBEaddrs0 : isBE pa s0).
											{ rewrite <- HBEeq. assumption. }
											specialize(Hcons0 pa HBEaddrs0).
											destruct Hcons0 as [scentryaddr (HSCEs0 & Hsceq)].
											(* almost DUP with previous step *)
											destruct (beqAddr newBlockEntryAddr (CPaddr (pa + scoffset))) eqn:newblockscoffset.
											-- (* newBlockEntryAddr = (CPaddr (pa + scoffset))*)
												rewrite <- DependentTypeLemmas.beqAddrTrue in newblockscoffset.
												rewrite <- newblockscoffset in *.
												unfold isSCE in *. unfold isBE in *.
												rewrite Hsceq in *.
												destruct (lookup newBlockEntryAddr (memory s0) beqAddr) ; try(exfalso ; congruence).
												destruct v ; try (exfalso ; congruence).
											-- (* newBlockEntryAddr <> (CPaddr (pa + sh1offset))*)
												destruct (beqAddr pdinsertion (CPaddr (pa + scoffset))) eqn:pdscoffset.
												--- (* pdinsertion = (CPaddr (pa + sh1offset))*)
													rewrite <- DependentTypeLemmas.beqAddrTrue in *.
													rewrite <- pdscoffset in *.
													unfold isSCE in *. unfold isPDT in *.
													rewrite Hsceq in *.
													destruct (lookup pdinsertion (memory s0) beqAddr) eqn:Hlookup ; try(exfalso ; congruence).
													destruct v eqn:Hv ; try(exfalso ; congruence).
												--- (* pdinsertion <> (CPaddr (pa + sh1offset))*)
													(* resolve the only true case *)
													exists scentryaddr. intuition.
													assert(HSCEeq : isSCE scentryaddr s = isSCE scentryaddr s0).
													{
														unfold isSCE.
														rewrite Hs.
														cbn. rewrite beqAddrTrue.
														rewrite <- Hsceq in *. rewrite beqscenewsc. rewrite H26.
														rewrite H24.
														cbn.
														rewrite newblockscoffset.
														cbn.
														rewrite <- beqAddrFalse in *.
														repeat rewrite removeDupIdentity ; intuition.
														rewrite beqAddrTrue.
														destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hf ; try(exfalso ; congruence).
														rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
														cbn.
														destruct (beqAddr pdinsertion scentryaddr) eqn:Hff ; try(exfalso ; congruence).
														rewrite <- DependentTypeLemmas.beqAddrTrue in Hff. congruence.
														rewrite <- beqAddrFalse in *.
														repeat rewrite removeDupIdentity ; intuition.
													}
													rewrite HSCEeq. assumption.
} (* end of wellFormedShadowCutIfBlockEntry *)
split.
{ (* BlocksRangeFromKernelStartIsBE s*)
	unfold BlocksRangeFromKernelStartIsBE.
	intros kernelentryaddr blockidx HKSs Hblockidx.

	assert(Hcons0 : BlocksRangeFromKernelStartIsBE s0) by (unfold consistency in * ; intuition).
	unfold BlocksRangeFromKernelStartIsBE in Hcons0.

	(* check all possible values for bentryaddr in the modified state s
	-> only possible is newBlockEntryAddr
	1) if bentryaddr == newBlockEntryAddr :
		- show CPaddr (bentryaddr + blockidx) didn't change
		- = newBlock -> when blockidx = 0 for example
			-> so isBE at s -> OK
		- <> newBlock
			- CPaddr (bentryaddr + blockidx)
				- = newBlock -> isBE -> OK
				- <> newBlock -> not modified -> leads to s0 in another structure -> OK
	2) if bentryaddr <> newBlockEntryAddr :
		- relates to another bentry than newBlockentryAddr
		(either in the same structure or another)
		- CPaddr (bentryaddr + blockidx)
			- = newBlock -> isBE -> OK
			- <> newBlock -> not modified -> leads to s0 in another structure -> OK
	*)

	(* Check all values except newBlockEntryAddr *)
	destruct (beqAddr sceaddr kernelentryaddr) eqn:beqscebentry; try(exfalso ; congruence).
	- (* sceaddr = kernelentryaddr *)
		rewrite <- DependentTypeLemmas.beqAddrTrue in beqscebentry.
		rewrite <- beqscebentry in *.
		unfold isSCE in *.
		unfold isKS in *.
		destruct (lookup sceaddr (memory s) beqAddr) ; try(exfalso ; congruence).
		destruct v ; try(exfalso ; congruence).
	- (* sceaddr <> kernelentryaddr *)
		destruct (beqAddr pdinsertion kernelentryaddr) eqn:beqpdbentry; try(exfalso ; congruence).
		-- (* pdinsertion = kernelentryaddr *)
				rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdbentry.
				rewrite <- beqpdbentry in *.
				unfold isPDT in *.
				unfold isKS in *.
				destruct (lookup pdinsertion (memory s) beqAddr) ; try(exfalso ; congruence).
				destruct v ; try(exfalso ; congruence).
		-- (* pdinsertion <> kernelentryaddr *)
				destruct (beqAddr newBlockEntryAddr kernelentryaddr) eqn:newbentry ; try(exfalso ; congruence).
				--- (* 1) newBlockEntryAddr = bentryaddr *)
						rewrite <- DependentTypeLemmas.beqAddrTrue in newbentry.
						rewrite <- newbentry in *.
						destruct (beqAddr newBlockEntryAddr (CPaddr (newBlockEntryAddr + blockidx))) eqn:newidx ; try(exfalso ; congruence).
						+++ (* newBlockEntryAddr = (CPaddr (newBlockEntryAddr + blockidx) -> blockidx = 0 *)
								rewrite <- DependentTypeLemmas.beqAddrTrue in newidx.
								rewrite <- newidx in *.
								intuition.
						+++ (* newBlockEntryAddr <> (CPaddr (newBlockEntryAddr + blockidx)) *)
								assert(HKSEq : isKS newBlockEntryAddr s = isKS newBlockEntryAddr s0).
								{
									unfold isKS. rewrite H2. rewrite Hs.
									cbn. rewrite beqAddrTrue.
									rewrite beqscebentry.
									rewrite beqAddrSym in beqscebentry.
									rewrite beqscebentry.
									cbn. rewrite beqAddrTrue.
									f_equal. rewrite <- Hblockindex7. rewrite <- Hblockindex6.
									rewrite <- Hblockindex5. rewrite <- Hblockindex4.
									rewrite <- Hblockindex3. rewrite <- Hblockindex2.
									unfold CBlockEntry.
									destruct(lt_dec (blockindex bentry5) kernelStructureEntriesNb) eqn:Hdec ; try(exfalso ; congruence).
									intuition.
									destruct blockentry_d. destruct bentry5.
									intuition.
								}
								assert(HKSs0 : isKS newBlockEntryAddr s0) by (rewrite HKSEq in * ; intuition).
								(* specialize for newBlock *)
								specialize(Hcons0 newBlockEntryAddr blockidx HKSs0 Hblockidx).
								(* check all values *)
								destruct (beqAddr sceaddr (CPaddr (newBlockEntryAddr + blockidx))) eqn:beqsceidx; try(exfalso ; congruence).
								+ (* sceaddr = (CPaddr (newBlockEntryAddr + blockidx) *)
									rewrite <- DependentTypeLemmas.beqAddrTrue in beqsceidx.
									rewrite <- beqsceidx in *.
									unfold isSCE in *.
									unfold isBE in *.
									destruct (lookup sceaddr (memory s0) beqAddr) ; try(exfalso ; congruence).
									destruct v ; try(exfalso ; congruence).
								+ (* sceaddr <> (CPaddr (newBlockEntryAddr + blockidx) *)
									destruct (beqAddr pdinsertion (CPaddr (newBlockEntryAddr + blockidx))) eqn:beqpdidx; try(exfalso ; congruence).
									++ (* pdinsertion = (CPaddr (newBlockEntryAddr + blockidx) *)
											rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdidx.
											rewrite <- beqpdidx in *.
											unfold isPDT in *.
											unfold isBE in *.
											destruct (lookup pdinsertion (memory s0) beqAddr) ; try(exfalso ; congruence).
											destruct v ; try(exfalso ; congruence).
									++ (* pdinsertion <> (CPaddr (newBlockEntryAddr + blockidx) *)
													unfold isBE.
													rewrite Hs.
													cbn. rewrite beqAddrTrue.
													rewrite beqsceidx.
													rewrite H26. (* newblock <> sce*)
													rewrite H24. (* pdinsertion <> newBlock *)
													cbn.
													rewrite newidx.
													rewrite beqAddrTrue.
													rewrite <- beqAddrFalse in *.
													repeat rewrite removeDupIdentity ; intuition.
													destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hf ; try(exfalso ; congruence).
													rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
													cbn.
													destruct (beqAddr pdinsertion (CPaddr (newBlockEntryAddr + blockidx))) eqn:Hff ; try(exfalso ; congruence).
													rewrite <- DependentTypeLemmas.beqAddrTrue in Hff. congruence.
													rewrite <- beqAddrFalse in *.
													repeat rewrite removeDupIdentity ; intuition.
			--- (* 2) newBlockEntryAddr <> bentryaddr *)
					(* COPY previous step and wellFormedShadowCutIfBlockEntry *)
					assert(HKSeq : isKS kernelentryaddr s = isKS kernelentryaddr s0).
					{
						unfold isKS.
						rewrite Hs. cbn.
						rewrite beqAddrTrue.
						rewrite beqscebentry. rewrite H26. rewrite H24.
						cbn in HBEs. rewrite beqAddrTrue. cbn.
						rewrite newbentry. rewrite H24.
						rewrite <- beqAddrFalse in *.
						repeat rewrite removeDupIdentity; intuition.
						cbn.
						destruct (beqAddr pdinsertion kernelentryaddr) eqn:Hf ; try (exfalso ; congruence).
						rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
						repeat rewrite removeDupIdentity; intuition.
					}
					assert(HKSs0 : isKS kernelentryaddr s0).
					{ rewrite <- HKSeq. assumption. }
					specialize(Hcons0 kernelentryaddr blockidx HKSs0 Hblockidx).
					destruct (beqAddr sceaddr (CPaddr (kernelentryaddr + blockidx))) eqn:beqsceidx; try(exfalso ; congruence).
					+ (* sceaddr = (CPaddr (kernelentryaddr + blockidx) *)
						rewrite <- DependentTypeLemmas.beqAddrTrue in beqsceidx.
						rewrite <- beqsceidx in *.
						unfold isSCE in *.
						unfold isBE in *.
						destruct (lookup sceaddr (memory s0) beqAddr) ; try(exfalso ; congruence).
						destruct v ; try(exfalso ; congruence).
					+ (* sceaddr <> (CPaddr (kernelentryaddr + blockidx) *)
						destruct (beqAddr pdinsertion (CPaddr (kernelentryaddr + blockidx))) eqn:beqpdidx; try(exfalso ; congruence).
						++ (* pdinsertion = (CPaddr (kernelentryaddr + blockidx) *)
								rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdidx.
								rewrite <- beqpdidx in *.
								unfold isPDT in *.
								unfold isBE in *.
								destruct (lookup pdinsertion (memory s0) beqAddr) ; try(exfalso ; congruence).
								destruct v ; try(exfalso ; congruence).
						++ (* pdinsertion <> (CPaddr (kernelentryaddr + blockidx) *)
							destruct (beqAddr newBlockEntryAddr (CPaddr (kernelentryaddr + blockidx))) eqn:newidx ; try(exfalso ; congruence).
							+++ (* newBlockEntryAddr = (CPaddr (kernelentryaddr + blockidx) -> blockidx = 0 *)
									rewrite <- DependentTypeLemmas.beqAddrTrue in newidx.
									rewrite <- newidx in *.
									intuition.
							+++ (* newBlockEntryAddr <> (CPaddr (kernelentryaddr + blockidx)) *)
									(* leads to s0 *)
									unfold isBE.
									rewrite Hs.
									cbn. rewrite beqAddrTrue.
									rewrite beqsceidx.
									rewrite H26. (* newblock <> sce*)
									rewrite H24. (* pdinsertion <> newBlock *)
									cbn.
									rewrite newidx.
									rewrite beqAddrTrue.
									rewrite <- beqAddrFalse in *.
									repeat rewrite removeDupIdentity ; intuition.
									destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:Hf ; try(exfalso ; congruence).
									rewrite <- DependentTypeLemmas.beqAddrTrue in Hf. congruence.
									cbn.
									destruct (beqAddr pdinsertion (CPaddr (kernelentryaddr + blockidx))) eqn:Hff ; try(exfalso ; congruence).
									rewrite <- DependentTypeLemmas.beqAddrTrue in Hff. congruence.
									rewrite <- beqAddrFalse in *.
									repeat rewrite removeDupIdentity ; intuition.
} (* end of BlockEntryAddrInBlocksRangeIsBE *)
split.
{ (* KernelStructureStartFromBlockEntryAddrIsKS s *)
	unfold KernelStructureStartFromBlockEntryAddrIsKS.
	intros bentryaddr blockidx Hlookup Hblockidx.

	assert(Hcons0 : KernelStructureStartFromBlockEntryAddrIsKS s0) by (unfold consistency in * ; intuition).
	unfold KernelStructureStartFromBlockEntryAddrIsKS in Hcons0.

	(* check all possible values for bentryaddr in the modified state s
			-> only possible is newBlockEntryAddr
		1) if bentryaddr == newBlockEntryAddr :
				- still a BlockEntry in s, index not modified
					- kernelStart is newBlock -> still a BE
					- kernelStart is not modified -> leads to s0 -> OK
		2) if bentryaddr <> newBlockEntryAddr :
				- relates to another bentry than newBlockentryAddr
					(either in the same structure or another)
					- kernelStart is newBlock -> still a BE
					- kernelStart is not modified -> leads to s0 -> OK
*)
	(* Check all values except newBlockEntryAddr *)
	destruct (beqAddr sceaddr bentryaddr) eqn:beqscebentry; try(exfalso ; congruence).
	-	(* sceaddr = bentryaddr *)
		rewrite <- DependentTypeLemmas.beqAddrTrue in beqscebentry.
		rewrite <- beqscebentry in *.
		unfold isSCE in *.
		unfold isBE in *.
		destruct (lookup sceaddr (memory s) beqAddr) ; try(exfalso ; congruence).
		destruct v ; try(exfalso ; congruence).
	-	(* sceaddr <> bentryaddr *)
		destruct (beqAddr pdinsertion bentryaddr) eqn:beqpdbentry; try(exfalso ; congruence).
		-- (* pdinsertion = bentryaddr *)
			rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdbentry.
			rewrite <- beqpdbentry in *.
			unfold isPDT in *.
			unfold isBE in *.
			destruct (lookup pdinsertion (memory s) beqAddr) ; try(exfalso ; congruence).
			destruct v ; try(exfalso ; congruence).
		-- (* pdinsertion <> bentryaddr *)
			destruct (beqAddr newBlockEntryAddr bentryaddr) eqn:newbentry ; try(exfalso ; congruence).
			--- (* newBlockEntryAddr = bentryaddr *)
					rewrite <- DependentTypeLemmas.beqAddrTrue in newbentry.
					rewrite <- newbentry in *.
					unfold bentryBlockIndex in *. rewrite H4 in *.
					destruct Hblockidx as [Hblockidx Hidxnb].
					specialize(Hcons0 newBlockEntryAddr blockidx HBEs0).
					rewrite H2 in *. intuition. rewrite Hblockindex in *.
					intuition.

					(* Check all possible values for CPaddr (newBlockEntryAddr - blockidx)
							-> only possible is newBlockEntryAddr
							1) if CPaddr (newBlockEntryAddr - blockidx) == newBlockEntryAddr :
									- still a BlockEntry in s with blockindex newBlockEntryAddr = 0 -> OK
							2) if CPaddr (newBlockEntryAddr - blockidx) <> newBlockEntryAddr :
									- relates to another bentry than newBlockentryAddr
										that was not modified
										(either in the same structure or another)
									- -> leads to s0 -> OK
					*)

					(* Check all values except newBlockEntryAddr *)
					destruct (beqAddr sceaddr (CPaddr (newBlockEntryAddr - blockidx))) eqn:beqsceks; try(exfalso ; congruence).
					*	(* sceaddr = (CPaddr (newBlockEntryAddr - blockidx)) *)
						rewrite <- DependentTypeLemmas.beqAddrTrue in beqsceks.
						rewrite <- beqsceks in *.
						unfold isSCE in *.
						unfold isKS in *.
						destruct (lookup sceaddr (memory s0) beqAddr) ; try(exfalso ; congruence).
						destruct v ; try(exfalso ; congruence).
					*	(* sceaddr <> kernelstarts0 *)
						destruct (beqAddr pdinsertion (CPaddr (newBlockEntryAddr - blockidx))) eqn:beqpdks; try(exfalso ; congruence).
						** (* pdinsertion = (CPaddr (newBlockEntryAddr - blockidx)) *)
							rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdks.
							rewrite <- beqpdks in *.
							unfold isPDT in *.
							unfold isKS in *.
							destruct (lookup pdinsertion (memory s0) beqAddr) ; try(exfalso ; congruence).
							destruct v ; try(exfalso ; congruence).
						** (* pdinsertion <> (CPaddr (newBlockEntryAddr - blockidx)) *)
							destruct (beqAddr newBlockEntryAddr (CPaddr (newBlockEntryAddr - blockidx))) eqn:beqnewks ; try(exfalso ; congruence).
							*** (* newBlockEntryAddr = (CPaddr (newBlockEntryAddr - blockidx)) *)
									rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewks.
									rewrite <- beqnewks in *.
									intuition.
									unfold isKS in *. rewrite H4. rewrite H2 in *.
									rewrite Hblockindex. intuition.
							*** (* newBlockEntryAddr <> (CPaddr (newBlockEntryAddr - blockidx)) *)
									unfold isKS.
									rewrite Hs.
									cbn. rewrite beqAddrTrue.
									destruct (beqAddr sceaddr (CPaddr (newBlockEntryAddr - blockidx))) eqn:sceks ; try(exfalso ; congruence).
									destruct (beqAddr newBlockEntryAddr sceaddr) eqn:newsce ; try(exfalso ; congruence).
									rewrite beqAddrTrue.
									cbn.
									destruct (beqAddr newBlockEntryAddr (CPaddr (newBlockEntryAddr - blockidx))) eqn:newks ; try(exfalso ; congruence).
									destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:pdks ; try(exfalso ; congruence).
									cbn.
									rewrite <- beqAddrFalse in *.
									repeat rewrite removeDupIdentity ; intuition.
									destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:pdnew ; try(exfalso ; congruence).
									rewrite <- DependentTypeLemmas.beqAddrTrue in pdnew. congruence.
									cbn.
									destruct (beqAddr pdinsertion (CPaddr (newBlockEntryAddr - blockidx))) eqn:pdks'; try(exfalso ; congruence).
									rewrite <- DependentTypeLemmas.beqAddrTrue in pdks'. congruence.
									rewrite <- beqAddrFalse in *.
									repeat rewrite removeDupIdentity ; intuition.
			---	(* newBlockEntryAddr <> bentryaddr *)
					(*apply isBELookupEq in Hlookup. destruct Hlookup as [Hentry Hlookup].
					unfold bentryBlockIndex in *. rewrite Hlookup in *.
					destruct Hblockidx as [Hblockidx Hidxnb].
					specialize(Hcons0 newBlockEntryAddr blockidx HBEs0).
					rewrite H2 in *. intuition. rewrite Hblockindex in *.
					intuition.*)

					assert(HblockEq : isBE bentryaddr s = isBE bentryaddr s0).
					{ (* DUP *)
						unfold isBE.
						rewrite Hs.
						cbn. rewrite beqAddrTrue.
						destruct (beqAddr sceaddr bentryaddr) eqn:scebentry ; try(exfalso ; congruence).
						destruct (beqAddr newBlockEntryAddr sceaddr) eqn:newsce ; try(exfalso ; congruence).
						rewrite beqAddrTrue.
						cbn. rewrite newbentry. rewrite H24. (* beqAddr pdinsertion newBlockEntryAddr = false *)
						rewrite <- beqAddrFalse in *.
						repeat rewrite removeDupIdentity ; intuition.
						cbn.
						destruct (beqAddr pdinsertion bentryaddr) eqn:pdbentry; try(exfalso ; congruence).
						rewrite <- DependentTypeLemmas.beqAddrTrue in pdbentry. congruence.
						rewrite <- beqAddrFalse in *.
						repeat rewrite removeDupIdentity ; intuition.
				}
				assert(Hblocks0 : isBE bentryaddr s0) by (rewrite HblockEq in * ; intuition).
				apply isBELookupEq in Hlookup. destruct Hlookup as [blockentry Hlookup].
				unfold bentryBlockIndex in *. rewrite Hlookup in *.
				destruct Hblockidx as [Hblockidx Hidxnb].
				specialize(Hcons0 bentryaddr blockidx Hblocks0).
				apply isBELookupEq in Hblocks0. destruct Hblocks0 as [blockentrys0 Hblocks0].
				rewrite Hblocks0 in *. intuition.
				assert(HlookupEq : lookup bentryaddr (memory s) beqAddr = lookup bentryaddr (memory s0) beqAddr).
					{ (* DUP *)
						rewrite Hs.
						cbn. rewrite beqAddrTrue.
						destruct (beqAddr sceaddr bentryaddr) eqn:scebentry ; try(exfalso ; congruence).
						destruct (beqAddr newBlockEntryAddr sceaddr) eqn:newsce ; try(exfalso ; congruence).
						rewrite beqAddrTrue.
						cbn. rewrite newbentry. rewrite H24. (* beqAddr pdinsertion newBlockEntryAddr = false *)
						rewrite <- beqAddrFalse in *.
						repeat rewrite removeDupIdentity ; intuition.
						cbn.
						destruct (beqAddr pdinsertion bentryaddr) eqn:pdbentry; try(exfalso ; congruence).
						rewrite <- DependentTypeLemmas.beqAddrTrue in pdbentry. congruence.
						rewrite <- beqAddrFalse in *.
						repeat rewrite removeDupIdentity ; intuition.
				}
				assert(HlookupEq' : lookup bentryaddr (memory s0) beqAddr = Some (BE blockentry)).
				{ rewrite <- HlookupEq. intuition. }
				rewrite HlookupEq' in *. inversion Hblocks0.
				subst blockentrys0. intuition.
					(* DUP *)
					(* Check all values except newBlockEntryAddr *)
					destruct (beqAddr sceaddr (CPaddr (bentryaddr - blockidx))) eqn:beqsceks; try(exfalso ; congruence).
					*	(* sceaddr = (CPaddr (bentryaddr - blockidx)) *)
						rewrite <- DependentTypeLemmas.beqAddrTrue in beqsceks.
						rewrite <- beqsceks in *.
						unfold isSCE in *.
						unfold isKS in *.
						destruct (lookup sceaddr (memory s0) beqAddr) ; try(exfalso ; congruence).
						destruct v ; try(exfalso ; congruence).
					*	(* sceaddr <> (CPaddr (bentryaddr - blockidx)) *)
						destruct (beqAddr pdinsertion (CPaddr (bentryaddr - blockidx))) eqn:beqpdks; try(exfalso ; congruence).
						** (* pdinsertion = (CPaddr (bentryaddr - blockidx)) *)
							rewrite <- DependentTypeLemmas.beqAddrTrue in beqpdks.
							rewrite <- beqpdks in *.
							unfold isPDT in *.
							unfold isKS in *.
							destruct (lookup pdinsertion (memory s0) beqAddr) ; try(exfalso ; congruence).
							destruct v ; try(exfalso ; congruence).
					** (* pdinsertion <> (CPaddr (bentryaddr - blockidx)) *)
							destruct (beqAddr newBlockEntryAddr (CPaddr (bentryaddr - blockidx))) eqn:beqnewks ; try(exfalso ; congruence).
							*** (* newBlockEntryAddr = (CPaddr (bentryaddr - blockidx)) *)
									rewrite <- DependentTypeLemmas.beqAddrTrue in beqnewks.
									rewrite <- beqnewks in *.
									unfold isKS in *. rewrite H4. rewrite H2 in *.
									rewrite Hblockindex. intuition.
							*** (* newBlockEntryAddr <> kernelstarts0 *)
									unfold isKS.
									rewrite Hs.
									cbn. rewrite beqAddrTrue.
									rewrite beqsceks.
									destruct (beqAddr newBlockEntryAddr sceaddr) eqn:newsce ; try(exfalso ; congruence).
									rewrite beqAddrTrue.
									cbn. rewrite beqnewks.
									rewrite <- beqAddrFalse in *.
									repeat rewrite removeDupIdentity ; intuition.
									destruct (beqAddr pdinsertion newBlockEntryAddr) eqn:pdnew ; try(exfalso ; congruence).
									rewrite <- DependentTypeLemmas.beqAddrTrue in pdnew. congruence.
									cbn.
									destruct (beqAddr pdinsertion (CPaddr (bentryaddr - blockidx))) eqn:pdks'; try(exfalso ; congruence).
									rewrite <- DependentTypeLemmas.beqAddrTrue in pdks'. congruence.
									rewrite <- beqAddrFalse in *.
									repeat rewrite removeDupIdentity ; intuition.
} (* end of KernelStructureStartFromBlockEntryAddrIsKS *)
	- (* Final state *)
		exists newpd. intuition. exists s0. exists pdentry. exists pdentry0.
		exists bentry. exists bentry0. exists bentry1. exists bentry2. exists bentry3.
		exists bentry4. exists bentry5. exists bentry6. exists sceaddr. exists scentry.
		exists newBlockEntryAddr. exists newFirstFreeSlotAddr. exists predCurrentNbFreeSlots.
		intuition.

(*
	destruct H. intuition.
	destruct H6. destruct H5. destruct H5. destruct H5.
			destruct H5. destruct H5. destruct H5. destruct H5. destruct H5.
			destruct H5. destruct H5. destruct H5.
			eexists. eexists. eexists. eexists. eexists. eexists. eexists. eexists.
			eexists. eexists. eexists. eexists. exists newBlockEntryAddr. exists newFirstFreeSlotAddr. exists predCurrentNbFreeSlots.

			intuition. rewrite H5. f_equal.*)
			Admitted.
(*
			exists x10. exists x11.
			exists x2. exists x9. exists newBlockEntryAddr. exists newFirstFreeSlotAddr. exists predCurrentNbFreeSlots.
			intuition. cbn. (* change postcondition or show equivalence *)
			simpl in *. unfold add in H5. simpl in H5.
			repeat rewrite beqAddrTrue in H5.
 exists s. subst. intuition.


-----------------------

			instantiate (1:= fun _ s => (*partitionsIsolation s /\ *)
				exists pdentry : PDTable,
				(lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry)
				) /\  isPDT pdinsertion s
				(*/\ s = {|
					currentPartition := currentPartition s;
					memory := add pdinsertion
								      (PDT
								         {|
								         structure := structure pdentry;
								         firstfreeslot := newFirstFreeSlotAddr;
												(*structure := newFirstFreeSlotAddr;
								         firstfreeslot := newFirstFreeSlotAddr;*)
								         nbfreeslots := nbfreeslots pdentry;
								         nbprepare := nbprepare pdentry;
								         parent := parent pdentry;
								         MPU := MPU pdentry |}) (memory s) beqAddr |}
										(*s.(memory) |}*)*)

				). simpl. set (s' := {|
      currentPartition :=  _|}).
- eexists. split. rewrite beqAddrTrue. (*split.*)
			+ f_equal.
			+ (*split.*) unfold isPDT. cbn. rewrite beqAddrTrue. intuition.
			}
			} 	cbn. admit. admit. admit. admit. admit.
			}
			intros.
			eapply weaken. apply modify.
			intros. simpl.
			instantiate (1:= fun _ s => (*partitionsIsolation s /\ *)
				exists pdentry : PDTable,
				(lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry)
				) /\  isPDT pdinsertion s
				/\ s = {|
					currentPartition := currentPartition s;
					memory := add pdinsertion
								      (PDT
								         {|
								         structure := structure pdentry;
								         firstfreeslot := newFirstFreeSlotAddr;
												(*structure := newFirstFreeSlotAddr;
								         firstfreeslot := newFirstFreeSlotAddr;*)
								         nbfreeslots := nbfreeslots pdentry;
								         nbprepare := nbprepare pdentry;
								         parent := parent pdentry;
								         MPU := MPU pdentry |}) (memory s) beqAddr |}
										(*s.(memory) |}*)  (*/\

				((*partitionsIsolation s /\
					 verticalSharing s /\*)

					pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s) /\
				 bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s /\
				StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots /\

							pdentryNbFreeSlots pdinsertion currnbfreeslots s /\
							currnbfreeslots > 0 /\ consistency s (* /\ isBE idBlockToShare s *)
				/\ isPDT pdinsertion s*)
				(*/\ exists pdentry : PDTable,
				lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry)*)
				). simpl. set (s' := {|
      currentPartition :=  _|}).
		 (*split.
		- admit.*)
		- eexists. split. rewrite beqAddrTrue. (*split.*)
			+ f_equal.
			+ (*split.*) unfold isPDT. cbn. rewrite beqAddrTrue. intuition.
				cbn. admit.

		}
}  eapply weaken. apply undefined. intros.
			simpl. intuition. destruct H. intuition. congruence.
eapply weaken. apply undefined. intros.
			simpl. intuition. destruct H. intuition. congruence.
eapply weaken. apply undefined. intros.
			simpl. intuition. destruct H. intuition. congruence.
eapply weaken. apply undefined. intros.
			simpl. intuition. destruct H. intuition. congruence.
eapply weaken. apply undefined. intros.
			simpl. intuition. destruct H. intuition. congruence.
} intros.
}
			admit. admit. admit. admit. admit. }
intros. simpl.*)

	Admitted.
(*
			exists x10. exists x11.
			exists x2. exists x9. exists newBlockEntryAddr. exists newFirstFreeSlotAddr. exists predCurrentNbFreeSlots.
			intuition. cbn. (* change postcondition or show equivalence *)
			simpl in *. unfold add in H5. simpl in H5.
			repeat rewrite beqAddrTrue in H5.
 exists s. subst. intuition.


-----------------------

			instantiate (1:= fun _ s => (*partitionsIsolation s /\ *)
				exists pdentry : PDTable,
				(lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry)
				) /\  isPDT pdinsertion s
				(*/\ s = {|
					currentPartition := currentPartition s;
					memory := add pdinsertion
								      (PDT
								         {|
								         structure := structure pdentry;
								         firstfreeslot := newFirstFreeSlotAddr;
												(*structure := newFirstFreeSlotAddr;
								         firstfreeslot := newFirstFreeSlotAddr;*)
								         nbfreeslots := nbfreeslots pdentry;
								         nbprepare := nbprepare pdentry;
								         parent := parent pdentry;
								         MPU := MPU pdentry |}) (memory s) beqAddr |}
										(*s.(memory) |}*)*)

				). simpl. set (s' := {|
      currentPartition :=  _|}).
- eexists. split. rewrite beqAddrTrue. (*split.*)
			+ f_equal.
			+ (*split.*) unfold isPDT. cbn. rewrite beqAddrTrue. intuition.
			}
			} 	cbn. admit. admit. admit. admit. admit.
			}
			intros.
			eapply weaken. apply modify.
			intros. simpl.
			instantiate (1:= fun _ s => (*partitionsIsolation s /\ *)
				exists pdentry : PDTable,
				(lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry)
				) /\  isPDT pdinsertion s
				/\ s = {|
					currentPartition := currentPartition s;
					memory := add pdinsertion
								      (PDT
								         {|
								         structure := structure pdentry;
								         firstfreeslot := newFirstFreeSlotAddr;
												(*structure := newFirstFreeSlotAddr;
								         firstfreeslot := newFirstFreeSlotAddr;*)
								         nbfreeslots := nbfreeslots pdentry;
								         nbprepare := nbprepare pdentry;
								         parent := parent pdentry;
								         MPU := MPU pdentry |}) (memory s) beqAddr |}
										(*s.(memory) |}*)  (*/\

				((*partitionsIsolation s /\
					 verticalSharing s /\*)

					pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s) /\
				 bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s /\
				StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots /\

							pdentryNbFreeSlots pdinsertion currnbfreeslots s /\
							currnbfreeslots > 0 /\ consistency s (* /\ isBE idBlockToShare s *)
				/\ isPDT pdinsertion s*)
				(*/\ exists pdentry : PDTable,
				lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry)*)
				). simpl. set (s' := {|
      currentPartition :=  _|}).
		 (*split.
		- admit.*)
		- eexists. split. rewrite beqAddrTrue. (*split.*)
			+ f_equal.
			+ (*split.*) unfold isPDT. cbn. rewrite beqAddrTrue. intuition.
				cbn. admit.

		}
}  eapply weaken. apply undefined. intros.
			simpl. intuition. destruct H. intuition. congruence.
eapply weaken. apply undefined. intros.
			simpl. intuition. destruct H. intuition. congruence.
eapply weaken. apply undefined. intros.
			simpl. intuition. destruct H. intuition. congruence.
eapply weaken. apply undefined. intros.
			simpl. intuition. destruct H. intuition. congruence.
eapply weaken. apply undefined. intros.
			simpl. intuition. destruct H. intuition. congruence.
} intros.
	eapply bindRev.
	{ (** MAL.writePDNbFreeSlots **)
		eapply weaken.
		2 : { intros. exact H. }
		unfold MAL.writePDNbFreeSlots.
		eapply bindRev.
		{ (** get **)
			eapply weaken. apply get.
			intro s. intros. simpl. instantiate (1:= fun s s0 => s = s0 /\
(*partitionsIsolation s /\*)
    exists pdentry : PDTable,
       (lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry) /\
        isPDT pdinsertion s)  /\
        s =
        {|
        currentPartition := currentPartition s;
        memory := add pdinsertion
                    (PDT
                       {|
                       structure := structure pdentry;
                       firstfreeslot := newFirstFreeSlotAddr;
                       nbfreeslots := nbfreeslots pdentry;
                       nbprepare := nbprepare pdentry;
                       parent := parent pdentry;
                       MPU := MPU pdentry |}) (memory s1) beqAddr |} (*/\
       ((*partitionsIsolation s /\
        verticalSharing s /\*)
			pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s) /\
       bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s /\
       StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots /\
       pdentryNbFreeSlots pdinsertion currnbfreeslots s /\
       currnbfreeslots > 0 (*/\
       consistency s*) (* /\ isBE idBlockToShare s *) /\ isPDT pdinsertion s)*)). intuition.
intuition. destruct H. exists x. intuition. }
intro s0. simpl. intuition. (*admit.*)
		destruct (lookup pdinsertion (memory s0) beqAddr) eqn:Hlookup.
		destruct v eqn:Hv.
		4 : {
unfold Monad.modify.
eapply bindRev.
		{ (** get **)
					eapply weaken. apply get.
			intro s. intros. simpl. pattern s in H. apply H.
	}
	intro s1.
	eapply weaken. apply put.
	intros. simpl.
(*
		eapply weaken. apply modify.
		intros.*)
instantiate (1:= fun _ s => (*partitionsIsolation s /\ *)
exists pdentry : PDTable,
(lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry)) /\
isPDT pdinsertion s /\

s = {|
  currentPartition := currentPartition s;
  memory := add pdinsertion
              (PDT
                 {|
                 structure := structure pdentry;
                 firstfreeslot := newFirstFreeSlotAddr;
                 nbfreeslots := nbfreeslots pdentry;
                 nbprepare := nbprepare pdentry;
                 parent := parent pdentry;
                 MPU := MPU pdentry |}) (memory s) beqAddr |} (*/\

((*partitionsIsolation s /\
   verticalSharing s /\*)

  pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s) /\
 bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s /\
StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots /\

      pdentryNbFreeSlots pdinsertion currnbfreeslots s /\
      currnbfreeslots > 0 /\ consistency s (* /\ isBE idBlockToShare s *)
/\ isPDT pdinsertion s
(*/\ exists pdentry : PDTable,
lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry)*) *)
). simpl. set (s' := {|
      currentPartition :=  _|}).
		 (*split.
		- admit.*)
		- eexists. split. rewrite beqAddrTrue. (*split.*)
			+ f_equal. + split.
			 (*split.*) unfold isPDT. cbn. rewrite beqAddrTrue. intuition.
				cbn. intuition. destruct H1.  intuition. subst. cbn in *.
				rewrite H2 in s'. f_equal.


			 } admit. admit. admit. admit. admit. } intros.
	eapply bindRev.
	{ (** MAL.writeBlockStartFromBlockEntryAddr **)
		eapply weaken.
		2 : { intros. exact H. }
		unfold MAL.writeBlockStartFromBlockEntryAddr.
		eapply bindRev.
		eapply weaken. apply get.
		intro s. intros. simpl. instantiate (1:= fun s s0 => s = s0 /\
(*partitionsIsolation s /\*)
    (exists pdentry : PDTable,
       (lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry) /\
        isPDT pdinsertion s (*/\
        s =
        {|
        currentPartition := currentPartition s;
        memory := add pdinsertion
                    (PDT
                       {|
                       structure := structure pdentry;
                       firstfreeslot := newFirstFreeSlotAddr;
                       nbfreeslots := predCurrentNbFreeSlots;
                       nbprepare := nbprepare pdentry;
                       parent := parent pdentry;
                       MPU := MPU pdentry |}) (memory s) beqAddr |} *) ) /\
       ((*partitionsIsolation s /\
        verticalSharing s /\*) pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s) /\
       bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s /\
       StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots /\
       pdentryNbFreeSlots pdinsertion currnbfreeslots s /\
       currnbfreeslots > 0 /\
       consistency s(*  /\ isBE idBlockToShare s *) /\ isPDT pdinsertion s)). intuition.
intro s0. intuition.
		destruct (lookup newBlockEntryAddr (memory s0) beqAddr) eqn:Hlookup.
		destruct v eqn:Hv.
		eapply weaken. apply modify.
		intros. (*instantiate (1:= fun _ s => tt=tt /\ s =s ).*)
instantiate (1:= fun _ s => partitionsIsolation s /\
exists pdentry : PDTable, exists bentry : BlockEntry,
(lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry) /\
isPDT pdinsertion s /\
lookup newBlockEntryAddr (memory s) beqAddr = Some (BE bentry) /\
isBE newBlockEntryAddr s (*/\
s = {|
  currentPartition := currentPartition s;
  memory := add pdinsertion
              (PDT
                 {|
                 structure := structure pdentry;
                 firstfreeslot := newFirstFreeSlotAddr;
                 nbfreeslots := predCurrentNbFreeSlots;
                 nbprepare := nbprepare pdentry;
                 parent := parent pdentry;
                 MPU := MPU pdentry |})
					(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry) (write bentry) (exec bentry)
                       (present bentry) (accessible bentry) (blockindex bentry)
                       (CBlock startaddr (endAddr (blockrange bentry)))))

 (memory s) beqAddr) beqAddr |} *) ) /\

(partitionsIsolation s /\
   verticalSharing s /\

  pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s) /\
 bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s /\
StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots /\

      pdentryNbFreeSlots pdinsertion currnbfreeslots s /\
      currnbfreeslots > 0 /\ consistency s (* /\ isBE idBlockToShare s *)
/\ isPDT pdinsertion s
(*/\ exists pdentry : PDTable,
lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry)*)
). simpl. admit. admit. admit. admit. admit. admit. } intros.
	eapply bindRev.
	{ (** MAL.writeBlockEndFromBlockEntryAddr **)
		eapply weaken.
		2 : { intros. exact H. }
		unfold MAL.writeBlockEndFromBlockEntryAddr.
		eapply bindRev.
		eapply weaken. apply get.
		intro s. intros. simpl. instantiate (1:= fun s s0 => s = s0 /\
(*partitionsIsolation s /\ *)
exists pdentry : PDTable, exists bentry : BlockEntry,
(lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry) /\
isPDT pdinsertion s /\
lookup newBlockEntryAddr (memory s) beqAddr = Some (BE bentry) /\
isBE newBlockEntryAddr s (*/\
s = {|
  currentPartition := currentPartition s;
  memory := add pdinsertion
              (PDT
                 {|
                 structure := structure pdentry;
                 firstfreeslot := newFirstFreeSlotAddr;
                 nbfreeslots := predCurrentNbFreeSlots;
                 nbprepare := nbprepare pdentry;
                 parent := parent pdentry;
                 MPU := MPU pdentry |})
					(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry) (write bentry) (exec bentry)
                       (present bentry) (accessible bentry) (blockindex bentry)
                       (CBlock startaddr (endAddr (blockrange bentry)))))

 (memory s) beqAddr) beqAddr |} *) ) /\

((*partitionsIsolation s /\
   verticalSharing s /\*)

  pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s) /\
 bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s /\
StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots /\

      pdentryNbFreeSlots pdinsertion currnbfreeslots s /\
      currnbfreeslots > 0 /\ consistency s (* /\ isBE idBlockToShare s *)
/\ isPDT pdinsertion s). intuition. admit.
intro s0. intuition.
		destruct (lookup newBlockEntryAddr (memory s0) beqAddr) eqn:Hlookup.
		destruct v eqn:Hv.
		eapply weaken. apply modify.
		intros. (*instantiate (1:= fun _ s => tt=tt /\ s =s ).*)
instantiate (1:= fun _ s => (*partitionsIsolation s /\ *)
exists pdentry : PDTable, exists bentry : BlockEntry,
(lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry) /\
isPDT pdinsertion s /\
lookup newBlockEntryAddr (memory s) beqAddr = Some (BE bentry) /\
isBE newBlockEntryAddr s (*/\
s = {|
  currentPartition := currentPartition s;
  memory := add pdinsertion
              (PDT
                 {|
                 structure := structure pdentry;
                 firstfreeslot := newFirstFreeSlotAddr;
                 nbfreeslots := predCurrentNbFreeSlots;
                 nbprepare := nbprepare pdentry;
                 parent := parent pdentry;
                 MPU := MPU pdentry |})
					(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry) (write bentry) (exec bentry)
                       (present bentry) (accessible bentry) (blockindex bentry)
                       (CBlock startaddr endaddr)))

 (memory s) beqAddr) beqAddr |} *) ) /\

((*partitionsIsolation s /\
   verticalSharing s /\*)

  pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s) /\
 bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s /\
StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots /\

      pdentryNbFreeSlots pdinsertion currnbfreeslots s /\
      currnbfreeslots > 0 /\ consistency s (* /\ isBE idBlockToShare s *)
/\ isPDT pdinsertion s
(*/\ exists pdentry : PDTable,
lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry)*)
). simpl. admit. admit. admit. admit. admit. admit. } intros.

	eapply bindRev.
	{ (** MAL.writeBlockAccessibleFromBlockEntryAddr **)
		eapply weaken.
		2 : { intros. exact H. }
		unfold MAL.writeBlockAccessibleFromBlockEntryAddr.
		eapply bindRev.
		eapply weaken. apply get.
		intro s. intros. simpl. instantiate (1:= fun s s0 => s = s0 /\
(*partitionsIsolation s /\ *)
exists pdentry : PDTable, exists bentry : BlockEntry,
(lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry) /\
isPDT pdinsertion s /\
lookup newBlockEntryAddr (memory s) beqAddr = Some (BE bentry) /\
isBE newBlockEntryAddr s (*/\
s = {|
  currentPartition := currentPartition s;
  memory := add pdinsertion
              (PDT
                 {|
                 structure := structure pdentry;
                 firstfreeslot := newFirstFreeSlotAddr;
                 nbfreeslots := predCurrentNbFreeSlots;
                 nbprepare := nbprepare pdentry;
                 parent := parent pdentry;
                 MPU := MPU pdentry |})
					(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry) (write bentry) (exec bentry)
                       (present bentry) (accessible bentry) (blockindex bentry)
                       (CBlock startaddr endaddr)))

 (memory s) beqAddr) beqAddr |} *) ) /\

((*partitionsIsolation s /\
   verticalSharing s /\*)

  pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s) /\
 bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s /\
StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots /\

      pdentryNbFreeSlots pdinsertion currnbfreeslots s /\
      currnbfreeslots > 0 /\ consistency s (* /\ isBE idBlockToShare s *)
/\ isPDT pdinsertion s). intuition.
intro s0. intuition.
		destruct (lookup newBlockEntryAddr (memory s0) beqAddr) eqn:Hlookup.
		destruct v eqn:Hv.
		eapply weaken. apply modify.
		intros. (*instantiate (1:= fun _ s => tt=tt /\ s =s ).*)
instantiate (1:= fun _ s => (*partitionsIsolation s /\ *)
exists pdentry : PDTable, exists bentry : BlockEntry,
(lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry) /\
isPDT pdinsertion s /\
lookup newBlockEntryAddr (memory s) beqAddr = Some (BE bentry) /\
isBE newBlockEntryAddr s (*/\
s = {|
  currentPartition := currentPartition s;
  memory := add pdinsertion
              (PDT
                 {|
                 structure := structure pdentry;
                 firstfreeslot := newFirstFreeSlotAddr;
                 nbfreeslots := predCurrentNbFreeSlots;
                 nbprepare := nbprepare pdentry;
                 parent := parent pdentry;
                 MPU := MPU pdentry |})
					(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry) (write bentry) (exec bentry)
                       (present bentry) true (blockindex bentry)
                       (CBlock startaddr endaddr)))

 (memory s) beqAddr) beqAddr |} *) ) /\

((*partitionsIsolation s /\
   verticalSharing s /\*)

  pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s) /\
 bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s /\
StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots /\

      pdentryNbFreeSlots pdinsertion currnbfreeslots s /\
      currnbfreeslots > 0 /\ consistency s (* /\ isBE idBlockToShare s *)
/\ isPDT pdinsertion s
(*/\ exists pdentry : PDTable,
lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry)*)
). simpl. admit. admit. admit. admit. admit. admit. } intros.

	eapply bindRev.
	{ (** MAL.writeBlockPresentFromBlockEntryAddr **)
		eapply weaken.
		2 : { intros. exact H. }
		unfold MAL.writeBlockAccessibleFromBlockEntryAddr.
		eapply bindRev.
		eapply weaken. apply get.
		intro s. intros. simpl. instantiate (1:= fun s s0 => s = s0 /\
(*partitionsIsolation s /\ *)
exists pdentry : PDTable, exists bentry : BlockEntry,
(lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry) /\
isPDT pdinsertion s /\
lookup newBlockEntryAddr (memory s) beqAddr = Some (BE bentry) /\
isBE newBlockEntryAddr s (*/\
s = {|
  currentPartition := currentPartition s;
  memory := add pdinsertion
              (PDT
                 {|
                 structure := structure pdentry;
                 firstfreeslot := newFirstFreeSlotAddr;
                 nbfreeslots := predCurrentNbFreeSlots;
                 nbprepare := nbprepare pdentry;
                 parent := parent pdentry;
                 MPU := MPU pdentry |})
					(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry) (write bentry) (exec bentry)
                       (present bentry) true (blockindex bentry)
                       (CBlock startaddr endaddr)))

 (memory s) beqAddr) beqAddr |} *) ) /\

((*partitionsIsolation s /\
   verticalSharing s /\*)

  pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s) /\
 bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s /\
StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots /\

      pdentryNbFreeSlots pdinsertion currnbfreeslots s /\
      currnbfreeslots > 0 /\ consistency s (* /\ isBE idBlockToShare s *)
/\ isPDT pdinsertion s). intuition.
intro s0. intuition.
		destruct (lookup newBlockEntryAddr (memory s0) beqAddr) eqn:Hlookup.
		destruct v eqn:Hv.
		eapply weaken. apply modify.
		intros. (*instantiate (1:= fun _ s => tt=tt /\ s =s ).*)
instantiate (1:= fun _ s => (*partitionsIsolation s /\ *)
exists pdentry : PDTable, exists bentry : BlockEntry,
(lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry) /\
isPDT pdinsertion s /\
lookup newBlockEntryAddr (memory s) beqAddr = Some (BE bentry) /\
isBE newBlockEntryAddr s (*/\
s = {|
  currentPartition := currentPartition s;
  memory := add pdinsertion
              (PDT
                 {|
                 structure := structure pdentry;
                 firstfreeslot := newFirstFreeSlotAddr;
                 nbfreeslots := predCurrentNbFreeSlots;
                 nbprepare := nbprepare pdentry;
                 parent := parent pdentry;
                 MPU := MPU pdentry |})
					(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry) (write bentry) (exec bentry)
                       true true (blockindex bentry)
                       (CBlock startaddr endaddr)))

 (memory s) beqAddr) beqAddr |} *) ) /\

((*partitionsIsolation s /\
   verticalSharing s /\*)

  pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s) /\
 bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s /\
StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots /\

      pdentryNbFreeSlots pdinsertion currnbfreeslots s /\
      currnbfreeslots > 0 /\ consistency s (* /\ isBE idBlockToShare s *)
/\ isPDT pdinsertion s
(*/\ exists pdentry : PDTable,
lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry)*)
). simpl. admit. admit. admit. admit. admit. admit. } intros.

	eapply bindRev.
	{ (** MAL.writeBlockRFromBlockEntryAddr **)
		eapply weaken.
		2 : { intros. exact H. }
		unfold MAL.writeBlockRFromBlockEntryAddr.
		eapply bindRev.
		eapply weaken. apply get.
		intro s. intros. simpl. instantiate (1:= fun s s0 => s = s0 /\
(*partitionsIsolation s /\ *)
exists pdentry : PDTable, exists bentry : BlockEntry,
(lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry) /\
isPDT pdinsertion s /\
lookup newBlockEntryAddr (memory s) beqAddr = Some (BE bentry) /\
isBE newBlockEntryAddr s (*/\
s = {|
  currentPartition := currentPartition s;
  memory := add pdinsertion
              (PDT
                 {|
                 structure := structure pdentry;
                 firstfreeslot := newFirstFreeSlotAddr;
                 nbfreeslots := predCurrentNbFreeSlots;
                 nbprepare := nbprepare pdentry;
                 parent := parent pdentry;
                 MPU := MPU pdentry |})
					(add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read bentry) (write bentry) (exec bentry)
                       true true (blockindex bentry)
                       (CBlock startaddr endaddr)))

 (memory s) beqAddr) beqAddr |} *) ) /\

((*partitionsIsolation s /\
   verticalSharing s /\*)

  pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s) /\
 bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s /\
StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots /\

      pdentryNbFreeSlots pdinsertion currnbfreeslots s /\
      currnbfreeslots > 0 /\ consistency s (* /\ isBE idBlockToShare s *)
/\ isPDT pdinsertion s). intuition.
intro s0. intuition.
		destruct (lookup newBlockEntryAddr (memory s0) beqAddr) eqn:Hlookup.
		destruct v eqn:Hv.
		eapply weaken. apply modify.
		intros. (*instantiate (1:= fun _ s => tt=tt /\ s =s ).*)
instantiate (1:= fun _ s => (*partitionsIsolation s /\ *)
exists pdentry : PDTable, exists bentry : BlockEntry,
(lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry) /\
isPDT pdinsertion s /\
lookup newBlockEntryAddr (memory s) beqAddr = Some (BE bentry) /\
isBE newBlockEntryAddr s (*/\
s = {|
  currentPartition := currentPartition s;
  memory := add pdinsertion
              (PDT
                 {|
                 structure := structure pdentry;
                 firstfreeslot := newFirstFreeSlotAddr;
                 nbfreeslots := predCurrentNbFreeSlots;
                 nbprepare := nbprepare pdentry;
                 parent := parent pdentry;
                 MPU := MPU pdentry |})
					(add newBlockEntryAddr
                 (BE
                    (CBlockEntry r (write bentry) (exec bentry)
                       true true (blockindex bentry)
                       (CBlock startaddr endaddr)))

 (memory s) beqAddr) beqAddr |} *) ) /\

((*partitionsIsolation s /\
   verticalSharing s /\*)

  pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s) /\
 bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s /\
StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots /\

      pdentryNbFreeSlots pdinsertion currnbfreeslots s /\
      currnbfreeslots > 0 /\ consistency s(*  /\ isBE idBlockToShare s *)
/\ isPDT pdinsertion s
(*/\ exists pdentry : PDTable,
lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry)*)
). simpl. admit. admit. admit. admit. admit. admit. } intros.


	eapply bindRev.
	{ (** MAL.writeBlockWFromBlockEntryAddr **)
		eapply weaken.
		2 : { intros. exact H. }
		unfold MAL.writeBlockWFromBlockEntryAddr.
		eapply bindRev.
		eapply weaken. apply get.
		intro s. intros. simpl. instantiate (1:= fun s s0 => s = s0 /\
(*partitionsIsolation s /\ *)
exists pdentry : PDTable, exists bentry : BlockEntry,
(lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry) /\
isPDT pdinsertion s /\
lookup newBlockEntryAddr (memory s) beqAddr = Some (BE bentry) /\
isBE newBlockEntryAddr s (*/\
s = {|
  currentPartition := currentPartition s;
  memory := add pdinsertion
              (PDT
                 {|
                 structure := structure pdentry;
                 firstfreeslot := newFirstFreeSlotAddr;
                 nbfreeslots := predCurrentNbFreeSlots;
                 nbprepare := nbprepare pdentry;
                 parent := parent pdentry;
                 MPU := MPU pdentry |})
					(add newBlockEntryAddr
                 (BE
                    (CBlockEntry r (write bentry) (exec bentry)
                       true true (blockindex bentry)
                       (CBlock startaddr endaddr)))

 (memory s) beqAddr) beqAddr |} *) ) /\

((*partitionsIsolation s /\
   verticalSharing s /\*)

  pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s) /\
 bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s /\
StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots /\

      pdentryNbFreeSlots pdinsertion currnbfreeslots s /\
      currnbfreeslots > 0 /\ consistency s (* /\ isBE idBlockToShare s *)
/\ isPDT pdinsertion s). intuition.
intro s0. intuition.
		destruct (lookup newBlockEntryAddr (memory s0) beqAddr) eqn:Hlookup.
		destruct v eqn:Hv.
		eapply weaken. apply modify.
		intros. (*instantiate (1:= fun _ s => tt=tt /\ s =s ).*)
instantiate (1:= fun _ s => (*partitionsIsolation s /\ *)
exists pdentry : PDTable, exists bentry : BlockEntry,
(lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry) /\
isPDT pdinsertion s /\
lookup newBlockEntryAddr (memory s) beqAddr = Some (BE bentry) /\
isBE newBlockEntryAddr s (*/\
s = {|
  currentPartition := currentPartition s;
  memory := add pdinsertion
              (PDT
                 {|
                 structure := structure pdentry;
                 firstfreeslot := newFirstFreeSlotAddr;
                 nbfreeslots := predCurrentNbFreeSlots;
                 nbprepare := nbprepare pdentry;
                 parent := parent pdentry;
                 MPU := MPU pdentry |})
					(add newBlockEntryAddr
                 (BE
                    (CBlockEntry r w (exec bentry)
                       true true (blockindex bentry)
                       (CBlock startaddr endaddr)))

 (memory s) beqAddr) beqAddr |} *) ) /\

((*partitionsIsolation s /\
   verticalSharing s /\*)

  pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s) /\
 bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s /\
StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots /\

      pdentryNbFreeSlots pdinsertion currnbfreeslots s /\
      currnbfreeslots > 0 /\ consistency s (* /\ isBE idBlockToShare s *)
/\ isPDT pdinsertion s
(*/\ exists pdentry : PDTable,
lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry)*)
). simpl. admit. admit. admit. admit. admit. admit. } intros.



	eapply bindRev.
	{ (** MAL.writeBlockXFromBlockEntryAddr **)
		eapply weaken.
		2 : { intros. exact H. }
		unfold MAL.writeBlockXFromBlockEntryAddr.
		eapply bindRev.
		eapply weaken. apply get.
		intro s. intros. simpl. instantiate (1:= fun s s0 => s = s0 /\
(*partitionsIsolation s /\ *)
exists pdentry : PDTable, exists bentry : BlockEntry,
(lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry) /\
isPDT pdinsertion s /\
lookup newBlockEntryAddr (memory s) beqAddr = Some (BE bentry) /\
isBE newBlockEntryAddr s (*/\
s = {|
  currentPartition := currentPartition s;
  memory := add pdinsertion
              (PDT
                 {|
                 structure := structure pdentry;
                 firstfreeslot := newFirstFreeSlotAddr;
                 nbfreeslots := predCurrentNbFreeSlots;
                 nbprepare := nbprepare pdentry;
                 parent := parent pdentry;
                 MPU := MPU pdentry |})
					(add newBlockEntryAddr
                 (BE
                    (CBlockEntry r w (exec bentry)
                       true true (blockindex bentry)
                       (CBlock startaddr endaddr)))

 (memory s) beqAddr) beqAddr |} *) ) /\

((*partitionsIsolation s /\
   verticalSharing s /\*)

  pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s) /\
 bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s /\
StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots /\

      pdentryNbFreeSlots pdinsertion currnbfreeslots s /\
      currnbfreeslots > 0 /\ consistency s (* /\ isBE idBlockToShare s *)
/\ isPDT pdinsertion s). intuition.
intro s0. intuition.
		destruct (lookup newBlockEntryAddr (memory s0) beqAddr) eqn:Hlookup.
		destruct v eqn:Hv.
		eapply weaken. apply modify.
		intros. (*instantiate (1:= fun _ s => tt=tt /\ s =s ).*)
instantiate (1:= fun _ s => (*partitionsIsolation s /\ *)
exists pdentry : PDTable, exists bentry : BlockEntry,
(lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry) /\
isPDT pdinsertion s /\
lookup newBlockEntryAddr (memory s) beqAddr = Some (BE bentry) /\
isBE newBlockEntryAddr s (*/\
s = {|
  currentPartition := currentPartition s;
  memory := add pdinsertion
              (PDT
                 {|
                 structure := structure pdentry;
                 firstfreeslot := newFirstFreeSlotAddr;
                 nbfreeslots := predCurrentNbFreeSlots;
                 nbprepare := nbprepare pdentry;
                 parent := parent pdentry;
                 MPU := MPU pdentry |})
					(add newBlockEntryAddr
                 (BE
                    (CBlockEntry r w e
                       true true (blockindex bentry)
                       (CBlock startaddr endaddr)))

 (memory s) beqAddr) beqAddr |} *) ) /\

((*partitionsIsolation s /\
   verticalSharing s /\*)

  pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s) /\
 bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s /\
StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots /\

      pdentryNbFreeSlots pdinsertion currnbfreeslots s /\
      currnbfreeslots > 0 /\ consistency s (* /\ isBE idBlockToShare s *)
/\ isPDT pdinsertion s
(*/\ exists pdentry : PDTable,
lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry)*)
). simpl. admit. admit. admit. admit. admit. admit. } intros.

	eapply bindRev.
	{ (** MAL.writeSCOriginFromBlockEntryAddr **)
		unfold MAL.writeSCOriginFromBlockEntryAddr.
		eapply bindRev.
		{ (** MAL.getSCEntryAddrFromBlockEntryAddr **)
			eapply weaken. apply getSCEntryAddrFromBlockEntryAddr.
			intros. split. apply H. unfold consistency in *. intuition.
			admit. admit. admit.
		}
		intro SCEAddr.
				unfold MAL.writeSCOriginFromBlockEntryAddr2.
			eapply bindRev.
		eapply weaken. apply get.
		intro s. intros. simpl. instantiate (1:= fun s s0 => s = s0 /\
(*partitionsIsolation s /\ *)
exists pdentry : PDTable, exists bentry : BlockEntry,
(lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry) /\
isPDT pdinsertion s /\
lookup newBlockEntryAddr (memory s) beqAddr = Some (BE bentry) /\
isBE newBlockEntryAddr s (*/\
s = {|
  currentPartition := currentPartition s;
  memory := add pdinsertion
              (PDT
                 {|
                 structure := structure pdentry;
                 firstfreeslot := newFirstFreeSlotAddr;
                 nbfreeslots := predCurrentNbFreeSlots;
                 nbprepare := nbprepare pdentry;
                 parent := parent pdentry;
                 MPU := MPU pdentry |})
					(add newBlockEntryAddr
                 (BE
                    (CBlockEntry r w e
                       true true (blockindex bentry)
                       (CBlock startaddr endaddr)))

 (memory s) beqAddr) beqAddr |} *)) /\

((*partitionsIsolation s /\
   verticalSharing s /\*)

  pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s) /\
 bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s /\
StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots /\

      pdentryNbFreeSlots pdinsertion currnbfreeslots s /\
      currnbfreeslots > 0 /\ consistency s (* /\ isBE idBlockToShare s *)
/\ isPDT pdinsertion s /\
(exists entry : SCEntry,
       lookup SCEAddr (memory s) beqAddr = Some (SCE entry) /\
       scentryAddr newBlockEntryAddr SCEAddr s)
). intuition. destruct H0. destruct H. exists x. exists x0.
intuition.
intro s0. intuition.
		destruct (lookup SCEAddr (memory s0) beqAddr) eqn:Hlookup.
		destruct v eqn:Hv.
	3 : {
		eapply weaken. apply modify.
		intros. (*instantiate (1:= fun _ s => tt=tt /\ s =s ).*)
(*instantiate (1:= fun _ st =>
partitionsIsolation st /\
exists pdentry : PDTable, exists bentry : BlockEntry, exists scentry : SCEntry,
(lookup pdinsertion (memory st) beqAddr = Some (PDT pdentry) /\
isPDT pdinsertion st /\
lookup newBlockEntryAddr (memory st) beqAddr = Some (BE bentry) /\
isBE newBlockEntryAddr st /\
st = {|
  currentPartition := currentPartition st;
  memory := add pdinsertion
              (PDT
                 {|
                 structure := structure pdentry;
                 firstfreeslot := newFirstFreeSlotAddr;
                 nbfreeslots := predCurrentNbFreeSlots;
                 nbprepare := nbprepare pdentry;
                 parent := parent pdentry;
                 MPU := MPU pdentry |})
					(add newBlockEntryAddr
                 (BE
                    (CBlockEntry r w e
                       true true (blockindex bentry)
                       (CBlock startaddr endaddr)))

 (memory st) beqAddr) beqAddr |}) /\

(partitionsIsolation st /\
   verticalSharing st /\

  pdentryFirstFreeSlot pdinsertion newBlockEntryAddr st) /\
 bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr st /\
StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots /\

      pdentryNbFreeSlots pdinsertion currnbfreeslots st /\
      currnbfreeslots > 0 /\ consistency st /\ isBE idBlockToShare st /\
(exists sceaddr : paddr, isSCE sceaddr st /\
scentryAddr newBlockEntryAddr sceaddr st /\
lookup sceaddr (memory st) beqAddr = Some (SCE scentry))).*)

instantiate (1:= fun _ s =>
(*partitionsIsolation s /\ *)
exists pdentry : PDTable, exists bentry : BlockEntry,
exists scentry : SCEntry, exists sceaddr : paddr,
(lookup pdinsertion (memory s) beqAddr = Some (PDT pdentry) /\
isPDT pdinsertion s /\
lookup newBlockEntryAddr (memory s) beqAddr = Some (BE bentry) /\
isBE newBlockEntryAddr s /\
lookup sceaddr (memory s) beqAddr = Some (SCE scentry) /\
isSCE sceaddr s /\
scentryAddr newBlockEntryAddr sceaddr s /\
s = {|
  currentPartition := currentPartition s;
  memory := add pdinsertion
              (PDT
                 {|
                 structure := structure pdentry;
                 firstfreeslot := newFirstFreeSlotAddr;
                 nbfreeslots := predCurrentNbFreeSlots;
                 nbprepare := nbprepare pdentry;
                 parent := parent pdentry;
                 MPU := MPU pdentry |})
					(add newBlockEntryAddr
                 (BE
                    (CBlockEntry r w e
                       true true (blockindex bentry)
                       (CBlock startaddr endaddr)))


				(add sceaddr (SCE {| origin := origin; next := next scentry |})
 (memory s) beqAddr) beqAddr) beqAddr |} ) /\
(*add SCEAddr (SCE {| origin := origin; next := next scentry |})
                 (memory s) beqAddr |})*)
((*partitionsIsolation s /\
   verticalSharing s /\*)

  pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s) /\
 bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s /\
StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots /\

      pdentryNbFreeSlots pdinsertion currnbfreeslots s /\
      currnbfreeslots > 0 /\ consistency s (* /\ isBE idBlockToShare s *)
/\ isPDT pdinsertion s

). intros. simpl. set (s' := {|
      currentPartition :=  _|}).
		 (*split.
		- admit.*)
		- eexists. eexists. eexists. eexists. split. repeat rewrite beqAddrTrue. cbn. split.
			+ f_equal.
			+ (*split.*) unfold isPDT. cbn. rewrite beqAddrTrue. trivial.
				(*cbn. admit.*)
			+ admit.



admit. } admit. admit. admit. admit. admit. }
	intros.
	{ (** ret **)
	eapply weaken. apply ret. intros. simpl. intuition.
	admit. admit. admit.
Admitted.

(*


	intros. split. reflexivity. split.
	admit. intuition.
	unfold bentryEndAddr. cbn.
	assert (pdinsertion <> newBlockEntryAddr). admit.
	rewrite beqAddrFalse in *. cbn. simpl. rewrite H5. rewrite removeDupIdentity.
	unfold bentryEndAddr in H3. subst. destruct (lookup newBlockEntryAddr (memory s) beqAddr) eqn:Hlookup' ; try (exfalso ; congruence).
	destruct v eqn:Hv0 ; try (exfalso ; congruence). intuition. rewrite <- beqAddrFalse in *. intuition.
admit. admit. admit. admit. admit. } admit. admit. admit. admit. admit. }
	intros. simpl.



(((partitionsIsolation s /\
   verticalSharing s /\
   (exists pdentry : PDTable,
      Some (PDT p) = Some (PDT pdentry) /\
      pdentryNbFreeSlots pdinsertion currnbfreeslots s /\
      currnbfreeslots > 0 /\ consistency s /\ isBE idBlockToShare s)) /\
  pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s) /\
 bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s) /\
StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots). intuition.





		instantiate (1:= forall s, s =  {|
  currentPartition := currentPartition s;
  memory := add pdinsertion
              (PDT
                 {|
                 structure := structure p;
                 firstfreeslot := newFirstFreeSlotAddr;
                 nbfreeslots := nbfreeslots p;
                 nbprepare := nbprepare p;
                 parent := parent p;
                 MPU := MPU p |}) (memory s) beqAddr |}). /\

    (((partitionsIsolation s0 /\
       verticalSharing s0 /\
       (exists pdentry : PDTable,
          Some (PDT p) = Some (PDT pdentry) /\
          pdentryNbFreeSlots pdinsertion currnbfreeslots s0 /\
          currnbfreeslots > 0 /\ consistency s0 /\ isBE idBlockToShare s0)) /\
      pdentryFirstFreeSlot pdinsertion newBlockEntryAddr s0) /\
     bentryEndAddr newBlockEntryAddr newFirstFreeSlotAddr s0) /\
    StateLib.Index.pred currnbfreeslots = Some predCurrentNbFreeSlots
).
		apply H.
		try (apply undefined ; congruence).
		try (apply undefined ; congruence).
		intros.  simpl.
		unfold Monad.modify.
		eapply bindRev. apply get. intro s0.



eapply weaken. apply WP.writePDFirstFreeSlotPointer.
		intros. simpl.
		eexists. split.
		- intuition. destruct H5. Set Printing All. instantiate (1:=
                 fun tt => {|
                 structure := structure x;
                 firstfreeslot := firstfreeslot x (*newFirstFreeSlotAddr*);
                 nbfreeslots := nbfreeslots x;
                 nbprepare := nbprepare x;
                 parent := parent x;
                 MPU := MPU x |}).
	}
(*{ (** writePDFirstFreeSlotPointer **)
	eapply weaken.
	apply Invariants.writePDFirstFreeSlotPointer.
	intros. simpl. intuition.
	- unfold isPDT. destruct H5. intuition. rewrite H5. trivial.
	- destruct H5. intuition.
}
	intros. simpl.
	eapply bindRev. (* ajouter propagation de props *)
	{ (** MAL.writePDNbFreeSlots **)
		eapply weaken. apply Invariants.writePDNbFreeSlots.
		intros. simpl. destruct H. intuition.
		- unfold isPDT. rewrite H0; trivial.
	}
	intros.
	eapply bindRev.
	{ (** MAL.writeBlockStartFromBlockEntryAddr **)
		eapply weaken. apply Invariants.writeBlockStartFromBlockEntryAddr.
		intros. simpl. destruct H. intuition.
		unfold isBE. admit.
	} intros.*)


unfold partitionsIsolation. intros. simpl.
	unfold getUsedBlocks. unfold getConfigBlocks.
	unfold getMappedBlocks. set (s' := {|
       currentPartition := currentPartition s;
       memory := _ |}).
	congruence.
	split.
- unfold verticalSharing. intros. simpl.
	unfold getUsedBlocks. unfold getConfigBlocks.
	unfold getMappedBlocks.
	set (s' := {|
       currentPartition := currentPartition s;
       memory := _ |}) in *.
	destruct (lookup child (memory s') beqAddr) ; congruence.
- split. split. unfold wellFormedFstShadowIfBlockEntry. intros. simpl.
	unfold isSHE. intros.
	destruct (  lookup (CPaddr (pa + sh1offset))
    (memory
       {|
       currentPartition := currentPartition s;
       memory := add pdinsertion
                   (PDT
                      {|
                      structure := structure x;
                      firstfreeslot := endAddr (blockrange x0);
                      nbfreeslots := {| i := currnbfreeslots - 1; Hi := Hi |};
                      nbprepare := nbprepare x;
                      parent := parent x;
                      MPU := MPU x |})
                   (add pdinsertion
                      (PDT
                         {|
                         structure := structure x;
                         firstfreeslot := endAddr (blockrange x0);
                         nbfreeslots := nbfreeslots x;
                         nbprepare := nbprepare x;
                         parent := parent x;
                         MPU := MPU x |}) (memory s) beqAddr) beqAddr |}) beqAddr).
	destruct v. congruence. intuition. congruence. congruence. congruence. congruence.
	split. unfold PDTIfPDFlag. intros. exists x0. split.
	destruct x0. simpl in *. rewrite beqAddrTrue. subst. rewrite removeDupIdentity.
	destruct (beqAddr pdinsertion idPDchild).
	simpl. congruence. congruence. congruence.
	unfold entryPDT. destruct (lookup idPDchild
    (memory
       {|
       currentPartition := currentPartition s;
       memory := add pdinsertion
                   (PDT
                      {|
                      structure := structure
                                     {|
                                     structure := structure x;
                                     firstfreeslot := endAddr (blockrange x0);
                                     nbfreeslots := nbfreeslots x;
                                     nbprepare := nbprepare x;
                                     parent := parent x;
                                     MPU := MPU x |};
                      firstfreeslot := firstfreeslot
                                         {|
                                         structure := structure x;
                                         firstfreeslot := endAddr (blockrange x0);
                                         nbfreeslots := nbfreeslots x;
                                         nbprepare := nbprepare x;
                                         parent := parent x;
                                         MPU := MPU x |};
                      nbfreeslots := {| i := currnbfreeslots - 1; Hi := Hi |};
                      nbprepare := nbprepare
                                     {|
                                     structure := structure x;
                                     firstfreeslot := endAddr (blockrange x0);
                                     nbfreeslots := nbfreeslots x;
                                     nbprepare := nbprepare x;
                                     parent := parent x;
                                     MPU := MPU x |};
                      parent := parent
                                  {|
                                  structure := structure x;
                                  firstfreeslot := endAddr (blockrange x0);
                                  nbfreeslots := nbfreeslots x;
                                  nbprepare := nbprepare x;
                                  parent := parent x;
                                  MPU := MPU x |};
                      MPU := MPU
                               {|
                               structure := structure x;
                               firstfreeslot := endAddr (blockrange x0);
                               nbfreeslots := nbfreeslots x;
                               nbprepare := nbprepare x;
                               parent := parent x;
                               MPU := MPU x |} |})
                   (add pdinsertion
                      (PDT
                         {|
                         structure := structure x;
                         firstfreeslot := endAddr (blockrange x0);
                         nbfreeslots := nbfreeslots x;
                         nbprepare := nbprepare x;
                         parent := parent x;
                         MPU := MPU x |}) (memory s) beqAddr) beqAddr |}) beqAddr).
	destruct v ; congruence. congruence.
	split. unfold nullAddrExists. simpl. intros. unfold getNullAddr.
	destruct (lookup nullAddr
  (memory
     {|
     currentPartition := currentPartition s;
     memory := add pdinsertion
                 (PDT
                    {|
                    structure := structure x;
                    firstfreeslot := endAddr (blockrange x0);
                    nbfreeslots := {| i := currnbfreeslots - 1; Hi := Hi |};
                    nbprepare := nbprepare x;
                    parent := parent x;
                    MPU := MPU x |})
                 (add pdinsertion
                    (PDT
                       {|
                       structure := structure x;
                       firstfreeslot := endAddr (blockrange x0);
                       nbfreeslots := nbfreeslots x;
                       nbprepare := nbprepare x;
                       parent := parent x;
                       MPU := MPU x |}) (memory s) beqAddr) beqAddr |}) beqAddr).
	congruence. congruence.
split. intros. simpl.
	exists x0. rewrite removeDupDupIdentity. rewrite removeDupIdentity.
	destruct (beqAddr pdinsertion (firstfreeslot entry)) eqn:Hbeq ; congruence.
	congruence. congruence. congruence.
	unfold isBE.
	destruct (lookup idBlockToShare
    (memory
       {|
       currentPartition := currentPartition s;
       memory := add pdinsertion
                   (PDT
                      {|
                      structure := structure
                                     {|
                                     structure := structure x;
                                     firstfreeslot := endAddr
                                              (blockrange x0);
                                     nbfreeslots := nbfreeslots x;
                                     nbprepare := nbprepare x;
                                     parent := parent x;
                                     MPU := MPU x |};
                      firstfreeslot := firstfreeslot
                                         {|
                                         structure := structure x;
                                         firstfreeslot := endAddr
                                              (blockrange x0);
                                         nbfreeslots := nbfreeslots x;
                                         nbprepare := nbprepare x;
                                         parent := parent x;
                                         MPU := MPU x |};
                      nbfreeslots := {|
                                     i := currnbfreeslots - 1;
                                     Hi := Hi |};
                      nbprepare := nbprepare
                                     {|
                                     structure := structure x;
                                     firstfreeslot := endAddr
                                              (blockrange x0);
                                     nbfreeslots := nbfreeslots x;
                                     nbprepare := nbprepare x;
                                     parent := parent x;
                                     MPU := MPU x |};
                      parent := parent
                                  {|
                                  structure := structure x;
                                  firstfreeslot := endAddr
                                              (blockrange x0);
                                  nbfreeslots := nbfreeslots x;
                                  nbprepare := nbprepare x;
                                  parent := parent x;
                                  MPU := MPU x |};
                      MPU := MPU
                               {|
                               structure := structure x;
                               firstfreeslot := endAddr (blockrange x0);
                               nbfreeslots := nbfreeslots x;
                               nbprepare := nbprepare x;
                               parent := parent x;
                               MPU := MPU x |} |})
                   (add pdinsertion
                      (PDT
                         {|
                         structure := structure x;
                         firstfreeslot := endAddr (blockrange x0);
                         nbfreeslots := nbfreeslots x;
                         nbprepare := nbprepare x;
                         parent := parent x;
                         MPU := MPU x |}) (memory s) beqAddr) beqAddr |})
    beqAddr) ; congruence.

Qed.




(*
unfold add. simpl. rewrite beqAddrTrue. simpl.
	assert (
forall addr pe1 pointer, lookup addr (memory s) beqAddr = Some (PDT pe1) ->
exists pe2,
          lookup addr  (add addr
       (PDT
          {|
          structure := structure pe1;
              firstfreeslot := pointer;
              nbfreeslots := nbfreeslots pe1;
              nbprepare := nbprepare pe1;
              parent := parent pe1;
              MPU := MPU pe1 |}) (memory s) beqAddr) beqAddr  = Some (PDT pe2)

).
{
	intros . cbn. rewrite beqAddrTrue.
	eexists. f_equal.
}
	specialize (H9 pdinsertion x (endAddr (blockrange x0)) H0).
	exact H9.
  rewrite  Hmemory. eassumption.}
	rewrite removeDupDupIdentity.
 apply removeDupIdentity.


(*simpl. intuition.
destruct H4. exists x. intuition.
eexists. simpl.
unfold beqAddr.
rewrite PeanoNat.Nat.eqb_refl.
simpl.
split.
- f_equal.
- eexists. split.
	assert (PeanoNat.Nat.eqb pdinsertion newBlockEntryAddr = false).
	unfold entryEndAddr in *. unfold entryFirstFreeSlot in *.
	rewrite H4 in H3. subst.
	rewrite PeanoNat.Nat.eqb_neq.
	Search (lookup).
	destruct (lookup (firstfreeslot x) (memory s) beqAddr) eqn:Hfalse.
	destruct v eqn:Hv.
	unfold not. intro. subst. rewrite H0 in Hfalse. Set Printing All.
	(* Prouver que lookup addr = Some PDT et lookup addr = Some BE -> False*)
Search ( PeanoNat.Nat.eqb ?x ?y = false).*)
	intuition. destruct H4. exists x. rewrite beqAddrTrue. split.	apply H0.
	eexists. split. simpl. f_equal.
	(*eexists. split.*)
	simpl. rewrite beqAddrTrue. simpl.
	(* newblockEntryAddr is the free slot pointer in PDT, we know it's a BE from consistency*)
	assert (beqAddr pdinsertion newBlockEntryAddr = false).
	{ apply beqAddrFalse. unfold not.
		intros.
		unfold entryEndAddr in *. unfold entryFirstFreeSlot in *.
		destruct H0.
		rewrite H0 in H3. subst.
		destruct H5. unfold consistency in *. unfold FirstFreeSlotPointerIsBE in *.
		intuition. specialize (H7 (firstfreeslot x) x).
		rewrite H0 in H7. destruct H7. reflexivity. congruence.
	}
		rewrite H4. simpl.
		rewrite removeDupDupIdentity. rewrite removeDupIdentity.
		unfold entryFirstFreeSlot in *.
		destruct H0. rewrite H0 in H3.
		unfold consistency in *. unfold FirstFreeSlotPointerIsBE in *.
		destruct H5.
		intuition.
		specialize (H9 pdinsertion x H0).
		destruct H9.
		subst. exists x0. split.	rewrite H9. reflexivity.
		eexists ?[newentry]. split. f_equal. simpl.

		(*simpl. induction x0. simpl.
			intuition. cbn. unfold CBlockEntry.
			destruct (lt_dec blockindex kernelStructureEntriesNb) ; simpl.
			destruct (lt_dec blockindex kernelStructureEntriesNb) ; simpl.
			unfold CBlock. simpl. destruct (lt_dec startaddr (endAddr blockrange) ) ; simpl.
			destruct (lt_dec startaddr endaddr) ; simpl.

			eexists. split. f_equal. simpl.*)

		assert (forall x0 : BlockEntry, read
             (CBlockEntry (read x0) (write x0) (exec x0)
                (present x0) (accessible x0) (blockindex x0)
                (CBlock startaddr (endAddr (blockrange x0)))) = read x0).
		{ simpl. induction x0. simpl.
			intuition. cbn. unfold CBlockEntry.
			simpl. destruct (lt_dec (ADT.blockindex x0) kernelStructureEntriesNb).
			simpl. reflexivity.
			congruence.
		}
assert (forall x0 : BlockEntry, write
             (CBlockEntry (read x0) (write x0) (exec x0)
                (present x0) (accessible x0) (blockindex x0)
                (CBlock startaddr (endAddr (blockrange x0)))) = write x0).
		{ simpl. induction x0. simpl.
			intuition. cbn. unfold CBlockEntry.
						simpl. destruct (lt_dec (ADT.blockindex x0) kernelStructureEntriesNb).
			simpl. reflexivity.
			congruence.
		}
assert (forall x0 : BlockEntry, exec
             (CBlockEntry (read x0) (write x0) (exec x0)
                (present x0) (accessible x0) (blockindex x0)
                (CBlock startaddr (endAddr (blockrange x0)))) = exec x0).
		{ simpl. induction x0. simpl.
			intuition. cbn. unfold CBlockEntry.
						simpl. destruct (lt_dec (ADT.blockindex x0) kernelStructureEntriesNb).
			simpl. reflexivity.
			congruence.
		}
assert (forall x0 : BlockEntry, accessible
             (CBlockEntry (read x0) (write x0) (exec x0)
                (present x0) (accessible x0) (blockindex x0)
                (CBlock startaddr (endAddr (blockrange x0)))) = accessible x0).
		{ simpl. induction x0. simpl.
			intuition. cbn. unfold CBlockEntry.
						simpl. destruct (lt_dec (ADT.blockindex x0) kernelStructureEntriesNb).
			simpl. reflexivity.
			congruence.
		}
assert (forall x0 : BlockEntry, present
             (CBlockEntry (read x0) (write x0) (exec x0)
                (present x0) (accessible x0) (blockindex x0)
                (CBlock startaddr (endAddr (blockrange x0)))) = present x0).
		{ simpl. induction x0. simpl.
			intuition. cbn. unfold CBlockEntry.
						simpl. destruct (lt_dec (ADT.blockindex x0) kernelStructureEntriesNb).
			simpl. reflexivity.
			congruence.
		}
		rewrite H3. rewrite H14. rewrite H16. rewrite H17. rewrite H18.

assert (forall x0 : BlockEntry, (blockindex
             (CBlockEntry (read x0) (write x0) (exec x0)
                (present x0) (accessible x0) (blockindex x0)
                (CBlock startaddr (endAddr (blockrange x0))))) = blockindex x0).
		{ simpl. induction x0. simpl.
			intuition. cbn. unfold CBlockEntry.
						simpl. destruct (lt_dec (ADT.blockindex x0) kernelStructureEntriesNb).
			simpl. reflexivity.
			congruence.
		}
		rewrite H19.
		assert(forall x0 : BlockEntry, startAddr
                (blockrange
                   (CBlockEntry (read x0) (write x0) (exec x0)
                      (present x0) (accessible x0) (blockindex x0)
                      (CBlock startaddr (endAddr (blockrange x0))))) = startaddr).
		{ simpl. induction x0. simpl.
			intuition. cbn. unfold CBlockEntry.
						simpl. destruct (lt_dec (ADT.blockindex x0) kernelStructureEntriesNb).
			simpl. unfold CBlock.  destruct (lt_dec startaddr (endAddr (ADT.blockrange x0))).
			simpl. reflexivity.
			congruence.
			simpl. congruence.
}
	rewrite H20.

		eexists. split. f_equal.
		eexists. split. simpl.
		assert (forall x0 : BlockEntry, (read
           (CBlockEntry (read x0) (write x0) (exec x0) (present x0)
              (accessible x0) (blockindex x0) (CBlock startaddr endaddr))) = read x0).
		{ simpl. induction x0. simpl.
			intuition. cbn. unfold CBlockEntry.
						simpl. destruct (lt_dec (ADT.blockindex x0) kernelStructureEntriesNb).
			simpl. reflexivity. congruence.
}
			assert (forall x0 : BlockEntry, (write
           (CBlockEntry (read x0) (write x0) (exec x0) (present x0)
              (accessible x0) (blockindex x0) (CBlock startaddr endaddr))) = write x0).
		{ simpl. induction x0. simpl.
			intuition. cbn. unfold CBlockEntry.
						simpl. destruct (lt_dec (ADT.blockindex x0) kernelStructureEntriesNb).
			simpl. reflexivity. congruence.
}
			assert (forall x0 : BlockEntry, (exec
           (CBlockEntry (read x0) (write x0) (exec x0) (present x0)
              (accessible x0) (blockindex x0) (CBlock startaddr endaddr))) = exec x0).
		{ simpl. induction x0. simpl.
			intuition. cbn. unfold CBlockEntry.
						simpl. destruct (lt_dec (ADT.blockindex x0) kernelStructureEntriesNb).
			simpl. reflexivity. congruence.
}
			assert (forall x0 : BlockEntry, (present
           (CBlockEntry (read x0) (write x0) (exec x0) (present x0)
              (accessible x0) (blockindex x0) (CBlock startaddr endaddr))) = present x0).
		{ simpl. induction x0. simpl.
			intuition. cbn. unfold CBlockEntry.
						simpl. destruct (lt_dec (ADT.blockindex x0) kernelStructureEntriesNb).
			simpl. reflexivity. congruence.
}
			assert (forall x0 : BlockEntry, (accessible
           (CBlockEntry (read x0) (write x0) (exec x0) (present x0)
              (accessible x0) (blockindex x0) (CBlock startaddr endaddr))) = accessible x0).
		{ simpl. induction x0. simpl.
			intuition. cbn. unfold CBlockEntry.
						simpl. destruct (lt_dec (ADT.blockindex x0) kernelStructureEntriesNb).
			simpl. reflexivity. congruence.
}

rewrite H21, H22, H23, H24. f_equal.


			unfold CBlockEntry.
						simpl. destruct (lt_dec (blockindex x0) kernelStructureEntriesNb).
			simpl. destruct (lt_dec (blockindex x0) kernelStructureEntriesNb).
			simpl.


unfold CBlock.  destruct (lt_dec startaddr (endAddr (ADT.blockrange x0))).
			simpl. reflexivity.
			congruence.
			simpl. congruence.


			destruct CBlockEntry. simpl.
		exists entry.

		assert (exists entry1 : BlockEntry, CBlockEntry (read x1) (write x1) (exec x1) (present x1)
          (accessible x1) (blockindex x1)
          (CBlock startaddr (endAddr (blockrange x1))) = Some (entry)).

                   {|
                   currentPartition := currentPartition s;
                   memory := add newBlockEntryAddr
                                              (BE
                                                 (CBlockEntry
                                                    (read entry)
                                                    (write entry)
                                                    (exec entry)
                                                    (present entry)
                                                    (accessible entry)
                                                    (blockindex entry)
                                                    (CBlock
                                                       (startAddr (blockrange entry))
                                                       endaddr)))
		eexists. split. f_equal.
		eexists. split. f_equal.
		2 : { apply beqAddrFalse in H4. intuition. }
		2 :{ apply beqAddrFalse in H4. intuition. }
		eexists. split. f_equal.
		eexists. split. f_equal.
		Definition foo (x : nat) : nat := ltac:(exact x).
		exists foo.
		set (s' := add newBlockEntryAddr
                         (BE
                            (CBlockEntry (read entry2) (write entry2) e
                               (present entry2) (accessible entry2)
                               (blockindex entry2) (blockrange entry2)))
                         (add newBlockEntryAddr
                            (BE
                               (CBlockEntry (read entry1) w
                                  (exec entry1) (present entry1)
                                  (accessible entry1) (blockindex entry1)
                                  (blockrange entry1)))
                            (add newBlockEntryAddr
                               (BE
                                  (CBlockEntry r (write entry0)
                                     (exec entry0) (present entry0)
                                     (accessible entry0)
                                     (blockindex entry0)
                                     (blockrange entry0)))
                               (add newBlockEntryAddr
                                  (BE
                                     (CBlockEntry (read entry)
                                        (write entry) (exec entry) true
                                        (accessible entry)
                                        (blockindex entry)
                                        (blockrange entry)))
                                  (add newBlockEntryAddr
                                     (BE
                                        (CBlockEntry
                                           (read
                                              (CBlockEntry
                                                 (read
                                                    (CBlockEntry
                                                       (read x1)
                                                       (write x1)
                                                       (exec x1)
                                                       (present x1)
                                                       (accessible x1)
                                                       (blockindex x1)
                                                       (CBlock startaddr
                                                        (endAddr (blockrange x1)))))
                                                 (write
                                                    (CBlockEntry
                                                       (read x1)
                                                       (write x1)
                                                       (exec x1)
                                                       (present x1)
                                                       (accessible x1)
                                                       (blockindex x1)
                                                       (CBlock startaddr
                                                        (endAddr (blockrange x1)))))
                                                 (exec
                                                    (CBlockEntry
                                                       (read x1)
                                                       (write x1)
                                                       (exec x1)
                                                       (present x1)
                                                       (accessible x1)
                                                       (blockindex x1)
                                                       (CBlock startaddr
                                                        (endAddr (blockrange x1)))))
                                                 (present
                                                    (CBlockEntry
                                                       (read x1)
                                                       (write x1)
                                                       (exec x1)
                                                       (present x1)
                                                       (accessible x1)
                                                       (blockindex x1)
                                                       (CBlock startaddr
                                                        (endAddr (blockrange x1)))))
                                                 (accessible
                                                    (CBlockEntry
                                                       (read x1)
                                                       (write x1)
                                                       (exec x1)
                                                       (present x1)
                                                       (accessible x1)
                                                       (blockindex x1)
                                                       (CBlock startaddr
                                                        (endAddr (blockrange x1)))))
                                                 (blockindex
                                                    (CBlockEntry
                                                       (read x1)
                                                       (write x1)
                                                       (exec x1)
                                                       (present x1)
                                                       (accessible x1)
                                                       (blockindex x1)
                                                       (CBlock startaddr
                                                        (endAddr (blockrange x1)))))
                                                 (CBlock
                                                    (startAddr
                                                       (blockrange
                                                        (CBlockEntry
                                                        (read x1)
                                                        (write x1)
                                                        (exec x1)
                                                        (present x1)
                                                        (accessible x1)
                                                        (blockindex x1)
                                                        (CBlock startaddr
                                                        (endAddr (blockrange x1))))))
                                                    endaddr)))
                                           (write
                                              (CBlockEntry
                                                 (read
                                                    (CBlockEntry
                                                       (read x1)
                                                       (write x1)
                                                       (exec x1)
                                                       (present x1)
                                                       (accessible x1)
                                                       (blockindex x1)
                                                       (CBlock startaddr
                                                        (endAddr (blockrange x1)))))
                                                 (write
                                                    (CBlockEntry
                                                       (read x1)
                                                       (write x1)
                                                       (exec x1)
                                                       (present x1)
                                                       (accessible x1)
                                                       (blockindex x1)
                                                       (CBlock startaddr
                                                        (endAddr (blockrange x1)))))
                                                 (exec
                                                    (CBlockEntry
                                                       (read x1)
                                                       (write x1)
                                                       (exec x1)
                                                       (present x1)
                                                       (accessible x1)
                                                       (blockindex x1)
                                                       (CBlock startaddr
                                                        (endAddr (blockrange x1)))))
                                                 (present
                                                    (CBlockEntry
                                                       (read x1)
                                                       (write x1)
                                                       (exec x1)
                                                       (present x1)
                                                       (accessible x1)
                                                       (blockindex x1)
                                                       (CBlock startaddr
                                                        (endAddr (blockrange x1)))))
                                                 (accessible
                                                    (CBlockEntry
                                                       (read x1)
                                                       (write x1)
                                                       (exec x1)
                                                       (present x1)
                                                       (accessible x1)
                                                       (blockindex x1)
                                                       (CBlock startaddr
                                                        (endAddr (blockrange x1)))))
                                                 (blockindex
                                                    (CBlockEntry
                                                       (read x1)
                                                       (write x1)
                                                       (exec x1)
                                                       (present x1)
                                                       (accessible x1)
                                                       (blockindex x1)
                                                       (CBlock startaddr
                                                        (endAddr (blockrange x1)))))
                                                 (CBlock
                                                    (startAddr
                                                       (blockrange
                                                        (CBlockEntry
                                                        (read x1)
                                                        (write x1)
                                                        (exec x1)
                                                        (present x1)
                                                        (accessible x1)
                                                        (blockindex x1)
                                                        (CBlock startaddr
                                                        (endAddr (blockrange x1))))))
                                                    endaddr)))
                                           (exec
                                              (CBlockEntry
                                                 (read
                                                    (CBlockEntry
                                                       (read x1)
                                                       (write x1)
                                                       (exec x1)
                                                       (present x1)
                                                       (accessible x1)
                                                       (blockindex x1)
                                                       (CBlock startaddr
                                                        (endAddr (blockrange x1)))))
                                                 (write
                                                    (CBlockEntry
                                                       (read x1)
                                                       (write x1)
                                                       (exec x1)
                                                       (present x1)
                                                       (accessible x1)
                                                       (blockindex x1)
                                                       (CBlock startaddr
                                                        (endAddr (blockrange x1)))))
                                                 (exec
                                                    (CBlockEntry
                                                       (read x1)
                                                       (write x1)
                                                       (exec x1)
                                                       (present x1)
                                                       (accessible x1)
                                                       (blockindex x1)
                                                       (CBlock startaddr
                                                        (endAddr (blockrange x1)))))
                                                 (present
                                                    (CBlockEntry
                                                       (read x1)
                                                       (write x1)
                                                       (exec x1)
                                                       (present x1)
                                                       (accessible x1)
                                                       (blockindex x1)
                                                       (CBlock startaddr
                                                        (endAddr (blockrange x1)))))
                                                 (accessible
                                                    (CBlockEntry
                                                       (read x1)
                                                       (write x1)
                                                       (exec x1)
                                                       (present x1)
                                                       (accessible x1)
                                                       (blockindex x1)
                                                       (CBlock startaddr
                                                        (endAddr (blockrange x1)))))
                                                 (blockindex
                                                    (CBlockEntry
                                                       (read x1)
                                                       (write x1)
                                                       (exec x1)
                                                       (present x1)
                                                       (accessible x1)
                                                       (blockindex x1)
                                                       (CBlock startaddr
                                                        (endAddr (blockrange x1)))))
                                                 (CBlock
                                                    (startAddr
                                                       (blockrange
                                                        (CBlockEntry
                                                        (read x1)
                                                        (write x1)
                                                        (exec x1)
                                                        (present x1)
                                                        (accessible x1)
                                                        (blockindex x1)
                                                        (CBlock startaddr
                                                        (endAddr (blockrange x1))))))
                                                    endaddr)))
                                           (present
                                              (CBlockEntry
                                                 (read
                                                    (CBlockEntry
                                                       (read x1)
                                                       (write x1)
                                                       (exec x1)
                                                       (present x1)
                                                       (accessible x1)
                                                       (blockindex x1)
                                                       (CBlock startaddr
                                                        (endAddr (blockrange x1)))))
                                                 (write
                                                    (CBlockEntry
                                                       (read x1)
                                                       (write x1)
                                                       (exec x1)
                                                       (present x1)
                                                       (accessible x1)
                                                       (blockindex x1)
                                                       (CBlock startaddr
                                                        (endAddr (blockrange x1)))))
                                                 (exec
                                                    (CBlockEntry
                                                       (read x1)
                                                       (write x1)
                                                       (exec x1)
                                                       (present x1)
                                                       (accessible x1)
                                                       (blockindex x1)
                                                       (CBlock startaddr
                                                        (endAddr (blockrange x1)))))
                                                 (present
                                                    (CBlockEntry
                                                       (read x1)
                                                       (write x1)
                                                       (exec x1)
                                                       (present x1)
                                                       (accessible x1)
                                                       (blockindex x1)
                                                       (CBlock startaddr
                                                        (endAddr (blockrange x1)))))
                                                 (accessible
                                                    (CBlockEntry
                                                       (read x1)
                                                       (write x1)
                                                       (exec x1)
                                                       (present x1)
                                                       (accessible x1)
                                                       (blockindex x1)
                                                       (CBlock startaddr
                                                        (endAddr (blockrange x1)))))
                                                 (blockindex
                                                    (CBlockEntry
                                                       (read x1)
                                                       (write x1)
                                                       (exec x1)
                                                       (present x1)
                                                       (accessible x1)
                                                       (blockindex x1)
                                                       (CBlock startaddr
                                                        (endAddr (blockrange x1)))))
                                                 (CBlock
                                                    (startAddr
                                                       (blockrange
                                                        (CBlockEntry
                                                        (read x1)
                                                        (write x1)
                                                        (exec x1)
                                                        (present x1)
                                                        (accessible x1)
                                                        (blockindex x1)
                                                        (CBlock startaddr
                                                        (endAddr (blockrange x1))))))
                                                    endaddr))) true
                                           (blockindex
                                              (CBlockEntry
                                                 (read
                                                    (CBlockEntry
                                                       (read x1)
                                                       (write x1)
                                                       (exec x1)
                                                       (present x1)
                                                       (accessible x1)
                                                       (blockindex x1)
                                                       (CBlock startaddr
                                                        (endAddr (blockrange x1)))))
                                                 (write
                                                    (CBlockEntry
                                                       (read x1)
                                                       (write x1)
                                                       (exec x1)
                                                       (present x1)
                                                       (accessible x1)
                                                       (blockindex x1)
                                                       (CBlock startaddr
                                                        (endAddr (blockrange x1)))))
                                                 (exec
                                                    (CBlockEntry
                                                       (read x1)
                                                       (write x1)
                                                       (exec x1)
                                                       (present x1)
                                                       (accessible x1)
                                                       (blockindex x1)
                                                       (CBlock startaddr
                                                        (endAddr (blockrange x1)))))
                                                 (present
                                                    (CBlockEntry
                                                       (read x1)
                                                       (write x1)
                                                       (exec x1)
                                                       (present x1)
                                                       (accessible x1)
                                                       (blockindex x1)
                                                       (CBlock startaddr
                                                        (endAddr (blockrange x1)))))
                                                 (accessible
                                                    (CBlockEntry
                                                       (read x1)
                                                       (write x1)
                                                       (exec x1)
                                                       (present x1)
                                                       (accessible x1)
                                                       (blockindex x1)
                                                       (CBlock startaddr
                                                        (endAddr (blockrange x1)))))
                                                 (blockindex
                                                    (CBlockEntry
                                                       (read x1)
                                                       (write x1)
                                                       (exec x1)
                                                       (present x1)
                                                       (accessible x1)
                                                       (blockindex x1)
                                                       (CBlock startaddr
                                                        (endAddr (blockrange x1)))))
                                                 (CBlock
                                                    (startAddr
                                                       (blockrange
                                                        (CBlockEntry
                                                        (read x1)
                                                        (write x1)
                                                        (exec x1)
                                                        (present x1)
                                                        (accessible x1)
                                                        (blockindex x1)
                                                        (CBlock startaddr
                                                        (endAddr (blockrange x1))))))
                                                    endaddr)))
                                           (blockrange
                                              (CBlockEntry
                                                 (read
                                                    (CBlockEntry
                                                       (read x1)
                                                       (write x1)
                                                       (exec x1)
                                                       (present x1)
                                                       (accessible x1)
                                                       (blockindex x1)
                                                       (CBlock startaddr
                                                        (endAddr (blockrange x1)))))
                                                 (write
                                                    (CBlockEntry
                                                       (read x1)
                                                       (write x1)
                                                       (exec x1)
                                                       (present x1)
                                                       (accessible x1)
                                                       (blockindex x1)
                                                       (CBlock startaddr
                                                        (endAddr (blockrange x1)))))
                                                 (exec
                                                    (CBlockEntry
                                                       (read x1)
                                                       (write x1)
                                                       (exec x1)
                                                       (present x1)
                                                       (accessible x1)
                                                       (blockindex x1)
                                                       (CBlock startaddr
                                                        (endAddr (blockrange x1)))))
                                                 (present
                                                    (CBlockEntry
                                                       (read x1)
                                                       (write x1)
                                                       (exec x1)
                                                       (present x1)
                                                       (accessible x1)
                                                       (blockindex x1)
                                                       (CBlock startaddr
                                                        (endAddr (blockrange x1)))))
                                                 (accessible
                                                    (CBlockEntry
                                                       (read x1)
                                                       (write x1)
                                                       (exec x1)
                                                       (present x1)
                                                       (accessible x1)
                                                       (blockindex x1)
                                                       (CBlock startaddr
                                                        (endAddr (blockrange x1)))))
                                                 (blockindex
                                                    (CBlockEntry
                                                       (read x1)
                                                       (write x1)
                                                       (exec x1)
                                                       (present x1)
                                                       (accessible x1)
                                                       (blockindex x1)
                                                       (CBlock startaddr
                                                        (endAddr (blockrange x1)))))
                                                 (CBlock
                                                    (startAddr
                                                       (blockrange
                                                        (CBlockEntry
                                                        (read x1)
                                                        (write x1)
                                                        (exec x1)
                                                        (present x1)
                                                        (accessible x1)
                                                        (blockindex x1)
                                                        (CBlock startaddr
                                                        (endAddr (blockrange x1))))))
                                                    endaddr)))))
                                     (add newBlockEntryAddr
                                        (BE
                                           (CBlockEntry
                                              (read
                                                 (CBlockEntry
                                                    (read x1)
                                                    (write x1)
                                                    (exec x1)
                                                    (present x1)
                                                    (accessible x1)
                                                    (blockindex x1)
                                                    (CBlock startaddr
                                                       (endAddr (blockrange x1)))))
                                              (write
                                                 (CBlockEntry
                                                    (read x1)
                                                    (write x1)
                                                    (exec x1)
                                                    (present x1)
                                                    (accessible x1)
                                                    (blockindex x1)
                                                    (CBlock startaddr
                                                       (endAddr (blockrange x1)))))
                                              (exec
                                                 (CBlockEntry
                                                    (read x1)
                                                    (write x1)
                                                    (exec x1)
                                                    (present x1)
                                                    (accessible x1)
                                                    (blockindex x1)
                                                    (CBlock startaddr
                                                       (endAddr (blockrange x1)))))
                                              (present
                                                 (CBlockEntry
                                                    (read x1)
                                                    (write x1)
                                                    (exec x1)
                                                    (present x1)
                                                    (accessible x1)
                                                    (blockindex x1)
                                                    (CBlock startaddr
                                                       (endAddr (blockrange x1)))))
                                              (accessible
                                                 (CBlockEntry
                                                    (read x1)
                                                    (write x1)
                                                    (exec x1)
                                                    (present x1)
                                                    (accessible x1)
                                                    (blockindex x1)
                                                    (CBlock startaddr
                                                       (endAddr (blockrange x1)))))
                                              (blockindex
                                                 (CBlockEntry
                                                    (read x1)
                                                    (write x1)
                                                    (exec x1)
                                                    (present x1)
                                                    (accessible x1)
                                                    (blockindex x1)
                                                    (CBlock startaddr
                                                       (endAddr (blockrange x1)))))
                                              (CBlock
                                                 (startAddr
                                                    (blockrange
                                                       (CBlockEntry
                                                        (read x1)
                                                        (write x1)
                                                        (exec x1)
                                                        (present x1)
                                                        (accessible x1)
                                                        (blockindex x1)
                                                        (CBlock startaddr
                                                        (endAddr (blockrange x1))))))
                                                 endaddr)))
                                        (add newBlockEntryAddr
                                           (BE
                                              (CBlockEntry
                                                 (read x1)
                                                 (write x1)
                                                 (exec x1)
                                                 (present x1)
                                                 (accessible x1)
                                                 (blockindex x1)
                                                 (CBlock startaddr
                                                    (endAddr (blockrange x1)))))
                                           (add pdinsertion
                                              (PDT
                                                 {|
                                                 structure := structure x;
                                                 firstfreeslot := newFirstFreeSlotAddr;
                                                 nbfreeslots := predCurrentNbFreeSlots;
                                                 nbprepare := nbprepare x;
                                                 parent := parent x;
                                                 MPU := MPU x |})
                                              (add pdinsertion
                                                 (PDT
                                                    {|
                                                    structure := structure x;
                                                    firstfreeslot := newFirstFreeSlotAddr;
                                                    nbfreeslots := nbfreeslots x;
                                                    nbprepare := nbprepare x;
                                                    parent := parent x;
                                                    MPU := MPU x |})
                                                 (memory s) beqAddr) beqAddr) beqAddr)
                                        beqAddr) beqAddr) beqAddr) beqAddr) beqAddr)
                         beqAddr) .
		destruct entry as (_).
		eexists. split. f_equal.
		eexists. split. f_equal.
		eexists. split. f_equal.
		eexists. split. f_equal.
		destruct entry.
		eexists. split. f_equal.
		eexists. split. f_equal.
		eexists. split. f_equal.
		assert (add newBlockEntryAddr
              (BE
                 (CBlockEntry (read x1) (write x1) (exec x1)
                    true true
                    (blockindex x2) (CBlock ((startAddr (blockrange x0) (endAddr (blockrange x))))
              (add newBlockEntryAddr
                 (BE
                    (CBlockEntry (read ?entry2) w (exec ?entry2)
                       (present ?entry2) (accessible ?entry2)
                       (blockindex ?entry2) (blockrange ?entry2)))
                 (add newBlockEntryAddr
                    (BE
                       (CBlockEntry r (write ?entry1) (exec ?entry1)
                          (present ?entry1) (accessible ?entry1)
                          (blockindex ?entry1) (blockrange ?entry1)))
                    (add newBlockEntryAddr
                       (BE
                          (CBlockEntry (read ?entry0) (write ?entry0)
                             (exec ?entry0) true (accessible ?entry0)
                             (blockindex ?entry0) (blockrange ?entry0)))
                       (add newBlockEntryAddr
                          (BE
                             (CBlockEntry (read ?entry)
                                (write ?entry) (exec ?entry)
                                (present ?entry) true (blockindex ?entry)
                                (blockrange ?entry)))
                          (add newBlockEntryAddr
                             (BE
                                (CBlockEntry (read x2) (write x2)
                                   (exec x2) (present x2)
                                   (accessible x2) (blockindex x2)
                                   (CBlock (startAddr (blockrange x2)) endaddr)))
                             (add newBlockEntryAddr
                                (BE
                                   (CBlockEntry (read x1)
                                      (write x1) (exec x1)
                                      (present x1) (accessible x1)
                                      (blockindex x1)
                                      (CBlock startaddr (endAddr (blockrange x1))))))))))) =
add newBlockEntryAddr
              (BE
                 (CBlockEntry r w e
                    true true
                    (blockindex x2)
(CBlock (startAddr endaddr))))).

set (s' :=   {|
currentPartition := _ |}).
{
	unfold isBE. destruct (lookup newBlockEntryAddr (memory s') beqAddr) eqn:Hlookup.
	destruct v eqn:Hv ; trivial.





{|
                      (CBlockEntry
                         (read
                            (CBlockEntry
                               (read
                                  (CBlockEntry r (write ?entry)
                                     (exec ?entry) (present ?entry)
                                     (accessible ?entry)
                                     (blockindex ?entry)
                                     (blockrange ?entry))) w
		eexists. split. subst. f_equal.
		eexists. split. subst. f_equal.
		eexists. split. subst. f_equal.
		eexists. split.
2 : {	eexists. split. f_equal.
			eexists. split. simpl. f_equal.
		unfold isBE. simpl. split.



}
		eexists. split. subst. f_equal.
		eexists. split. subst. f_equal.
		eexists. split. subst. f_equal.



		unfold entryEndAddr in *.
		destruct (lookup newBlockEntryAddr (memory s) beqAddr) eqn:Hlookup.
		f_equal.
		destruct v eqn:Hv.
		specialize (entry = b).

rewrite H5. simpl.
		assert (lookup newBlockEntryAddr
  (removeDup pdinsertion (removeDup pdinsertion (memory s) beqAddr) beqAddr)
  beqAddr = lookup newBlockEntryAddr (memory s) beqAddr).
		{ apply removeDupIdentity. intuition. }
		unfold removeDup. simpl.


	eapply bindRev.
{	eapply weaken. apply WP.writePDFirstFreeSlotPointer.
	intros. simpl. intuition.
	destruct H4. exists x. split. destruct H0. assumption.
	unfold add.
	set (s' :=  {|
     currentPartition := _ |}).
	subst.
	exact (P s').

writeAccessible
split. apply H.
	intuition. destruct H3. destruct H. destruct H3. intuition.
}
	intro predCurrentNbFreeSlots.


set (s' :=  {|
     currentPartition := _ |}).
   simpl in *.
	pattern s in H.
   instantiate (1 := fun tt s => H /\
             StateLib.entryFirstFreeSlot pdinsertion s.(memory) = Some newFirstFreeSlotAddr ).

assert( Hlemma : forall addr1 addr2 x pointer,
addr2 <> addr1 ->
entryFirstFreeSlot addr1 pointer s ->
entryFirstFreeSlot addr1 pointer
  {|
  currentPartition := currentPartition s;
  memory := add addr2 x (memory s) beqAddr |}).
{
intros.
unfold entryFirstFreeSlot in *.
cbn.
case_eq (beqAddr addr2 addr1).
intros. simpl. unfold beqAddr in H5. unfold not in H3. contradict H5.
	unfold not. intro. apply H3. Search(PeanoNat.Nat.eqb).
	rewrite -> PeanoNat.Nat.eqb_eq in H5.
	destruct addr2 in *. destruct addr1 in *. apply H5.

unfold not in H0.
unfold beqAddr.
rewrite <- H0.
assert (Hpairs : beqPairs (table2, idx2) (table1, idx1) beqAddr = false).
apply beqPairsFalse.
left; trivial.
rewrite Hpairs.
assert (lookup  table1 idx1 (removeDup table2 idx2 (memory s) beqPage beqIndex)
          beqPage beqIndex = lookup  table1 idx1 (memory s) beqPage beqIndex) as Hmemory.
{ apply removeDupIdentity. subst.  intuition. }
rewrite  Hmemory. assumption.
Qed.

destruct H. destruct H. destruct H. destruct H2.
	exists x. split. destruct H2. assumption.
	pose (H' : H&H2&H1).
	pose (H'' := conj H1 H0).
	pose (H''' := conj H' H'').
	pattern s in H'''.
  match type of H with
  | ?HT s => instantiate (1 := fun tt s => HT s /\
             StateLib.entryFirstFreeSlot pdinsertion s.(memory) = Some newFirstFreeSlotAddr )
  end.

	  intros. simpl.
     (*set (s' := {| currentPartition := _ |}). *)


admit. (*
 (** add the propeties about writeAccessible post conditions **)
match type of H2 with
  | ?HT s => instantiate (1 := fun tt s => HT s /\
              entryUserFlag ptvaInAncestor (StateLib.getIndexOfAddr vaInAncestor fstLevel) false s /\
              isEntryPage ptvaInAncestor (StateLib.getIndexOfAddr vaInAncestor fstLevel) phypage s /\
              entryPresentFlag ptvaInAncestor (StateLib.getIndexOfAddr vaInAncestor fstLevel) true s  )
  end.
  rewrite and_assoc.
   split. *)
}	intros.

	eapply bindRev.
{ eapply weaken. apply readPDNbFreeSlots.
	intros. simpl.

}
	intro currentNbFreeSlots.

Require Import Model.Test.

Lemma addMemoryBlockTest  (currentPartition idPDchild : paddr) :
{{fun s => partitionsIsolation s   /\ kernelDataIsolation s /\ verticalSharing s /\ consistency s }}
checkChildOfCurrPart3 currentPartition idPDchild
{{fun _ s  => partitionsIsolation s   /\ kernelDataIsolation s /\ verticalSharing s /\ consistency s }}.
Proof.
unfold checkChildOfCurrPart3.
eapply bindRev.
eapply weaken. apply checkChildOfCurrPart. simpl. intros. split. apply H. apply H.
intro b. simpl. destruct b. simpl.
eapply bindRev.
	eapply weaken. apply readBlockStartFromBlockEntryAddr. intros. simpl. split.
	apply H.
	unfold isBE.

	unfold checkChild in *.
Admitted.*)
*)
*)
