
local umf=require "umf"
local utils=require "utils"

local table=table

local type=type
local assert=assert
local error=error
local pairs=pairs
local ipairs=ipairs
local print=print
local tostring=tostring

module("umf_check")

-- shortcuts
local class = umf.class

-- helpers
-- function log(...) print(...) end
function log(...) return end

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
   if not umf.instance_of(Spec, obj) then
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
local function add_msg(vres, level, msg)
   if not vres then return end
   if not (level=='err' or level=='warn' or level=='inf') then
      error("add_msg: invalid level: " .. tostring(level))
   end
   if not vres then return end
   local msgs = vres.msgs
   msgs[#msgs+1]=level .. ": " .. table.concat(vres.context, '.') .. " " .. msg
   vres[level] = vres[level] + 1
   return vres
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
   if #vres.context <= 0 then error("vres pop <= 0") end
   vres.context[#vres.context] = nil
end

--- True as long it is not nil.
function AnySpec.check(self, obj, vres)
   return obj==nil
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
   add_msg(vres, "err", "not a string but a " ..t)
   return false
end

--- Validate a function spec.
function FunctionSpec(self, obj, vres)
   log("checking function spec", obj)
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

function TableSpec.init(t)
   t.dict = t.dict or {}
   t.array = t.array or {}
end

--- Validate a table spec.
function TableSpec.check(self, obj, vres)
   local ret=true

   --- Check if val is a legal array entry type.
   local function check_array_entry(entry)
      local sealed = self.sealed == 'both' or self.sealed=='array'
      local arr_spec = self.array or {}
      for _,sp in ipairs(arr_spec) do if sp:check(entry) then return end end
      if sealed then
	 add_msg(vres, "err", "illegal/invalid entry '"..tostring(entry) .."' in array part")
	 ret=false
      else
	 add_msg(vres, "inf", "unkown entry '"..tostring(entry) .."' in array part")
      end
   end

   local function is_a_valid_spec(entry, spec_tab)
      for _,spec in ipairs(spec_tab) do
	 if spec:check(entry) then return true end
      end
      return false
   end

   local function check_dict_entry(entry, key)
      if key=='class' or key=='__other' then return end
      vres_push_context(vres, key)

      local sealed = self.sealed == 'both' or self.sealed=='dict'

      if sealed and not self.dict[key] then
	 add_msg(vres, "err", "unknown dict field '"..tostring(key).."' of type "..tostring(entry).." found in sealed table")
	 ret=false
      elseif not sealed and not self.dict[key] then
	 -- do we have a __other table to comply with?
	 -- tbd: we check wether it is a spec, but not if it is valid?!
	 if self.dict.__other then
	    if not is_a_valid_spec(entry, self.dict.__other) then
	       add_msg(vres, "err", "non legal value '"..tostring(entry).." of key '"..key.."' in unsealed dict")
	       ret=false
	    end
	 else
	    -- ignore it
	    add_msg(vres, "inf", "ignoring unkown field "..key)
	 end
      else
	 -- known key, check it.
	 if not self.dict[key]:check(entry, vres) then ret=false end
      end
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

   log("checking table spec")

   -- check we have a table
   local t = type(obj)
   if t ~= "table" then
      add_msg(vres, "err", "not a table but a " ..t)
      ret=false
   end

   local arr,dct = table_split(obj)

   utils.foreach(function (e) check_array_entry(e) end, arr)
   utils.foreach(function (e,k) check_dict_entry(e, k) end, dct)
   check_dict_optionals(dct)
   return ret
end

--- Check a class spec.
function ClassSpec.check(self, c, vres)
   log("validating class spec of type " .. self.name)
   vres_push_context(vres, self.name)

   -- classes are not the same or obj a subclass
   -- if not (self:type() == obj:type().name or umf.subclassOf(self.type, obj)) then
   if not umf.uoo_type(c)=='class' or not umf.subclass_of(c, self.type) then
      add_msg(vres, "err", "'"..tostring(c) .."' not of (sub-)class '"..tostring(self.type).."'")
      return false
   end
   local res=TableSpec:iops().check(self, c, vres)
   vres_pop_context(vres)
   return res
end

--- Check an object spec.
function ObjectSpec.check(self, obj, vres)
   log("validating object spec of type " .. self.name)
   vres_push_context(vres, self.name)
   if not umf.instance_of(self.type, obj) then
      add_msg(vres, "err", "'".. tostring(obj) .."' not an instance of '"..tostring(self.type).."'")
      return false
   end
   local res=TableSpec:iops().check(self, obj, vres)
   vres_pop_context(vres)
   return res
end


--- Print the validation results.
function print_vres(vres)
   utils.foreach(function(mes) print(mes) end, vres.msgs)
   print(tostring(vres.err) .. " errors, " .. tostring(vres.warn) .. " warnings, ".. tostring(vres.inf) .. " informational messages.")
end

--- Check a specification against an object.
function check(obj, spec)
   assert(umf.instance_of(Spec, spec), "check: invalid spec")
   local vres = { msgs={}, err=0, warn=0, inf=0 }

   spec:check(obj, vres)
   print_vres(vres)
   return vres
end
