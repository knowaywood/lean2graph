import Lean
import Lean.Data.Json
import Std.Data.HashMap
import Lean2graph.Normal
import Lean2graph.Types

open Lean Meta Elab Tactic Json Std

namespace TacMiner

def tacticNode2StrNode (tn : TacticNode) : MetaM TacticStrNode := do
  let g_fmt ← ppGoal tn.goals
  return {
    id := tn.id,
    goals := toString g_fmt
  }

def get_seqTactics (seq : TSyntax ``Parser.Tactic.tacticSeq) : Array (TSyntax `tactic) :=
  match seq with
  | `(tacticSeq| $seq:tactic;*) => seq.getElems
  | `(tacticSeq| { $seq:tactic;* }) => seq.getElems
  | _ => #[]

partial def flattenTactics (tac : TSyntax `tactic) : Array (TSyntax `tactic) :=
  match tac with
  | `(tactic| · $seq:tacticSeq) =>
      get_seqTactics seq |>.flatMap flattenTactics
  | _ => #[tac]

def get_seqTacticsFlattened (seq : TSyntax ``Parser.Tactic.tacticSeq) : Array (TSyntax `tactic) :=
  match seq with
  | `(tacticSeq| $seq:tactic;*) => seq.getElems.flatMap flattenTactics
  | `(tacticSeq| { $seq:tactic;* }) => seq.getElems.flatMap flattenTactics
  | _ => #[]

elab "extract_tdg " seq:tacticSeq : tactic => do

  let tactics := get_seqTacticsFlattened seq
  let mut nodes : Array TacticNode := #[]
  let mut edges : Array DependencyEdge := #[]
  let mut allGoals : OrderedSet MVarId := OrderedSet.empty
  let mut assigned_Goal : HashMap MVarId Bool := {}
  let mut node2end : Array End := #[]

  for tac in tactics do
    let goalsBefore ← getGoals

    allGoals := insertMany allGoals goalsBefore
    assigned_Goal := insertMany assigned_Goal ( ← goalsBefore.mapM fun g => return (g, ← g.isAssigned))

    let parents := allGoals.gets? goalsBefore.toArray

    let tacStr := match tac.raw.reprint with
      | some s => s.trim
      | none   => "unknown_tactic"

    evalTactic tac

    let goalsAfter ← getGoals
    let newGoals := goalsAfter.filter (fun g => !allGoals.contains g)
    if newGoals.isEmpty then
      for parent in parents do
      if let some parent := parent then do
        let parent_assigned  ← parent.isAssigned
        if parent_assigned == true && assigned_Goal.get! parent == false then
          node2end := node2end.push {
            sourceId := allGoals.findIdx! (· == parent),
            label := tacStr
          }

    for parent in parents do
      if let some parent := parent then do
        let parent_assigned  ← parent.isAssigned
        if parent_assigned == true && assigned_Goal.get! parent == false then
          for g in newGoals do
              edges := edges.push {
                sourceId := allGoals.findIdx! (· == parent),
                targetId := (insertMany allGoals newGoals).findIdx! (· == g),
                label := tacStr
              }

    allGoals := insertMany allGoals newGoals

    if allGoals.size > nodes.size then
      let newNodes := allGoals.filter (fun g => !(nodes.map (fun n => n.goals)).contains g)
      for g in newNodes.items do
        nodes := nodes.push {
          id := allGoals.findIdx! (· == g),
          goals := g
        }
  let strnodes ←  nodes.mapM (fun g => tacticNode2StrNode g)
  let graph := GraphData.mk strnodes edges node2end
  logInfo m!"{toJson graph}"

end TacMiner
