#include <cstdint>
#include <iostream>
#include <fstream>
#include <string>
#include <map>
#include <mutex>

// Global map to store the mapping between basic block IDs and their addresses
static std::map<std::string, uint64_t> bb_address_map;
static std::mutex map_mutex;

// This function is called at the beginning of each basic block
// It records the basic block ID and its address
extern "C" void bb_marker(const char* bb_id) {
    // Get the return address (which is the address of the instruction after the call)
    void* return_addr = __builtin_return_address(0);
    uint64_t addr = reinterpret_cast<uint64_t>(return_addr);
    
    // Adjust the address to point to the beginning of the basic block
    // This is an approximation - the actual address is slightly before this
    // but it's close enough for most purposes
    
    // Lock to ensure thread safety
    std::lock_guard<std::mutex> lock(map_mutex);
    
    // Store the mapping
    bb_address_map[bb_id] = addr;
    
    // Optionally print for debugging
    // std::cout << "BB: " << bb_id << " at address: 0x" << std::hex << addr << std::dec << std::endl;
}

// Function to dump the mapping to a file when the program exits
// This is automatically called by the atexit handler
static void dump_bb_address_map() {
    std::ofstream outfile("bb_address_mapping.txt");
    if (!outfile.is_open()) {
        std::cerr << "Error: Could not open bb_address_mapping.txt for writing" << std::endl;
        return;
    }
    
    for (const auto& [bb_id, addr] : bb_address_map) {
        outfile << bb_id << " 0x" << std::hex << addr << std::dec << std::endl;
    }
    
    outfile.close();
}

// Register the dump function to be called when the program exits
static int register_dump = []() {
    std::atexit(dump_bb_address_map);
    return 0;
}();

// This function returns the current instruction pointer (RIP) value
// It uses a more reliable approach to get the address
extern "C" uint64_t get_rip_value() {
    // We'll use the __builtin_return_address function which is more reliable
    // than inline assembly for getting addresses
    void* return_addr = __builtin_return_address(0);
    
    // This will give us the address of the instruction that will be executed
    // after returning from this function, which is close to the call site
    return reinterpret_cast<uint64_t>(return_addr);
} 