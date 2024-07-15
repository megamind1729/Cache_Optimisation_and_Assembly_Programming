#include <algorithm>
#include <cassert>
#include <map>
#include <vector>

#include "cache.h"

namespace
{
std::map<CACHE*, std::vector<uint64_t>> used_frequency;
}

/*
initialize_replacement() is called when the cache is initialized. You can use it to initialize elements of dynamic structures, such as std::vector or std::map.
*/
void CACHE::initialize_replacement() { ::used_frequency[this] = std::vector<uint64_t>(NUM_SET * NUM_WAY); }

uint32_t CACHE::find_victim(uint32_t triggering_cpu, uint64_t instr_id, uint32_t set, const BLOCK* current_set, uint64_t ip, uint64_t full_addr, uint32_t type)
{
  auto begin = std::next(std::begin(::used_frequency[this]), set * NUM_WAY);
  auto end = std::next(begin, NUM_WAY);

  // Find the way whose frequency is least
  auto victim = std::min_element(begin, end);
  assert(begin <= victim);
  assert(victim < end);
  
  // Updating used_frequency at to 0
  uint32_t way = static_cast<uint32_t>(std::distance(begin, victim));
  ::used_frequency[this].at(set * NUM_WAY + way) = 0;
  
  return static_cast<uint32_t>(std::distance(begin, victim)); // cast protected by prior asserts
}

void CACHE::update_replacement_state(uint32_t triggering_cpu, uint32_t set, uint32_t way, uint64_t full_addr, uint64_t ip, uint64_t victim_addr, uint32_t type,
                                     uint8_t hit)
{
  // Increment the frequency of way used currently
  if (!hit || access_type{type} != access_type::WRITE) // Skip this for writeback hits
    ::used_frequency[this].at(set * NUM_WAY + way) += 1;
  // Initialised to 0, during eviction
}

void CACHE::replacement_final_stats() {}
