/*****
 * array.h
 * Tom Prince 2005/06/18
 * 
 * Array type used by virtual machine.
 *****/

#ifndef ARRAY_H
#define ARRAY_H

#include "vm.h"
#include "memory.h"
#include "item.h"

namespace vm {

// Arrays are vectors with push and pop functions.
class array : public mem::deque<item>, public gc {
bool cycle;  
public:
  array(size_t n)
    : mem::deque<item>(n), cycle(false)
  {}

  void push(item i)
  {
    push_back(i);
  }

  item pop()
  {
    item i=back();
    pop_back();
    return i;
  }

  template <typename T>
  T read(size_t i)
  {
    return get<T>((*this)[i]);
  }
  
  void cyclic(bool b) {
    cycle=b;
  }
  
  bool cyclic() {
    return cycle;
  }
};

template <typename T>
inline T read(array *a, size_t i)
{
  return a->array::read<T>(i);
}

template <typename T>
inline T read(array &a, size_t i)
{
  return a.array::read<T>(i);
}

inline bool checkArray(vm::array *a)
{
  if(a == 0) vm::error("dereference of null array");
  return true;
}

extern const char *arraymismatch;

inline size_t checkArrays(vm::array *a, vm::array *b) 
{
  checkArray(a);
  checkArray(b);
  
  size_t asize=a->size();
  if(asize != b->size())
    vm::error(arraymismatch);
  return asize;
}
 
} // namespace vm

#endif // ARRAY_H
