
function __class(name, super)
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




Animal=class("Animal", Object)
Mammal=class("Mammal", Animal)
Human=class("Human", Mammal)

function Mammal:name()
   print ("mammal name: ", self.name)
end

function Mammal:speak()
   print("wuff")
end

function Human:speak()
   print("haloelle says ".. self.name)
end

a1=Animal{}
m1=Mammal{ name="bello" }
h1=Human{ name="Jeff"}

print("m1:speak()")
m1:speak()
print("h1:speak()")
h1:speak()


print("instance_of(a1, Animal):", instance_of(Animal, a1))
print("instance_of(m1, Animal):", instance_of(Animal, m1))
print("instance_of(h1, Animal):", instance_of(Animal, h1))

print("instance_of(a1, Mammal):", instance_of(Mammal, a1))
print("instance_of(m1, Mammal):", instance_of(Mammal, m1))
print("instance_of(h1, Mammal):", instance_of(Mammal, h1))

print("instance_of(a1, Human): ", instance_of(Human, a1))
print("instance_of(m1, Human): ", instance_of(Human, m1))
print("instance_of(h1, Human): ", instance_of(Human, h1))

print("instance_of(a1, Object):", instance_of(Object, a1))
print("instance_of(m1, Object):", instance_of(Object, m1))
print("instance_of(h1, Object):", instance_of(Object, h1))


-- print("instance_of(Animal, Object):", instance_of(Animal, uoo.Object))
-- print("instance_of(Mammal, Object):", instance_of(Mammal, uoo.Object))
-- print("instance_of(Human, Object):", instance_of(Human, uoo.Object))

