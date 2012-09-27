-- Simple example that implements a runtime dependent check to
-- determine if a given string describes an existing ROS package.

require "umf"
require "rttros"

-- New ROSPack Spec
ROSPackSpec = umf.class("RosPackSpec", umf.StringSpec)

function ROSPackSpec.check(self, obj, vres)
   umf.log("validating object against ROSPackSpec")
   umf.vres_push_context(vres, self.name)
   local res = umf.StringSpec.check(self, obj, vres)

   if not res then return false end

   res = pcall(rttros.rospack_find, obj)
   if not res then
      umf.add_msg(vres, "err", tostring(obj) .. " not a known ROS package")
   end
   umf.vres_pop_context(vres)
   return res
end

RPC = ROSPackSpec{ name='ROSPackSpec' }

s1 = "rFSM"
s2 = "foobatschi"
s3 = 333
s4 = {'foo'}

print("s1: (OK)")
umf.check(s1, RPC, true)

print("s2:")
umf.check(s2, RPC, true)

print("s3:")
umf.check(s3, RPC, true)

print("s4:")
umf.check(s4, RPC, true)