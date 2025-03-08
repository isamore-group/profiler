cmake_minimum_required(VERSION 3.16)

project(adex VERSION 0.1 DESCRIPTION "LLVM passes for automated extension discovery")

set(CMAKE_CXX_STANDARD 20)

set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

# add LLVM support

set(SYSTEM_HOME $ENV{HOME})
message(STATUS "SYSTEM_HOME: ${SYSTEM_HOME}")

set(LLVM_PATH "${SYSTEM_HOME}/repos/jlm/build-llvm-mlir")
message(STATUS "LLVM_PATH: ${LLVM_PATH}")

if(NOT EXISTS ${LLVM_PATH}/include/llvm )
	message(FATAL_ERROR "LLVM_PATH (${LLVM_PATH}) is not a valid LLVM install.")
endif()

set(CMAKE_PREFIX_PATH "${LLVM_PATH}/bin/")
list(APPEND CMAKE_MODULE_PATH ${LLVM_PATH}/lib/cmake/llvm/)
include(LLVMConfig)
include(AddLLVM)

add_definitions(${LLVM_DEFINITIONS})
include_directories(${LLVM_INCLUDE_DIRS})
link_directories(${LLVM_LIBRARY_DIRS})


add_compile_options(-Wall)
add_compile_options(-fno-rtti)
add_compile_options(-ggdb)
add_compile_options(-O3)
add_compile_options(-fno-vectorize -fno-slp-vectorize -ffp-contract=off)
add_compile_options(-fPIC)

add_library(bb_instrument SHARED BBInstrument.cpp)