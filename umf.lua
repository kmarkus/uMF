--- micro-OO: classes, object, simple inheritance.
-- Just enough required for umf modeling.

require "utils"
module("umf", package.seeall)

--- Everything is derived from Object.
Object={}
Object_mt = { __index=Object }

function Object:new(t)
   local newobj = t or {}
   setmetatable(newobj, Object_mt)
   return newobj
end

function Object:type() return 'Object' end
function Object:tostring() return "class '"..self:type() end
function Object:class() return Object end
function Object:super() return false end
setmetatable(Object, { __call=Object.new }) -- just to be consistent

--- Create a new class.
function class(name, base)
   base = base or Object
   local klass = {}
   local klass_mt = { __index = klass }

   function klass:super() return base end

   -- Create Constructor
   function klass:new(t)
      local newobj = t or {}
      setmetatable( newobj, klass_mt)
      return newobj
   end

   -- return name of class
   function klass:type() return name end

   -- Return class object of instance.
   function klass:class() return klass end

   -- Enable inheritance + "call" constructors
   setmetatable(klass, { __index=base, __call=klass.new } )
   return klass
end

--- Check if one class is equal or a subclass of another.
function subclass_of(sc, c)
   if not sc then return false end
   if sc==c then return true
   else return  subclass_of(sc:super(), c) end
end

--- Check if obj is an instance of class.
function instance_of(klass, obj)
   if not klass then return false end
   local c = obj:class()
   if c == klass then return true
   else return subclass_of(c, klass) end
end
