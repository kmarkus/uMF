--
-- This file is part of uMF.
--
-- (C) 2012 Markus Klotzbuecher, markus.klotzbuecher@mech.kuleuven.be,
-- Department of Mechanical Engineering, Katholieke Universiteit
-- Leuven, Belgium.
--
-- You may redistribute this software and/or modify it under either
-- the terms of the GNU Lesser General Public License version 2.1
-- (LGPLv2.1 <http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html>)
-- or (at your discretion) of the Modified BSD License: Redistribution
-- and use in source and binary forms, with or without modification,
-- are permitted provided that the following conditions are met:
--    1. Redistributions of source code must retain the above copyright
--       notice, this list of conditions and the following disclaimer.
--    2. Redistributions in binary form must reproduce the above
--       copyright notice, this list of conditions and the following
--       disclaimer in the documentation and/or other materials provided
--       with the distribution.
--    3. The name of the author may not be used to endorse or promote
--       products derived from this software without specific prior
--       written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS
-- OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
-- WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
-- ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
-- DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
-- DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
-- GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
-- WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
-- NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
-- SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--

--- micro-OO: classes, objects, simple inheritance, constructors.
-- Just enough for umf modeling.

local color=true
local logmsgs = true

local ac=require("ansicolors")
local utils=require("utils")
local ts = tostring

module("umf", package.seeall)

function log(...) print(...) end
-- function log(...) return end

--- microObjects:
local function __class(name, super)
   local klass = { name=name, superclass=super, static = {}, iops={}, __class_identifier=true }
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

--- uMF spec validation.

--- Split a table in array and dictionary part.
function table_split(t)
   local arr,dict = {},{}
   for i,v in ipairs(t) do arr[i] = v end
   for k,v in pairs(t) do if not arr[k] then dict[k]=v end end
   return arr, dict
end

-- Specifications
Spec=class("Spec")

--- Check if object complies to spec.
-- @param self spec object
-- @param obj object to validate
-- @param vres validation result structure (optional)
-- @return boolean return value meaning success
function Spec.check(self, obj, vres)
   if not instance_of(Spec, obj) then
      add_msg(vres, "err", tostring(obj).." not an instance of "..tostring(self.type))
      return false
   end
   return true
end

--- Check if obj is of the correct type.
-- This does not mean it is validated.
function Spec.is_a(self, obj, vres) error("Spec:is_a invoked") end

AnySpec=class("AnySpec", Spec)
NumberSpec=class("NumberSpec", Spec)
StringSpec=class("StringSpec", Spec)
BoolSpec=class("BoolSpec", Spec)
FunctionSpec=class("FunctionSpec", Spec)
EnumSpec=class("EnumSpec", Spec)
TableSpec=class("TableSpec", Spec)
ClassSpec=class("ClassSpec", TableSpec)
ObjectSpec=class("ObjectSpec", TableSpec)

--- Add an error to the validation result struct.
-- @param validation structure
-- @param level: 'err', 'warn', 'inf'
-- @param msg string message
function add_msg(vres, level, msg)
   local function colorize(level, msg)
      if not color then return msg end
      if level=='inf' then return ac.blue(ac.bright(msg))
      elseif level=='warn' then return ac.yellow(msg)
      elseif level=='err' then return ac.red(ac.bright(msg)) end
   end
   if not vres then return end
   if not (level=='err' or level=='warn' or level=='inf') then
      error("add_msg: invalid level: " .. tostring(level))
   end
   local msgs = vres.msgs
   msgs[#msgs+1]=colorize(level, level .. " @ " .. table.concat(vres.context, '.') .. ": " .. msg)
   vres[level] = vres[level] + 1
   return vres
end

function vres_add_newline(vres)
   if not vres then return end -- not sure this is necessary/correct/
   local msgs = vres.msgs
   msgs[#msgs+1] = ''
end

--- Push error message context.
-- @param vres validation result table
-- @param field current context in form of table field.
function vres_push_context(vres, field)
   if not vres then return end
   vres.context=vres.context or {}
   vres.context[#vres.context+1] = field
end

--- Pop error message context.
-- @param vres validation result table
function vres_pop_context(vres)
   if not vres then return end
   vres.context=vres.context or {}
   if #vres.context < 0 then error("vres pop < 0") end
   vres.context[#vres.context] = nil
end

--- True as long it is not nil.
function AnySpec.check(self, obj, vres)
   log("checking AnySpec spec", ts(obj))
   if obj==nil then
      add_msg(vres, "err", "obj is nil")
      return false
   end
   return true
end

--- Number spec.
function NumberSpec.is_a(self, obj)
   return type(obj) == "number"
end

function NumberSpec.check(self, obj, vres)
   log("checking number spec", obj)
   local t = type(obj)
   if t ~= "number" then
      add_msg(vres, "err", "not a number but a " ..t)
      return false
   end
   if self.min and obj < self.min then
      add_msg(vres, "err", "number value="..tostring(obj).. " beneath min="..tostring(self.min))
      return false
   end
   if self.max and obj > self.max then
      add_msg(vres, "err", "number value="..tostring(obj).. " above max="..tostring(self.max))
      return false
   end
   return true
end

--- Validate a string spec.
function StringSpec.check(self, obj, vres)
   log("checking string spec", obj)
   local t = type(obj)
   if t == "string" then return true end
   add_msg(vres, "err", "not a string but a " ..t)
   return false
end

--- Validate a boolean spec.
function BoolSpec.check(self, obj, vres)
   log("checking boolean spec")
   local t = type(obj)
   if t == "boolean" then return true end
   add_msg(vres, "err", "not a boolean but a " ..t)
   return false
end

--- Validate a function spec.
function FunctionSpec.check(self, obj, vres)
   log("checking function spec against object "..tostring(obj))
   local t = type(obj)
   if t == "function" then return true end
   add_msg(vres, "err", "not a function but a " ..t)
   return false
end

--- Validate an enum spec.
function EnumSpec.check(self, obj, vres)
   if utils.table_has(self, obj) then return true end
   add_msg(vres, "err", "invalid enum value: " .. tostring(obj) .. " (valid: " .. table.concat(self, ", ")..")")
end

function TableSpec:init()
   self.dict = self.dict or {}
   self.array = self.array or {}
end

--- Validate a table spec.
-- This is the most important function of uMF.
function TableSpec.check(self, obj, vres)
   local ret=true

   local function is_a_valid_spec(entry, spec_tab, vres)
      spec_tab = spec_tab or {}
      for _,spec in ipairs(spec_tab) do
	 if spec:check(entry, vres) then return true end
      end
      return false
   end


   --- Check if entry is a legal array entry type.
   local function check_array_entry(entry)
      local sealed = self.sealed == 'both' or self.sealed=='array'
      local arr_spec = self.array or {}
      for _,sp in ipairs(arr_spec) do
	 if sp:check(entry) then return end
      end
      print("array checking could not legitimize ", ts(entry))
      if sealed then
	 add_msg(vres, "err", "illegal/invalid entry array part. Error(s) follow:")
	 is_a_valid_spec(entry, arr_spec, vres)
	 vres_add_newline(vres)
	 log("checking array failed")
	 ret=false
      else
	 add_msg(vres, "inf", "unkown entry '"..tostring(entry) .."' in array part")
      end
   end

   --- Check if key=entry are valid for the TableSpec 'self'.
   local function check_dict_entry(entry, key)
      -- if key=='__other' then return end ?
      vres_push_context(vres, key)
      local sealed = self.sealed == 'both' or self.sealed=='dict'

      -- known key, check it.
      if self.dict[key] then
	 if not self.dict[key]:check(entry, vres) then
	    ret=false
	    log("key " .. ts(key) .. "found but spec checking failed")
	 else
	    log("key " .. ts(key) .. " found and spec checking OK")
	 end
      elseif not self.dict.__other and sealed then -- unkown key, no __other and sealed -> err!
	 add_msg(vres, "err", "illegal field "..key.." in sealed dict (value: "..tostring(entry)..")")
      elseif not self.dict[key] and is_a_valid_spec(entry, self.dict.__other) then
	 log("found matching spec in __other table")
      elseif not self.dict[key] and not is_a_valid_spec(entry, self.dict.__other) then
	 if sealed then
	    add_msg(vres, "err", "checking __other failed for undeclared key '".. key..
		    "' in sealed dict. Error(s) follow:")
	    -- add errmsg of __other check
	    is_a_valid_spec(entry, self.dict.__other, vres)
	    vres_add_newline(vres)
	    log("checking __other for key "..key.. " failed")
	    ret=false
	 else
	    add_msg(vres, "inf", "ignoring unkown field "..key.." in unsealed dict")
	 end
      else error("should not get here") end
      vres_pop_context(vres)
      return
   end

   -- Check that all non optional dict entries are there
   local function check_dict_optionals(dct)
      -- build a list of non-optionals
      nopts={}
      local optional=self.optional or {}
      for field,spec in pairs(self.dict) do
	 if field~='__other' and not utils.table_has(optional, field) then
	    nopts[#nopts+1] = field
	 end
      end

      -- check all non optionals are defined
      for _,nopt_field in ipairs(nopts) do
	 if not dct[nopt_field] then
	    add_msg(vres, "err", "non-optional field '"..nopt_field.."' missing")
	    ret=false
	 end
      end
   end

   log("checking table spec "..(self.name or "unnamed"))

   -- check we have a table
   local t = type(obj)
   if t ~= "table" then
      add_msg(vres, "err", "not a table but a " ..t)
      return false -- fatal.
   end

   vres_push_context(vres, self.name)
   if self.precheck then ret=self.precheck(self, obj, vres) end -- precheck hook

   if ret then
      local arr,dct = table_split(obj)
      utils.foreach(function (e) check_array_entry(e) end, arr)
      utils.foreach(function (e,k) check_dict_entry(e, k) end, dct)
      check_dict_optionals(dct)
   end

   if self.postcheck and ret then ret=self.postcheck(self, obj, vres) end

   vres_pop_context(vres)
   log("checked table spec "..(self.name or "unnamed")..", result: "..tostring(ret))
   return ret
end

--- Check a class spec.
function ClassSpec.check(self, c, vres)
   log("validating class spec of type " .. self.name)
   vres_push_context(vres, self.name)

   -- check that they are classes
   if not uoo_type(c)=='class' or not subclass_of(c, self.type) then
      add_msg(vres, "err", "'"..tostring(c) .."' not of (sub-)class '"..tostring(self.type).."'")
      return false
   end
   vres_pop_context(vres)
   local res=TableSpec.check(self, c, vres)
   return res
end

--- Check an object spec.
function ObjectSpec.check(self, obj, vres)
   local res=true
   log("validating object spec of type " .. self.name)
   vres_push_context(vres, self.name)
   if uoo_type(self.type) ~= 'class' then
      add_msg(vres, "err", "type field of ObjectSpec "..tostring(self.name).. " is not a umf class")
      res=false
   elseif uoo_type(obj) ~= 'instance' then
      add_msg(vres, "err", "given object is not an umf class instance but a '"..tostring(type(obj)).."'")
      res = false
   elseif not instance_of(self.type, obj) then
      add_msg(vres, "err", "'".. tostring(obj) .."' not an instance of '"..tostring(self.type).."'")
      res=false
   end
   vres_pop_context(vres)
   if res then res=TableSpec.check(self, obj, vres) end
   return res
end

--- Print the validation results.
function print_vres(vres)
   utils.foreach(function(mes) print(mes) end, vres.msgs)
   print(tostring(vres.err) .. " errors, " .. tostring(vres.warn) .. " warnings, ".. tostring(vres.inf) .. " informational messages.")
end

--- Check a specification against an object.
-- @param object object to check
-- @param spec umf spec to check against.
-- @return number of errors
-- @return validation result table
function check(obj, spec, verb)
   -- spec must be an instance of Spec:
   if verb then print("checking spec "..(spec.name or "unnamed")) end
   local ok, ret = pcall(instance_of, Spec, spec)
   if not ok then print("err: second argument not an Object (should be Spec instance)"); return false
   elseif ok and not ret then print("err: spec not an instance of umf.Spec\n"..msg); return false end

   local vres = { msgs={}, err=0, warn=0, inf=0, context={} }
   spec:check(obj, vres)
   if verb then print_vres(vres) end
   return vres.err, vres
end
