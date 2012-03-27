

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
--    multi={
--	<spec>={ min=<number>, max=<number> },
--	<spec>={ min=<number>, max=<number> } }, -- optional, default is no constraints on multiplicity
--       ...
--    }
-- }

local umf=require "umf"
local utils=require "utils"
local type,assert,error=type,assert,error
local pairs, ipairs=pairs, ipairs
local print, tostring=print, tostring
local table=table

module("umf_check")

-- shortcuts
local class = umf.class

-- helpers
-- function log(...) print(...) end
function log(...) return end

-- Specifications
Spec=class("Spec")

--- Check if object complies to spec.
-- @param self spec object
-- @param obj object to validate
-- @param vres validation result structure (optional)
-- @return boolean return value meaning success
function Spec.check(self, obj, vres) error("Spec:check invoked") end

NumberSpec=class("NumberSpec", Spec)
StringSpec=class("StringSpec", Spec)
BoolSpec=class("BoolSpec", Spec)
EnumSpec=class("EnumSpec", Spec)

TableSpec=class("TableSpec", Spec)
ClassSpec=class("ClassSpec", TableSpec)


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

function vres_push_context(vres, field)
   vres.context=vres.context or {}
   vres.context[#vres.context+1] = field
end

function vres_pop_context(vres)
   vres.context=vres.context or {}
   if #vres.context <= 0 then error("vres pop <= 0") end
   vres.context[#vres.context] = nil
end

function NumberSpec.check(self, obj, vres)
   log("checking number spec", obj)
   local t = type(obj)
   if t == "number" then return true end
   add_msg(vres, "err", "not a number but a " ..t)
   return false
end

function StringSpec.check(self, obj, vres)
   log("checking string spec", obj)
   local t = type(obj)
   if t == "string" then return true end
   add_msg(vres, "err", "not a string but a " ..t)
   return false
end

function BoolSpec.check(self, obj, vres)
   log("checking boolean spec")
   local t = type(obj)
   if t == "boolean" then return true end
   add_msg(vres, "err", "not a string but a " ..t)
   return false
end

function EnumSpec.initialize(self, ...)
   self.legal_values={...}
end

function EnumSpec.check(self, obj, vres)
   if utils.table_has(self.legal_values, obj) then return true end
   add_msg(vres, "err", " invalid enum value: " .. tostring(obj))
end


--- Split a table in array and dictionary part.
function table_split(t)
   local arr,dict = {},{}
   for i,v in ipairs(t) do arr[i] = v end
   for k,v in pairs(t) do if not arr[k] then dict[k]=v end end
   return arr, dict
end

function TableSpec.check(self, obj, vres)

   --- Check if val is a legal array entry type.
   local function check_array_entry(entry)
      local arr_spec = self.array or {}
      for _,sp in ipairs(array_spec) do
	 if sp:check(val) then return true end
      end
      add_msg(vres, "err", "illegal entry "..tostring(entry) .."in array")
      return false
   end

   local function check_dict_entry(entry, key)
      if key=='class' then return true end -- middleclass class field
      vres_push_context(vres, key)
      local closed = self.sealed == 'both' or self.sealed=='dict'

      if closed and not self.dict[key] then
	 add_msg(vres, "err", "unknown dict field '"..tostring(key).."' of type "..tostring(entry).."found in sealed table")
	 return false
      elseif not closed and not self.dict[key] then
	 -- ignore it
	 add_msg(vres, "info", "ignoring unkown field "..key)
	 return true
      end
      -- known key, check it.
      local res=self.dict[key].val:check(entry, vres)
      vres_pop_context(vres)
      return res
   end
   
   -- Check that all non optional dict entries are there
   local function check_optionals()
   end

   log("checking table spec")

   -- check type
   local t = type(obj)
   if t ~= "table" then
      add_msg(vres, "err", "not a table but a " ..t)
      return false
   end

   local arr,dct = table_split(obj)

   vres_push_context(vres, "<array>")
   utils.foreach(function (e) check_array_entry(e) end, arr)
   vres_pop_context(vres)

   utils.foreach(function (e,k) check_dict_entry(e, k) end, dct)
   
end

function ClassSpec.check(self, obj, vres)
   log("validating class spec of type " .. self.name)
   vres_push_context(vres, self.name)
   if not umf.instanceOf(self.type, obj) then
      add_msg(vres, "err", " not of Class '"..self.type.name.."'")
      return false
   end
   TableSpec.check(self, obj, vres)
   vres_pop_context(vres)
end


--- Print the validation results.
function print_vres(vres)
   utils.foreach(function(mes) print(mes) end, vres.msgs)
   print(tostring(vres.err) .. " errors, " .. tostring(vres.warn) .. " warnings, ".. tostring(vres.inf) .. " informational messages")
end

function check(obj, spec)
   assert(umf.instanceOf(Spec, spec), "check: invalid spec")
   local vres = { msgs={}, err=0, warn=0, inf=0 }

   spec:check(obj, vres)
   print_vres(vres)
   return vres
end