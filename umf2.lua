
local function _setClassDictionariesMetatables(klass)
  local dict = klass.iops
  dict.__index = dict

  local super = klass.super
  if super then
    local superStatic = super.static
    setmetatable(dict, super.iops)
    setmetatable(klass.static, { __index = function(_,k) return dict[k] or superStatic[k] end })
  else
    setmetatable(klass.static, { __index = function(_,k) return dict[k] end })
  end
end

local function _setClassMetatable(klass)
  setmetatable(klass, {
    __tostring = function() return "class " .. klass.name end,
    __index    = klass.static,
    __newindex = klass.iops,
    __call     = function(self, ...) return self:new(...) end
  })
end

function class(name, super)
  local klass = { name = name, super = super, static = {}, __mixins = {}, iops={} }
  -- klass.subclasses = setmetatable({}, {__mode = "k"})

  _setClassDictionariesMetatables(klass)
  _setClassMetatable(klass)
  --_classes[klass] = true

  return klass
end

Object = class("Object", nil)

function Object.static:allocate(t)
   --assert(_classes[self], "Make sure that you are using 'Class:allocate' instead of 'Class.allocate'")
   return setmetatable(t, self.iops)
end

function Object.static:new(t)
   local obj = self:allocate(t)
   --obj:initialize()
   return obj
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


-- print("instance_of(a1, Animal):", instance_of(Animal, a1))
-- print("instance_of(m1, Animal):", instance_of(Animal, m1))
-- print("instance_of(h1, Animal):", instance_of(Animal, h1))

-- print("instance_of(a1, Mammal):", instance_of(Mammal, a1))
-- print("instance_of(m1, Mammal):", instance_of(Mammal, m1))
-- print("instance_of(h1, Mammal):", instance_of(Mammal, h1))

-- print("instance_of(a1, Human): ", instance_of(Human, a1))
-- print("instance_of(m1, Human): ", instance_of(Human, m1))
-- print("instance_of(h1, Human): ", instance_of(Human, h1))

-- print("instance_of(a1, Object):", instance_of(Object, a1))
-- print("instance_of(m1, Object):", instance_of(Object, m1))
-- print("instance_of(h1, Object):", instance_of(Object, h1))


-- print("instance_of(Animal, Object):", instance_of(Animal, uoo.Object))
-- print("instance_of(Mammal, Object):", instance_of(Mammal, uoo.Object))
-- print("instance_of(Human, Object):", instance_of(Human, uoo.Object))

