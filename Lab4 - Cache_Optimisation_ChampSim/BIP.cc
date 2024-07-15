#include <algorithm>
#include <cassert>
#include <map>
#include <vector>
#include "time.h"

#include "cache.h"

namespace
{

/* last_inserted_cycles - vector of last_used_cycle_number (uint64_t) corresponding to each line */
std::map<CACHE*, std::vector<bool>> isMRU;
std::map<CACHE*, std::vector<uint64_t>> count_MRU;
double epsilon = 50;
}

/*
initialize_replacement() is called when the cache is initialized. You can use it to initialize elements of dynamic structures, such as std::vector or std::map.
*/
void CACHE::initialize_replacement() {
  ::isMRU[this] = std::vector<bool>(NUM_SET * NUM_WAY, 0);
}

/*
find_victim() is called when a tag is checked in the cache. The parameters passed are:
*/
uint32_t CACHE::find_victim(uint32_t triggering_cpu, uint64_t instr_id, uint32_t set, const BLOCK* current_set, uint64_t ip, uint64_t full_addr, uint32_t type)
{
  auto begin = std::next(std::begin(::isMRU[this]), set * NUM_WAY);
  auto end = std::next(begin, NUM_WAY);

  // Find the way_index of any element in LRU ,i.e., isMRU = 0
  auto victim = begin;
  bool flag = false;
  for(auto it = begin; it != end; it++){
    if (*it == 0){
      victim = it;
      flag = true;
      break;
    }
  }
  if(flag == false){
    for(auto it = begin; it != end; it++){
      *it = 0;
    }
  }

  assert(begin <= victim); assert(victim < end);
  
  return static_cast<uint32_t>(std::distance(begin, victim)); // cast protected by prior asserts
}

// Generates 0 with probability (1-eps) and 1 with probability (eps)
bool bernoulli(double eps){
  std::srand(time(0));
  int randomInt = std::rand();
  double randomDouble = static_cast<double>(randomInt) / RAND_MAX;
  if (randomDouble > eps){ return 0; }
  else{ return 1; }
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
  // If not write_back hits, then update replacement state
    if(hit){
      // Promotes the element to MRU if hit
      ::isMRU[this].at(set * NUM_WAY + way) = 1;
    }
    else{
      // Cache lines inserted into MRU with probability eps and into LRU with probability 1-eps
      ::isMRU[this].at(set * NUM_WAY + way) = bernoulli(epsilon); 
    }
}

/* This function is called at the end of the simulation and can be used to print statistics. */
void CACHE::replacement_final_stats() {}