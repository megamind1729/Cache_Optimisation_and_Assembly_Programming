#include <algorithm>
#include <array>
#include <map>
#include <optional>
#include <cassert>
#include "cache.h"

/* Implementing a lru table with elements as monitoring regions {start_cl_addr, stream_direction} */
class lru_table_custom
{
public:
  uint64_t TABLE_SIZE = 64;
  uint64_t PREFETCH_DISTANCE = 8;
  using value_type = std::pair<uint64_t, int64_t>;

  struct block_t {
    uint64_t last_used = 0;
    value_type data;    // data is {start_addr, stream_direction}
  };

  using block_vec_type = std::vector<block_t>;

  uint64_t access_count = 0;
  block_vec_type block{TABLE_SIZE};  // Initialises a vector of TABLE_SIZE monitoring regions
  

  auto comp()
  {
    /* x<y Comparison function which returns true, if x is not used, else both are used and x.last_used < y.last_used  */
    return [](const block_t &x, const block_t &y){
      auto x_valid = x.last_used > 0;
      auto cmp_lru = x.last_used < y.last_used;
      return !x_valid || cmp_lru;
    };
  }

  /* Function to insert a monitoring region into the monitoring_region_table */
  void insert_monitoring_region(const value_type& elem)
  {
    auto set_begin = std::begin(block);
    auto set_end = std::end(block);
    if (set_begin != set_end) {
      auto miss = std::min_element(set_begin, set_end, comp());
      *miss = {++access_count, elem};
    }
  }

  /* Function to return pointer to block, null if not found*/
  block_t* find_monitoring_region(uint64_t cl_addr){
    auto set_begin = block.begin();
    auto set_end = block.end();
    for(auto it = set_begin; it != set_end; it++){
        value_type data = it->data;
        if(data.second == 1){
            if(data.first <= cl_addr && cl_addr < static_cast<uint64_t>(static_cast<int64_t>(data.first) + data.second * static_cast<int64_t>(PREFETCH_DISTANCE)) ){
                it->last_used = ++access_count;
                return &(*it);    
            }
        }
        else if ((it->data).second == -1){
            if(data.first >= cl_addr && cl_addr > static_cast<uint64_t>(static_cast<int64_t>(data.first) + data.second * static_cast<int64_t>(PREFETCH_DISTANCE)) ){
                it->last_used = ++access_count;
                return &(*it);    
            }
        }
    }
    return nullptr;
  }
};

/* namespace contains struct tracker and map<CACHE*, tracker> trackers. */
namespace
{

/*
struct tracker contains:
  - struct monitoring_region - start_addr, stream_direction 
  - struct lookahead_entry - address, stride, degree
  - constants - PREFETCH_DEGREE (int)
  - std::optional<lookahead_entry> active_lookahead
  - lru_table<monitoring_region> table - table of monitoring regions
*/

struct tracker {

  struct lookahead_entry {
    uint64_t address = 0;
    int64_t stride = 0;
    int degree = 0; // degree remaining
  };

  constexpr static int PREFETCH_DEGREE = 10;
  constexpr static int PREFETCH_DISTANCE = 8;
  std::optional<lookahead_entry> active_lookahead;
  lru_table_custom table;

public:
  
  /*
  This function is used to initiate lookahead prefetching for a given cache line address.
  (cl_addr is currently divided by BLOCK_SIZE, can be thought of as line index.)
  It checks the monitoring_region table for a monitoring_region which contains cl_addr if it is a cache miss.
  If a stride is found and meets certain conditions, the code initializes prefetching (if not already active) by specifying the prefetch address, stride, and degree.
  */

  uint64_t prev_cl_addr = 0;
  int64_t prev_diff_addr = 0;
  int64_t diff_addr = 0;
  int64_t prev_direction = 0;
  int64_t direction = 0;

  void initiate_lookahead(uint64_t cl_addr)
  {

    /* 
    - find_monitoring_region(cl_addr) defined in structure of lru_table 
    - It checks whether there is a monitoring_region which contains cl_addr 
    - returns std::optional<monitoring_region>
    */
    auto found = table.find_monitoring_region(cl_addr);

    // calculate the stride between the current address and the last address
    // no need to check for overflow since these values are downshifted
    diff_addr = static_cast<int64_t>(cl_addr) - static_cast<int64_t>(prev_cl_addr);
    if(diff_addr > 0){ direction = 1; }
    else if(diff_addr < 0){ direction = -1; }
    else{ direction = 0; }

    // If we found a monitoring region containing cl_addr, found is not nullptr.
    // if (found.has_value()) {
    if (found) {
      uint64_t start_cl_addr = (found->data).first;
      int64_t stream_direction = (found->data).second;
      uint64_t end_cl_addr = static_cast<uint64_t>(static_cast<int64_t>(start_cl_addr) + stream_direction * static_cast<int64_t>(PREFETCH_DISTANCE));

      // If we got a miss in a monitoring region, prefetch the cache lines from end_addr to end_addr + stride*PREFETCH_DEGREE and update monitoring region to (start_addr + PREFETCH_DEGREE, end_addr + PREFETCH_DEGREE)
      active_lookahead = {end_cl_addr << LOG2_BLOCK_SIZE, stream_direction, PREFETCH_DEGREE};
      (found->data).first = static_cast<uint64_t>(static_cast<int64_t>(start_cl_addr) + stream_direction * static_cast<int64_t>(PREFETCH_DEGREE)) ;
    }

    // If we get three consecutive misses in the same direction within the range of (X, X +- PREFETCH_DISTANCE), insert a new monitoring region
    if(direction > 0 && prev_direction > 0 && (diff_addr + prev_diff_addr < static_cast<int64_t>(PREFETCH_DISTANCE))){
      table.insert_monitoring_region(std::pair(static_cast<uint64_t>(static_cast<int64_t>(cl_addr) - diff_addr - prev_diff_addr), direction));
    }
    else if(direction < 0 && prev_direction < 0 && (diff_addr + prev_diff_addr + static_cast<int64_t>(PREFETCH_DISTANCE) > 0)){
      table.insert_monitoring_region(std::pair(static_cast<uint64_t>(static_cast<int64_t>(cl_addr) - diff_addr - prev_diff_addr), direction));
    }

    prev_cl_addr = cl_addr;
    prev_direction = direction;
    prev_diff_addr = diff_addr;
  }

  /*
  If the active_lookahead (address, stride, degree) is active, advance_lookahead() prefetches the next cache line and updates active_lookahead with the next cache line to pre_fetch.  
  */
  void advance_lookahead(CACHE* cache)
  {
    // If the lookahead_entry (address, stride, degree) is active
    if (active_lookahead.has_value()) {

      auto [old_pf_address, stride, degree] = active_lookahead.value();
      assert(degree > 0);

      auto addr_delta = stride * BLOCK_SIZE;    // BLOCK_SIZE (size of one cache line)
      auto pf_address = static_cast<uint64_t>(static_cast<int64_t>(old_pf_address) + addr_delta); // cast to signed to allow negative strides

      // If the next step would exceed the degree or run off the page, stop
      if (cache->virtual_prefetch || (pf_address >> LOG2_PAGE_SIZE) == (old_pf_address >> LOG2_PAGE_SIZE)) {
        // check the MSHR (Miss Status Holding Registers) occupancy to decide if we're going to prefetch to this level or not
        bool success = cache->prefetch_line(pf_address, (cache->get_mshr_occupancy_ratio() < 0.5), 0);

        if (success)
          active_lookahead = {pf_address, stride, degree - 1};
        // If we fail, try again next cycle

        if (active_lookahead->degree == 0) {
          active_lookahead.reset();
        }
      } else {
        active_lookahead.reset();
      }
    }
  }
};

std::map<CACHE*, tracker> trackers;
} // namespace

/* 
prefetcher_initialize() is called when the cache is initialized. 
*/
void CACHE::prefetcher_initialize() {}

/*
prefetcher_cache_operate() is called when a tag is checked in the cache.
It calls initiate_lookahead(cl_addr) in case of a cache miss.
*/
uint32_t CACHE::prefetcher_cache_operate(uint64_t addr, uint64_t ip, uint8_t cache_hit, bool useful_prefetch, uint8_t type, uint32_t metadata_in)
{
  // Initiate a lookahead in case of a cache miss
  if(!cache_hit){
    /* Passing addr >> LOG2_BLOCK_SIZE [similar to dividing addr by size of cache line, i.e., similar to cache line index] */
    ::trackers[this].initiate_lookahead(addr >> LOG2_BLOCK_SIZE);
  }
  return metadata_in;
}

/*
prefetcher_cache_fill() is called when a miss is filled in the cache.
*/
uint32_t CACHE::prefetcher_cache_fill(uint64_t addr, uint32_t set, uint32_t way, uint8_t prefetch, uint64_t evicted_addr, uint32_t metadata_in){
  return metadata_in;
}

/* 
prefetcher_cycle_operate() - Called each cycle, after all other operations has completed. 
prefetcher_cycle_operate() calls advance_lookahead, which prefetches the cache lines if active_lookahead (address, stride, degree) is active.
*/
void CACHE::prefetcher_cycle_operate(){
    ::trackers[this].advance_lookahead(this);
}

/* This function is called at the end of the simulation and can be used to print statistics. */
void CACHE::prefetcher_final_stats(){}
