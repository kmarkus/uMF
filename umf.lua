--- micro-OO: classes, objects, simple inheritance, constructors.
-- Just enough for umf modeling.

require("utils")
module("umf", package.seeall)

local function __class(name, super)
   local klass = { name=name, superclass=super, static = {}, iops={}, __class_identifier=true }

   -- setup iops
   local iops = klass.iops
   iops.__index = iops

   if super then
      local superStatic = super.static
      setmetatable(iops, super.iops)
      setmetatable(klass.static, { __index = function(_,k) return iops[k] or superStatic[k] end })
   else
      setmetatable(klass.static, { __index = function(_,k) return iops[k] end })
   end

  setmetatable(klass, {
    __tostring = function() return "class " .. klass.name end,
    __index    = klass.static,
    __newindex = klass.iops,
    __call     = function(self, ...) return self:new(...) end
  })

  klass.class=function(_) return klass end -- enable access to class
  return klass
end

Object = __class("Object")

function class(name, super) return __class(name, super or Object) end

function Object.static:new(t)
   local obj = setmetatable(t or {}, self.iops)
   obj:init()
   return obj
end

function Object.static:super() return self.superclass end
function Object.static:classname() return self.name end
function Object.static:type() return 'class' end
function Object:init() return end

function uoo_type(x)
   if not x then return false end
   local mt = getmetatable(x)
   if mt and mt.__index==x.static then return 'class'
   elseif mt and mt.class then return 'instance' end
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

