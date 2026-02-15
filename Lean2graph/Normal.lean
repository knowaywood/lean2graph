import Std
import Lean2graph.Types
open Std


class InsertMany (C : Type) (E : Type) where
  insertMany : C → List E → C

instance [BEq α] [Hashable α] : InsertMany (Std.HashMap α β) (α × β) where
  insertMany m entries :=Id.run do
  let mut m := m
  for (k, v) in entries do
    m := m.insert k v
  return m

instance [BEq α] [Hashable α] : InsertMany (Std.HashSet α ) α where
  insertMany m entries :=Id.run do
    let mut m := m
    for k in entries do
      m := m.insert k
    return m

instance [BEq α] [Hashable α] : InsertMany (Std.HashSet α ) α where
  insertMany m entries :=Id.run do
    let mut m := m
    for k in entries do
      m := m.insert k
    return m


instance [BEq α] [Hashable α] : InsertMany (OrderedSet α) α where
  insertMany m entries :=Id.run do
    let mut m := m
    for k in entries do
      m := m.insert k
    return m

def insertMany {C E} [InsertMany C E] (contaner: C) (entries: List E) :=
  InsertMany.insertMany contaner entries
