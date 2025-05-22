# Deep Equality and `addUnique` Behavior in TinyDB

## Overview
TinyDB's update operations (`addUnique`, `push`, `pull`, `pop`) are designed to work robustly with Dart's dynamic lists and maps, supporting deep equality and defensive copying. This ensures that all mutations are safe, predictable, and value-based, not reference-based.

## `addUnique` Operation
- When you use `addUnique` on a list field, TinyDB will only add the new value if it does **not** already exist in the list **by value** (deep equality), not just by reference.
- Deep equality means:
  - For lists: Two lists are equal if they have the same length and all corresponding elements are deeply equal.
  - For maps: Two maps are equal if they have the same keys and all corresponding values are deeply equal.
  - For primitives (int, double, String, bool, null): Standard `==` is used.
- This allows you to safely store lists of lists, lists of maps, or mixed-type lists without worrying about duplicate values caused by reference differences.

## Defensive Copying
- All list operations (`addUnique`, `push`, `pull`, `pop`) create a deep copy of the list before mutating it. This prevents accidental reference bugs and ensures that each document maintains its own data integrity.

## Examples
### Lists of Lists
```dart
// Initial field: [[1, 2, 3]]
table.update(UpdateOperations().addUnique('favorites', [1, 2, 3]));
// No change, because [1, 2, 3] is already present (by value).
```

### Mixed-Type Lists
```dart
// Initial field: ['a', 'b']
table.update(UpdateOperations().addUnique('tags', null));
// Result: ['a', 'b', null]

table.update(UpdateOperations().addUnique('tags', 42));
// Result: ['a', 'b', null, 42]
```

### Maps
```dart
// Initial field: [{'foo': 1}]
table.update(UpdateOperations().addUnique('myMaps', {'foo': 1}));
// No change, because {'foo': 1} is already present (by value).
```

## Notes
- Dart lists are dynamic; TinyDB does not enforce element type at runtime.
- If you want to enforce stricter typing, do so in your own application logic.
- All equality checks are recursive and value-based, not reference-based.

## Summary
TinyDB's deep equality and defensive copying make it robust for all Dart data structures. You can safely use nested lists, maps, and mixed types with predictable, value-based behavior.
