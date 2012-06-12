--- micro-OO: classes, object, simple inheritance.
-- Just enough required for umf modeling.

require "utils"
module("umf", package.seeall)

Object={}      -- Everything is derived from class Object.
Object_cops={} -- Methods of class
Object_iops={} -- Methods of instances of class

-- Object methods
function Object_iops:class() return getmetatable(self).class end
function Object_iops:type() return 'instance' end
function Object_iops:tostring() return "instance of class "..self:class():classname() end

-- Class methods
function Object_cops:super() return getmetatable(self).super end
function Object_cops:classname() return getmetatable(self).classname end
function Object_cops:tostring() return 'Class '.. self:classname() end
function Object_cops:type() return 'class' end
function Object_cops:cops() return getmetatable(self).__index end
function Object_cops:iops() return getmetatable(self).iops end
function Object_cops:addMethod(k,m) self:iops()[k]=m end

function Object_cops:new(t)
   local newobj = t or {}
   setmetatable(newobj, { class=Object, __index=Object_iops, __tostring=Object_iops.tostring })
   return newobj
end

setmetatable(Object, { classname='Object', iops=Object_iops, super=false,
		       __index=Object_cops, __newindex=Object_cops.addMethod,
		       __tostring=Object_cops.tostring, __call=Object_cops.new } )

--- Create a new class.
function class(name, base)
   base = base or Object
   local klass = {}
   local klass_iops={}
   local klass_cops={}

   -- Create Constructor
   function klass_cops:new(t)
      local newobj = t or {}
      setmetatable( newobj, { class=klass, __index=klass_iops })
      setmetatable( klass_iops, { __index=base:iops() })
      return newobj
   end

   setmetatable(klass, { classname=name, iops=klass_iops, super=base,
			 __index=klass_cops, __newindex=Object_cops.addMethod, __call=klass_cops.new  })
   setmetatable(klass_cops, { __index=base:cops() })
   return klass
end

function uoo_type(x)
   if not x then return false end
   local mt = getmetatable(x)
   if mt and mt.class then return 'instance'
   elseif mt and mt.classname then return 'class' end
   return false
end

function subclass_of(subklass, klass)
   function sc_of(sc, k)
      if not sc then return false end
      if sc==k then return true end
      return sc_of(sc:super(), k)
   end
   assert(uoo_type(subklass)=='class', "subclass_of: first argument not a class")
   assert(uoo_type(klass)=='class', "subclass_of: second argument not a class")
   return sc_of(subklass, klass)
end

function instance_of(klass, obj)
   assert(uoo_type(klass)=='class', "instance_of: first argument not a class")
   assert(uoo_type(obj)=='instance', "instance_of: second argument not an instance")
   return subclass_of(obj:class(), klass)
end