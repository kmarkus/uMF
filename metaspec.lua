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
