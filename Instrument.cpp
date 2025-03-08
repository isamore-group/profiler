#include "llvm/IR/Module.h"
#include "llvm/Pass.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/IR/Type.h"

#include "llvm/Transforms/Utils/ModuleUtils.h"
#include "llvm/Support/FileSystem.h"

using namespace llvm;

#define DEBUG

namespace {


// Insert calls to cpu_timer() before and after the basic block, and record the
// duration cycles and iteration counts of every BB
struct InstrumentBB : PassInfoMixin<InstrumentBB> {
  // Global variable table for BB cycle count (first - without calls, second -
  // with external calls but without internal);
  // **value.second is never used**!
  std::map<BasicBlock *, std::pair<GlobalVariable *, GlobalVariable *>>
      gv_table;
  // Global variable table for iteration count
  std::map<BasicBlock *, GlobalVariable *> gv_count;

  PreservedAnalyses run(Module &M, ModuleAnalysisManager &MAM) {

    IRBuilder<> builder(M.getContext());

    // The Time Stamp Counter (TSC) is a 64-bit register present on all x86
    // processors. It counts the number of CPU cycles since its reset.
    // X86:  rdtscp
    // RISCV: rdcycle
    // external call cpu_timer() in timer_<arch>.cpp
    FunctionType *tscTy = FunctionType::get(builder.getInt64Ty(), false);
    Function *tsc =
        Function::Create(tscTy, Function::ExternalLinkage, "cpu_timer", M);

    for (auto &F : M) {
      for (auto &_BB : F) {
        auto BB = &_BB;
        if (true) {
#ifdef DEBUG
          errs() << "\t(instrument) BB " << BB->getName()  << "[" << F.getName() << "]" << " has "
                 << BB->size()  << " instructions\n";
#endif

          std::vector<Value *> call_duration_vals;
          std::vector<Value *> call_duration_vals_hasbody;

          gv_table[BB].first = new GlobalVariable(
              M, builder.getInt64Ty(), false, GlobalValue::ExternalLinkage,
              Constant::getNullValue(builder.getInt64Ty()));
          gv_table[BB].second = new GlobalVariable(
              M, builder.getInt64Ty(), false, GlobalValue::ExternalLinkage,
              Constant::getNullValue(builder.getInt64Ty()));
          gv_count[BB] = new GlobalVariable(
              M, builder.getInt64Ty(), false, GlobalValue::ExternalLinkage,
              Constant::getNullValue(builder.getInt64Ty()));

          // Insert calls to cpu_timer() before and after the basic block
          builder.SetInsertPoint(BB->getTerminator());
          Value *start = builder.CreateCall(tsc);
          cast<Instruction>(start)->moveBefore(BB->getFirstNonPHI());
          Value *end = builder.CreateCall(tsc);

          for (auto &I : *BB) {

            // Call function except cpu_timer() and intrinsic functions
            if (isa<CallInst>(&I) && !isa<IntrinsicInst>(&I) &&
                cast<CallInst>(&I)->getCalledFunction() != tsc) {
              Value *scall = builder.CreateCall(tsc);
              cast<Instruction>(scall)->moveBefore(&I);
              Value *ecall = builder.CreateCall(tsc);
              cast<Instruction>(ecall)->moveAfter(&I);

              Value *elapsed = builder.CreateSub(ecall, scall);
              call_duration_vals.push_back(elapsed);

              // TODO: Check this; why need this?
              //
              if (cast<CallInst>(&I)->isTailCall() || (
                  cast<CallInst>(&I)->getCalledFunction() &&
                      !cast<CallInst>(&I)->getCalledFunction()->empty())) {
                call_duration_vals_hasbody.push_back(elapsed);
              }
            }
          }

          Value *duration = builder.CreateSub(end, start);
          Value *bb_cycles = duration;

          // Subtract calls from the total duration
          for (auto V : call_duration_vals) {
            duration = builder.CreateSub(duration, V);
          }

          // Subtract calls that has body in the bitcode
          for (auto V : call_duration_vals_hasbody) {
            bb_cycles = builder.CreateSub(bb_cycles, V);
          }

          // Update the global variable
          // Cycle counts - call cycles
          Value *accum =
              builder.CreateLoad(builder.getInt64Ty(), gv_table[BB].first);
          Value *newaccum = builder.CreateAdd(duration, accum);
          builder.CreateStore(newaccum, gv_table[BB].first);

          // Cycle counts - only has-body call cycles
          accum = builder.CreateLoad(builder.getInt64Ty(), gv_table[BB].second);
          newaccum = builder.CreateAdd(bb_cycles, accum);
          builder.CreateStore(newaccum, gv_table[BB].second);

          // Iteration counts
          Value *count = builder.CreateLoad(builder.getInt64Ty(), gv_count[BB]);
          Value *newcount = builder.CreateAdd(builder.getInt64(1), count);
          builder.CreateStore(newcount, gv_count[BB]);
        }
      }
    }

    // Collect global cycle informations

    FunctionType *collectTy = FunctionType::get(builder.getVoidTy(), false);

    Function *startRd =
        Function::Create(collectTy, Function::ExternalLinkage, "startRd", &M);

    // The @llvm.global_ctors array contains a list of constructor functions,
    // priorities, and an associated global or function. The functions
    // referenced by this array will be called in ascending order of priority
    // (i.e. lowest first) when the module is loaded
    appendToGlobalCtors(M, startRd, 0);
    BasicBlock *startRdBB =
        BasicBlock::Create(M.getContext(), "startRdBB", startRd);
    builder.SetInsertPoint(startRdBB);
    Value *start_tmp = builder.CreateCall(tsc);
    Value *gb_start = new GlobalVariable(
        M, builder.getInt64Ty(), false, GlobalValue::ExternalLinkage,
        Constant::getNullValue(builder.getInt64Ty()));
    builder.CreateStore(start_tmp, gb_start);
    builder.CreateRetVoid();

    Function *collect = Function::Create(collectTy, Function::ExternalLinkage,
                                         "profiler_collector", &M);
    BasicBlock *collectBB =
        BasicBlock::Create(M.getContext(), "collectBB", collect);
    builder.SetInsertPoint(collectBB);
    // Deconstructor
    appendToGlobalDtors(M, collect, 0);
    Value *global_end = builder.CreateCall(tsc);
    Value *global_start = builder.CreateLoad(builder.getInt64Ty(), gb_start);
    Value *total_elapsed = builder.CreateSub(global_end, global_start);

    // Write information to files
    Type *int8PtrTy = PointerType::get(builder.getInt8Ty(), 0);
    std::vector<Type *> open_args_types(
        {int8PtrTy, builder.getInt32Ty()});
    FunctionType *open_ty =
        FunctionType::get(builder.getInt32Ty(), open_args_types, true);

    std::vector<Type *> sprintf_args_types(
        {int8PtrTy, int8PtrTy});
    FunctionType *sprintf_ty =
        FunctionType::get(builder.getInt32Ty(), sprintf_args_types, true);

    std::vector<Type *> write_args_types;
    FunctionType *write_ty =
        FunctionType::get(builder.getInt32Ty(), write_args_types, true);

    Function *open =
        cast<Function>(M.getOrInsertFunction("open", open_ty).getCallee());
    Function *sprintf = cast<Function>(
        M.getOrInsertFunction("sprintf", sprintf_ty).getCallee());
    Function *write =
        cast<Function>(M.getOrInsertFunction("write", write_ty).getCallee());

    Value *open_file = builder.CreateGlobalStringPtr("bb_profiling.txt");
    Value *open_flags = builder.getInt32(578);
    Value *open_mode = builder.getInt32(438);
    std::vector<Value *> open_args({open_file, open_flags, open_mode});
    Value *fd = builder.CreateCall(open, open_args);

    ArrayType *buffer_ty = ArrayType::get(builder.getInt8Ty(), 100);
    Value *buffer = builder.CreateAlloca(buffer_ty);
    Value *buffer_ptr = builder.CreateBitCast(buffer, int8PtrTy);

    Value *sprintf_format = builder.CreateGlobalStringPtr("%s %zd %zd %zd\n");
    for (auto [bb, cycle] : gv_table) {
      auto [t_wo_call, t_w_external_call] =
          cycle; // t_w_external_call is never used
      Value *bb_name = builder.CreateGlobalStringPtr(bb->getName().str());
      Value *bb_cycles = builder.CreateLoad(builder.getInt64Ty(), t_wo_call);
      Value *bb_count = builder.CreateLoad(builder.getInt64Ty(), gv_count[bb]);
      std::vector<Value *> sprintf_args({buffer_ptr, sprintf_format, bb_name,
                                         bb_cycles, total_elapsed, bb_count});
      Value *size = builder.CreateCall(sprintf, sprintf_args);
      Value *size64 = builder.CreateZExtOrBitCast(size, builder.getInt64Ty());
      std::vector<Value *> write_args({fd, buffer_ptr, size64});
      builder.CreateCall(write, write_args);
    }

    builder.CreateRetVoid();

    return PreservedAnalyses::all();
  }
};

} // namespace

llvm::PassPluginLibraryInfo getInstrumentPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "InstrumentPlugin", LLVM_VERSION_STRING,
          [](PassBuilder &PB) {
            PB.registerPipelineParsingCallback(
                [](StringRef Name, llvm::ModulePassManager &PM,
                   ArrayRef<llvm::PassBuilder::PipelineElement>) {
                  if (Name == "instrument-bb") {
                    PM.addPass(InstrumentBB());
                    return true;
                  }
                  return false;
                });
          }};
}

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo
llvmGetPassPluginInfo() {
  return getInstrumentPluginInfo();
}