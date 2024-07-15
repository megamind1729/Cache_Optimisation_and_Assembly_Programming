#include <algorithm>
#include <cassert>
#include <map>
#include <vector>

#include "cache.h"

namespace
{

/* last_inserted_cycles - vector of last_used_cycle_number (uint64_t) corresponding to each line */
std::map<CACHE*, std::vector<uint64_t>> last_inserted_cycles;
}

/*
initialize_replacement() is called when the cache is initialized. You can use it to initialize elements of dynamic structures, such as std::vector or std::map.
*/
void CACHE::initialize_replacement() { ::last_inserted_cycles[this] = std::vector<uint64_t>(NUM_SET * NUM_WAY, 0); }

/*
find_victim() is called when a tag is checked in the cache. The parameters passed are:

  - triggering_cpu: the core index that initiated this fill
  - instr_id: an instruction count that can be used to examine the program order of requests.
  - set: the set that the fill occurred in.
  - current_set: a pointer to the beginning of the set being accessed.
  - ip: the address of the instruction that initiated the demand. If the packet is a prefetch from another level, this value will be 0.
  - addr: the address of the packet. If this is the first-level cache, the offset bits are included. Otherwise, the offset bits are zero. If the cache was configured with “virtual_prefetch”: true, this address will be a virtual address. Otherwise, this is a physical address.
  - type: the result of static_cast<std::underlying_type_t<access_type>>(v) for v in:
    - access_type::LOAD
    - access_type::RFO
    - access_type::PREFETCH
    - access_type::WRITE
    - access_type::TRANSLATION

The function should return the way_index that should be evicted, or this->NUM_WAY to indicate that a bypass should occur.
*/
uint32_t CACHE::find_victim(uint32_t triggering_cpu, uint64_t instr_id, uint32_t set, const BLOCK* current_set, uint64_t ip, uint64_t full_addr, uint32_t type)
{
  auto begin = std::next(std::begin(::last_inserted_cycles[this]), set * NUM_WAY);
  auto end = std::next(begin, NUM_WAY);

  // Find the way whose last insertion cycle is most distant
  auto victim = std::min_element(begin, end);
  assert(begin <= victim);
  assert(victim < end);
  return static_cast<uint32_t>(std::distance(begin, victim)); // cast protected by prior asserts
}

/*
update_replacement_state() is called when a hit occurs or a miss is filled in the cache. The parameters passed are:

  - triggering_cpu: the core index that initiated this fill
  - set: the set that the fill occurred in.
  - way: the way that the fill occurred in.
  - addr: the address of the packet. If this is the first-level cache, the offset bits are included. Otherwise, the offset bits are zero. If the cache was configured with “virtual_prefetch”: true, this address will be a virtual address. Otherwise, this is a physical address.
  - ip: the address of the instruction that initiated the demand. If the packet is a prefetch from another level, this value will be 0.
  victim_addr: the address of the evicted block, if this is a miss. If this is a hit, the value is 0.
  - type: the result of static_cast<std::underlying_type_t<access_type>>(v) for v in:
  - access_type::LOAD
  - access_type::RFO
  - access_type::PREFETCH
  - access_type::WRITE
  - access_type::TRANSLATION

The function should return metadata that will be stored alongside the block.
*/
void CACHE::update_replacement_state(uint32_t triggering_cpu, uint32_t set, uint32_t way, uint64_t full_addr, uint64_t ip, uint64_t victim_addr, uint32_t type,
                                     uint8_t hit)
{
  // Mark the way as being inserted on the current cycle
  if (!hit){
    ::last_inserted_cycles[this].at(set * NUM_WAY + way) = current_cycle;
  }
}

/* This function is called at the end of the simulation and can be used to print statistics. */
void CACHE::replacement_final_stats() {}
