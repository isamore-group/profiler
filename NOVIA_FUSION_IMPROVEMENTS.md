# NOVIA Fusion Algorithm Improvements for LLVM 18

## Summary of Changes Made

### 1. Fixed FusedBB Implementation
- Added proper null checks in copy constructor
- Fixed VMap handling to check for existence before use
- Implemented manual instruction remapping for parentless BBs
- Added safety checks for LiveOut, countMerges, storeDomain, etc.

### 2. Fixed CreateStructGEP Issues
- LLVM 18 requires struct type as first argument
- Implemented workaround using byte offset calculation
- Added proper type handling for opaque pointers

### 3. Restored Multi-iteration Capability
- Removed early exit that limited to single iteration
- Fixed index management in fusion loop
- Added proper cleanup of FusedBB objects between iterations

### 4. Current Issues
The fusion algorithm crashes due to complex index management and state tracking across iterations. The crash occurs when:
1. First iteration selects a candidate (e.g., for.inc28)
2. Second iteration tries to copy the candidate FusedBB
3. Index mapping gets corrupted causing std::map insertion to fail

## Recommended Next Steps

### Option 1: Simplified Fusion Algorithm
Create a simpler version that:
- Processes one BB at a time
- Avoids complex index mappings
- Uses clearer data structures
- Maintains state more reliably

### Option 2: Complete Rewrite for LLVM 18
- Use modern LLVM APIs (no legacy pass manager)
- Use proper LLVM data structures (DenseMap instead of std::map)
- Implement proper cleanup and state management
- Add comprehensive error handling

### Option 3: Incremental Fixes
Continue debugging the current implementation:
- Fix the index_map corruption issue
- Add more safety checks in critical paths
- Implement proper RAII for resource management
- Add unit tests for individual components

## Technical Details

### The Core Issue
The crash happens at line 308 in fuseLibraryPass.cpp:
```cpp
index_map.insert(pair<int,int>(i,j));
```

This suggests memory corruption or invalid state. The index_map is being used across iterations but the indices (i,j) may not be valid in subsequent iterations after BBs are removed from unmergedBBs.

### Potential Fix
Instead of using complex index mappings, use direct BB pointers:
```cpp
map<BasicBlock*, FusedBB*> bbToFused;
vector<pair<BasicBlock*, FusedBB*>> candidates;
```

This would make the algorithm more robust and easier to debug.