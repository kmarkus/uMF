

---module("uml-checking")

--- Spec definition
-- {
--    name=string
--    type=['string', 'number', 'boolean', 'thread', 'table', 'enum', <umf_class>]		-- result of type(obj)  (required!)
--    enum={},			-- if type==enum, then list of legal values or predicates (optional)
--    optional			-- if true, then field does not have to exist (optional, default=false)
--    predicates={}		-- additional checks (optional), should return true,false and errmsg if false.
--
--    -- subfield related (only if type is class)
--    sealed=['array'|'dict'|'both']	-- other subfields permitted than the mentioned? (optional, default=false)
--    dict={name1=spec1, name2=spec2, specA, specB...} -- optional, default={}
--       name1 must be of spec1, etc. all others must be of specA or specB
-- 
--    array={spec, spec,...}, -- optional, default={}
--
--    multi={
--	<spec>={ min=<number>, max=<number> },
--	<spec>={ min=<number>, max=<number> } }, -- optional, default is no constraints on multiplicity
--       ...
--    }
-- }

-- Metacircular spec of spec, howdee!
spec_spec = spec{
   name='spec',
   type=Spec,
   sealed=both,
   
   dict={
      name=spec{ type='string' },

      type=spec{
	 type='enum',
	 enum={'string', 'number', 'boolean', 'function', 'thread', 'table', 'enum', 
	       function (x) return umf.instanceOf(x, Spec) end, },
      },

      enum=spec{
	 type='table',
	 sealed='dict',
	 array={spec{type='string'},
		spec{type='boolean'},
		spec{type='number'},
		spec{type='function'} } 
      },

      optional=spec{ type='enum', enum={true, false} },

      predicates=spec{
	 sealed='both',
	 array={spec{type='function'} },
      },

      sealed=spec{ type='enum', enum={'both', 'array', 'dict'} },
      
      dict=spec{ 
	 type='table', 
	 sealed='array'
	 dict={Spec},		-- all values must be of type Spec
      },

      array=spec{
	 type='table',
	 sealed='dict',
	 array={Spec}
      },
   }
}		
