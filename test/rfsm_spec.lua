require "rfsm"
require "strict"
local state_spec, trans_spec, conn_spec

conn_spec = TableSpec {
   name='conn_spec',
   sealed='both'
}

trans_spec = TableSpec {
   name='trans_spec',
   sealed='both',
   dict={
      src=StringSpec{},
      tgt=StringSpec{},
      guard=FunctionSpec{},
      effect=FunctionSpec{},
      events=TableSpec{ name='trans_event_list', sealed='both', array={StringSpec{} } },
      pn=NumberSpec{min=0},
   },
   optional={'guard', 'pn', 'effect', 'events' },
}

state_spec = TableSpec {
   name='rfsm_state',
   sealed = 'both',
   dict = {
      entry = FunctionSpec{},
      doo = FunctionSpec{},
      exit = FunctionSpec{},
      __other={ trans_spec, conn_spec },
   },
   optional={'entry', 'doo', 'exit' },
   array = { trans_spec, conn_spec },
}
state_spec.dict.__other[#state_spec.dict.__other+1] = state_spec

return TableSpec{
   name='rfsm_root_state',
   sealed='both',
   dict={
      dbg = FunctionSpec{},
      info = FunctionSpec{},
      warn = FunctionSpec{},
      err = FunctionSpec{},
      getevents = FunctionSpec{},

      entry = FunctionSpec{},
      doo = FunctionSpec{},
      exit = FunctionSpec{},
      __other={ state_spec, trans_spec, conn_spec },
   },
   optional = { 'dbg', 'warn', 'info', 'err', 'getevents', 'entry', 'doo', 'exit' },

   array = { trans_spec, conn_spec },
}
