#include "llvm/ADT/StringRef.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/LegacyPassManager.h"
#include "llvm/IR/Module.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/ModuleUtils.h"
#include <map>
#include <string>
#include <vector>
#include <fstream>

using namespace llvm;

#define DEBUG_TYPE "bb-instrument"

cl::opt<std::string> CountFile("count-file", cl::desc("Output file for basic block counts"), cl::value_desc("filename"));

struct BBInstrument : PassInfoMixin<BBInstrument> {  
  PreservedAnalyses run(Module &M, ModuleAnalysisManager &MAM) {
    IRBuilder<> builder(M.getContext());
    std::map<std::string, unsigned> bbOpCounts;
    
    // For each basic block, add a marker instruction that references a unique identifier
    for (auto &F : M) {
      // Skip declarations
      if (F.isDeclaration())
        continue;
        
      for (auto &BB : F) {
        if (BB.empty()) continue;
        
        errs() << "Instrumenting BB: " << BB.getName() << " in function: " << F.getName() << "\n";
        
        // Create a unique identifier for this basic block
        std::string bbId = "____bbid#" + F.getName().str() + "#" + BB.getName().str();
        std::string bbIdRaw = F.getName().str() + "#" + BB.getName().str();
        
        // Count operations in this basic block
        unsigned opCount = 0;
        for (auto &I : BB) {
          if (!isa<PHINode>(&I) && !isa<DbgInfoIntrinsic>(&I)) {
            opCount++;
          }
        }
        bbOpCounts[bbIdRaw] = opCount;
        
        // Create a global string variable with the BB identifier
        // Make it non-constant so we can modify it
        Constant *stringConstant = ConstantDataArray::getString(M.getContext(), bbId, true);
        GlobalVariable *bbIdGlobal = new GlobalVariable(
            M, 
            stringConstant->getType(), 
            false,  // isConstant = false so we can modify it
            GlobalValue::ExternalLinkage,  // Make it external so it's not optimized out
            stringConstant, 
            bbId);
        
        // Insert at the beginning of the basic block
        IRBuilder<> bbBuilder(&*BB.getFirstInsertionPt());
        
        // Get a pointer to the first character of the string
        Value *zero = ConstantInt::get(Type::getInt8Ty(M.getContext()), 0);
        Value *firstCharPtr = bbBuilder.CreateGEP(
            bbIdGlobal->getValueType(), 
            bbIdGlobal, 
            {zero, zero}, 
            "bb_marker_ptr");
        
        Value *char_ = ConstantInt::get(Type::getInt8Ty(M.getContext()), '_');
        // Store it back (this creates a self-reference that can't be optimized out)
        bbBuilder.CreateStore(char_, firstCharPtr);
      }
    }
    
    // Output the mapping to file if specified
    if (!CountFile.empty()) {
      auto outputFile = CountFile.getValue();
      std::ofstream outFile(outputFile);
      if (outFile.is_open()) {
        outFile << "bbid,opcount\n";
        for (const auto &pair : bbOpCounts) {
          outFile << pair.first << "," << pair.second << "\n";
        }
        outFile.close();
      } else {
        errs() << "Warning: Could not open output file: " << outputFile << "\n";
      }
    }
    
    return PreservedAnalyses::all();
  }
};

// Plugin registration
llvm::PassPluginLibraryInfo getBBInstrumentPluginInfo() {
  return {
      LLVM_PLUGIN_API_VERSION, "BBInstrument", LLVM_VERSION_STRING,
      [](PassBuilder &PB) {
        PB.registerPipelineParsingCallback(
            [](StringRef Name, ModulePassManager &MPM,
               ArrayRef<PassBuilder::PipelineElement>) {
              if (Name == "bb_instrument") {
                MPM.addPass(BBInstrument());
                return true;
              }
              return false;
            });
      }};
}

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo
llvmGetPassPluginInfo() {
  return getBBInstrumentPluginInfo();
} 