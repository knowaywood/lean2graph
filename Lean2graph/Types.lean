import Lean

namespace Tree
open Lean in
structure Tree where
  Goal : MVarId
  Tactic : String
  Children : List Tree

def Goal_id (t : Tree) : Lean.Name := t.Goal.name

end Tree
