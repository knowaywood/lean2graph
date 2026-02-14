import Lean
import Std.Data.HashMap
open Std

def insertMany {α β} [BEq α] [Hashable α] (m : HashMap α β) (entries : List (α  × β )) : HashMap α β  := Id.run do
  let mut m := m
  for (k, v) in entries do
    m := m.insert k v
  return m

open Lean Parser Elab Tactic in
def get_seqTactics : TSyntax ``tacticSeq → TSyntaxArray `tactic := fun seq =>
  match seq with
  | `(tacticSeq| $seq:tactic;*) => seq.getElems
  | `(tacticSeq| { $seq:tactic;* }) => seq.getElems
  | _ => panic! ""


open Lean Meta Tactic Elab Tactic in
elab "trace_mvar_status" t:tacticSeq : tactic => do
  let initialGoals ← getGoals

  let mut statusMap : HashMap MVarId Bool :=
    HashMap.ofList (initialGoals.map fun g => (g, false))

  let tactics := get_seqTactics t

  for tac in tactics do
    evalTactic tac
    let newGoals ← getGoals
    statusMap := statusMap.insertMany (newGoals.map fun g => (g, false))
    for g in statusMap.keys do
      let isAssigned ← g.isAssigned
      let recordedStatus := statusMap.getD g false

      if isAssigned && !recordedStatus then

        statusMap := statusMap.insert g true
  logInfo m!"{statusMap.toList}"



open Lean Meta Tactic Elab Tactic in
elab "trace_mvar_status'" t:tacticSeq : tactic => do
  let initialGoals ← getGoals

  let mut statusMap : HashMap MVarId Bool :=
    HashMap.ofList (initialGoals.map fun g => (g, false))

  let tactics := get_seqTactics t

  for tac in tactics do
    evalTactic tac
    let newGoals ← getGoals
    statusMap := statusMap.insertMany (newGoals.map fun g => (g, false))
    for g in statusMap.keys do
      let isAssigned ← g.isAssigned
      let recordedStatus := statusMap.getD g false

      if isAssigned && !recordedStatus then
        statusMap := statusMap.insert g true
        
  logInfo m!"{statusMap.toList}"
