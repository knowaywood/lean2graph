import Lean

open Std in
structure OrderedSet (α : Type) [BEq α] [Hashable α] where
  items : Array α
  seen  : HashSet α
deriving Repr, Inhabited

namespace OrderedSet

def insert [BEq α] [Hashable α] (s : OrderedSet α) (x : α) : OrderedSet α :=
  if s.seen.contains x then
    s
  else
    { items := s.items.push x, seen := s.seen.insert x }

def get? [BEq α] [Hashable α] (s : OrderedSet α) (x : α) : Option α := s.seen.get? x

def gets? [BEq α] [Hashable α] (l : OrderedSet α) (ax :Array α): Array (Option α) :=Id.run do
  let mut arr := #[]
  for i in ax do
    arr := arr.push (l.get? i)
  return arr

def contains [BEq α] [Hashable α] (s : OrderedSet α) (x : α) : Bool := s.seen.contains x

def empty [BEq α] [Hashable α] : OrderedSet α := { items := #[], seen := {}}

def findIdx? [BEq α] [Hashable α] (p : α → Bool) (l : OrderedSet α) : Option Nat := l.items.findIdx? p

def findIdx! [BEq α] [Hashable α] (p : α → Bool) (l : OrderedSet α) : Nat :=
  match l.findIdx? p with
  | none => panic! ""
  | some n => n

def size [BEq α] [Hashable α]  (l : OrderedSet α) : Nat := l.items.size

def filter [BEq α] [Hashable α] (p:α → Bool) (l : OrderedSet α): OrderedSet α := {items := l.items.filter p,seen:= l.seen.filter p}

def append [BEq α] [Hashable α] (l₁ l₂ : OrderedSet α) : OrderedSet α :=Id.run do
  let mut l := l₁
  for i in l₂.items do
    l := l.insert i
  return l

-- (p : α → Bool) (l : List α) : List α
end OrderedSet

namespace TacMiner
open Lean

structure TacticNode where
  id : Nat
  goals :  MVarId
  deriving Repr, Inhabited,ToJson

structure TacticStrNode where
  id : Nat
  goals :  String
  deriving Repr, Inhabited,ToJson

structure End where
  sourceId : Nat
  label : String
  deriving ToJson,Repr


structure DependencyEdge where
  sourceId : Nat
  targetId : Nat
  label : String
  deriving ToJson, Repr

structure GraphData where
  nodes : Array TacticStrNode := #[]
  edges : Array DependencyEdge := #[]
  END : Array End := #[]
  deriving ToJson

end TacMiner
