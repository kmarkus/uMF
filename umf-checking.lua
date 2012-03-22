

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
--    array_multi={
--	{ spec=<spec>, min=<number>, max=<number> },
--	{ spec=<spec>, min=<number>, max=<number> } }, -- optional, default is no constraints on multiplicity
--
--    multi={
--      { spec=<spec>, min=<number>, max=<number> } }, -- optional, default is no constraints on multiplicity
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
	       function (x) return umf_is_a(x, Spec) end, },
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

--- Specification of a frame
frame_spec =  spec{
   name='kdl_frame',
   type='table',
   sealed='both',
   
   dict={
      M=spec{
	 name='kdl_rotation',
	 type='table',
	 sealed='both',
	 dict= { X_x = spec{type='number'}, Y_x = spec{type='number'}, Z_x = spec{type='number'},
		 X_y = spec{type='number'}, Y_y = spec{type='number'}, Z_y = spec{type='number'},
		 X_z = spec{type='number'}, Y_z = spec{type='number'}, Z_z = spec{type='number'} }
      },
      p=spec{
	 name='kdl_vector',
	 type='table',
	 sealed='both',
	 dict={X = spec{type='number'}, Y = spec{type='number'}, Z = spec{type='number'} } }
   }
}

-- Robot spec
robot_spec = {
   name='itasc_robot' -- only used for debug messages
   type=Robot,	-- result of type(obj)
   sealed='both',-- no other fields than the mentioned permitted?

   dict={
      name=spec{type='string'},
      location=frame_spec,
      package=spec{type='string'},
      type=spec{type='string'},
   },
}

--- Add an error to the validation result struct.
-- @param validation structure
-- @param level: 'err', 'warn', 'inf'
-- @param msg string message
local function add_msg(vres, level, msg)
   if not level='err' or not level='warn' or not level='inf' then
      error("add_msg: invalid level: " .. tostring(level))
   end
   local msgs = vres.msgs
   msgs[#msgs+1]=level .. ": " .. msgs
   vres[level] = vres[level] + 1
   return vres
end

--- Validate that the type of obj is
local function vali_type(obj, spec, vres)
end

--- Validate sealed property.
local function vali_sealed(obj, spec, vres)
   
end

--- Validate the dictionary part.
local function vali_dict(obj, spec, vres)
end

--- Validate array part.
local function vali_array(obj, spec, vres)
end


function validate_spec(obj, spec)
   local vres = { msgs={}, err=0, warn=0, inf=0 }
   validate_type(obj, spec, vres)
   return vres
end