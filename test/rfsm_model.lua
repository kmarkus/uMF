require "rfsm"
return rfsm.state {
   hello = rfsm.state{ entry=function() print("hello") end },
   world = rfsm.state{ entry=function() print("world") end },
   rfsm.transition { src='world', tgt='hello', events={ 'e_restart' } },
}