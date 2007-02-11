/*****
 * record.cc
 * Tom Prince 2004/07/15
 *
 * The type for records and modules in the language.
 *****/

#include "record.h"
#include "inst.h"
#include "runtime.h"
#include "coder.h"

namespace types {

record::record(symbol *name, frame *level)
  : ty(ty_record),
    name(name),
    level(level),
    init(new vm::lambda),
    e()
{
  assert(init);
}

record::~record()
{}

record *record::newRecord(symbol *id, bool statically)
{
  frame *underlevel = getLevel(statically);
  assert(underlevel);
    
  frame *level = new frame(underlevel, 0);

  record *r = new record(id, level);
  return r;
}

// Initialize to null by default.
trans::access *record::initializer() {
  static trans::bltinAccess a(run::pushNullRecord);
  return &a;
}

dummyRecord::dummyRecord(symbol *name) 
  : record(name, new frame(0,0))
{
  // Encode the instructions to put an placeholder instance of the record
  // on the stack.
  trans::coder c(this, 0);
  c.closeRecord();
}

dummyRecord::dummyRecord(string s)
  : record (symbol::trans(s), new frame(0,0))
{
  // Encode the instructions to put an placeholder instance of the record
  // on the stack.
  trans::coder c(this, 0);
  c.closeRecord();
}

void dummyRecord::add(string name, ty *t, trans::access *a) {
  e.addVar(symbol::trans(name), new trans::varEntry(t, a, this, position())); 
}

void dummyRecord::add(string name, function *t, vm::bltin f) {
  add(name, t, new trans::bltinAccess(f));
}

} // namespace types
