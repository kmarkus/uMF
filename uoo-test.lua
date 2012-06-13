
require "umf"

Animal=umf.class("Animal")
Mammal=umf.class("Mammal", Animal)
Human=umf.class("Human", Mammal)

function Mammal:name()
   print ("mammal name: ", self.name)
end

function Mammal:speak()
   print("wuff")
end

function Human:speak()
   print("haloelle says ".. self.name)
end

function Mammal:init()
   self.mammal='seal'
end

a1=Animal{}
m1=Mammal{ name="bello" }
h1=Human{ name="Jeff"}

print("m1:speak()")
m1:speak()
print("h1:speak()")
h1:speak()


print("instance_of(a1, Animal):", umf.instance_of(Animal, a1))
print("instance_of(m1, Animal):", umf.instance_of(Animal, m1))
print("instance_of(h1, Animal):", umf.instance_of(Animal, h1))

print("instance_of(a1, Mammal):", umf.instance_of(Mammal, a1))
print("instance_of(m1, Mammal):", umf.instance_of(Mammal, m1))
print("instance_of(h1, Mammal):", umf.instance_of(Mammal, h1))

print("instance_of(a1, Human): ", umf.instance_of(Human, a1))
print("instance_of(m1, Human): ", umf.instance_of(Human, m1))
print("instance_of(h1, Human): ", umf.instance_of(Human, h1))

print("instance_of(a1, Object):", umf.instance_of(umf.Object, a1))
print("instance_of(m1, Object):", umf.instance_of(umf.Object, m1))
print("instance_of(h1, Object):", umf.instance_of(umf.Object, h1))


-- print("instance_of(Animal, Object):", umf.instance_of(Animal, uoo.Object))
-- print("instance_of(Mammal, Object):", umf.instance_of(Mammal, uoo.Object))
-- print("instance_of(Human, Object):", umf.instance_of(Human, uoo.Object))

