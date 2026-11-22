--
-- This file is part of uMF.
--
-- (C) 2012-2020 Markus Klotzbuecher, mk@mkio.de
--
-- SPDX-License-Identifier: BSD-3-Clause
--
-- micro-OO: classes, objects, simple inheritance, constructors.
-- Just enough for umf modeling.

local color=true

local ac=require("ansicolors")
local utils=require("utils")
local ts = tostring

-- emulate module("umf", package.seeall) for lua 5.1 to 5.4+:
-- globals defined below go into M, lookups fall back to _G.
local M = setmetatable({}, { __index = _G })
local _ENV = M
if setfenv then setfenv(1, M) end
_G.umf = M -- compat: users rely on the global set by module()

-- log stuff
local ind, indmul, indchar = 0, 4, ' '
function ind_inc() ind=ind+1 end
function ind_dec() ind=ind-1 end

--- Debug log, enable with umf.log_enabled=true.
-- Arguments are joined with ' ' and converted with tostring only when
-- enabled, so call sites pass pieces instead of concatenating.
log_enabled = false
function log(...)
   if not log_enabled then return end
   local n, t = select('#', ...), {...}
   for i=1,n do t[i]=tostring(t[i]) end
   io.write(string.rep(indchar, ind*indmul), table.concat(t, ' ', 1, n), '\n')
end

--- microObjects, heavily inspired by middleclass.
local function __class(name, super)   local klass = { name=name, superclass=super, static = {}, iops={}, __class_identifier=true }
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

--- Return the uoo type ('class' or 'instance')
function uoo_type(x)
   if type(x) ~= 'table' then return false end
   local mt = getmetatable(x)
   if mt and mt.__index==x.static then return 'class'
   elseif mt and mt.class then return 'instance' end
   return false
end

--- Return the class name of the given object.
function uoo_class(o)
   if uoo_type(o) == 'instance' then
      return o:class().name
   end
   return false
end

function subclass_of(subklass, klass)
   local function sc_of(sc, k)
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
   for k,v in pairs(t) do if arr[k]==nil then dict[k]=v end end
   return arr, dict
end

-- Specifications
Spec=class("Spec")

--- Check if object complies to spec.
-- @param self spec object
-- @param obj object to validate
-- @param vres validation result structure (optional)
-- @return boolean return value meaning success
--- True if x is a Spec instance.
function is_spec(x)
   return uoo_type(x) == 'instance' and instance_of(Spec, x)
end

function Spec.check(self, obj, vres)
   if not is_spec(obj) then
      add_msg(vres, "err", tostring(obj).." not an instance of umf.Spec")
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

-- concatenate the validation context in a smart way, ie. no dots
-- before [].
local function concat_ctx(ctx,sep)
   local ret = ""
   for i,v in ipairs(ctx) do
      if string.match(v, "%[(%d+)]") then ret=ret..v else ret=ret..sep..v end
   end
   return ret
end

--- Add an error to the validation result struct.
-- @param validation structure
-- @param level: 'err', 'warn', 'inf'
-- @param msg string message
function add_msg(vres, level, msg)
   local function colorize(tag, msg, bright)
      if not color then return msg end
      if tag=='inf' then msg = ac.blue(msg)
      elseif tag=='warn' then msg = ac.yellow(msg)
      elseif tag=='err' then msg = ac.red(msg)
      elseif tag=='ctx' then msg = ac.cyan(msg) end
      if bright then msg = ac.bright(msg) end
      return msg
   end

   if not vres then return end
   if not (level=='err' or level=='warn' or level=='inf') then
      error("add_msg: invalid level: " .. tostring(level))
   end
   local msgs = vres.msgs
   msgs[#msgs+1] = colorize(level, level.." @ ", true) .. colorize("ctx", concat_ctx(vres.context, '.')..": ").. colorize(level, msg)
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
   if type(field) ~= 'string' then error("vres_push_context: field not a string but "..type(field)) end
   local depth = #vres.context
   vres.context[depth+1] = field
   return depth
end

--- Pop error message context.
-- @param vres validation result table
function vres_pop_context(vres, old_depth)
   if not vres then return end
   vres.context=vres.context or {}
   local cur_depth = #vres.context
   if old_depth~=nil and old_depth ~= cur_depth - 1 then
      error("vres_pop_context: unbalanced context stack at "..table.concat(vres.context, '.')..
	 ". should be "..ts(old_depth).." but is "..ts(cur_depth-1))
   end
   if #vres.context <= 0 then error("vres_pop_context with empty stack") end
   vres.context[#vres.context] = nil
end

--- True as long it is not nil.
function AnySpec.check(self, obj, vres)
   log("checking obj '", obj, "' against AnySpec")
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
   log("checking obj '", obj, "' against NumberSpec")
   local t = type(obj)
   if t ~= "number" then
      add_msg(vres, "err", "not a number but a " ..t)
      return false
   end
   if obj ~= obj then
      add_msg(vres, "err", "number value is NaN")
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
   log("checking obj '", obj, "' against StringSpec")

   local t = type(obj)

   if t ~= "string" then
      add_msg(vres, "err", "not a string but a " ..t)
      return false
   end

   if self.regexp then
      local res = string.match(obj, self.regexp)
      if not res then
	 add_msg(vres, "err", "regexp "..tostring(self.regexp).. " didn't match string "..tostring(obj))
	 return false
      end
   end
   return true
end

--- Validate a boolean spec.
function BoolSpec.check(self, obj, vres)
   log("checking obj '", obj, "' against BooleanSpec")
   local t = type(obj)
   if t == "boolean" then return true end
   add_msg(vres, "err", "not a boolean but a " ..t)
   return false
end

--- Validate a function spec.
function FunctionSpec.check(self, obj, vres)
   log("checking obj '", obj, "' against FunctionSpec")
   local t = type(obj)
   if t == "function" then return true end
   add_msg(vres, "err", "not a function but a " ..t)
   return false
end

--- Validate an enum spec.
function EnumSpec.check(self, obj, vres)
   log("checking obj '", obj, "' against EnumSpec")
   if utils.table_has(self, obj) then return true end
   add_msg(vres, "err", "invalid enum value: " .. tostring(obj) ..
	      " (valid: " .. table.concat(utils.imap(tostring, self), ", ")..")")
   return false
end

local valid_sealed = { both=true, dict=true, array=true }

function TableSpec:init()
   self.dict = self.dict or {}
   self.array = self.array or {}
   if self.sealed == true then self.sealed = 'both' end
   if self.sealed and not valid_sealed[self.sealed] then
      error("TableSpec "..ts(self.name)..": invalid sealed value '"..ts(self.sealed)..
	       "' (valid: 'both', 'dict', 'array', true, false)", 3)
   end
end

-- context string for a dict key
local function key2ctx(key)
   if type(key) == 'string' then return key end
   return "["..ts(key).."]"
end

-- scratch vres sharing the current context, nil if vres is nil
local function vres_scratch(vres)
   if not vres then return nil end
   local ctx = {}
   for i,v in ipairs(vres.context) do ctx[i]=v end
   return { msgs={}, err=0, warn=0, inf=0, context=ctx }
end

--- Append the messages of a list of scratch vres to vres.
function vres_merge(vres, list)
   if not vres or not list then return end
   for _,sv in ipairs(list) do
      for _,m in ipairs(sv.msgs) do vres.msgs[#vres.msgs+1] = m end
      vres.err, vres.warn, vres.inf = vres.err+sv.err, vres.warn+sv.warn, vres.inf+sv.inf
   end
end

--- Check entry against a spec or a list of alternative specs.
-- Each alternative is checked once, its messages go to a scratch vres.
-- An instance with a matching ObjectSpec is only checked against that.
-- @return true if one alternative matches
-- @return list of scratch vres to report with vres_merge: the matching
--         one on success, all on failure
function match_specs(entry, specs, vres)
   if specs == nil then specs = {}
   elseif is_spec(specs) then specs = { specs } end

   if type(specs) ~= 'table' then
      add_msg(vres, "err", "invalid spec "..ts(specs)..": not a Spec or a list of Specs")
      return false
   end

   for _,spec in ipairs(specs) do
      if not is_spec(spec) then
	 add_msg(vres, "err", "invalid spec "..ts(spec)..": not an umf.Spec instance")
	 return false
      end
   end

   if uoo_type(entry) == 'instance' then
      for _,spec in ipairs(specs) do
	 if instance_of(ObjectSpec, spec) and uoo_type(spec.type) == 'class' and
	    instance_of(spec.type, entry) then
	    log("match_specs: strongly matched type", spec.type.name)
	    specs = { spec }
	    break
	 end
      end
   end

   local failed = {}
   for _,spec in ipairs(specs) do
      local sv = vres_scratch(vres)
      if spec:check(entry, sv) then return true, { sv } end
      failed[#failed+1] = sv
   end
   return false, failed
end

--- Validate a table spec.
-- This is the most important function of uMF.
function TableSpec.check(self, obj, vres)
   local ret=true

   --- Check if entry is a legal array entry type.
   local function check_array_entry(entry,i)
      ind_inc()
      local depth = vres_push_context(vres, "["..ts(i).."]")
      log("check_array_entry: IN  #", i, " '", entry, "'")

      local sealed = self.sealed == 'both' or self.sealed=='array'
      local ok, res = match_specs(entry, self.array, vres)

      if ok then
	 log("check_array_entry: OUT #", i, " Ok!")
	 vres_merge(vres, res)
      elseif sealed then
	 log("check_array_entry: OUT #", i, " FAILED (illegal/invalid)")
	 add_msg(vres, "err", "illegal/invalid array entry #"..ts(i).." '".. ts(entry).."'. Error(s) follow:")
	 vres_merge(vres, res)
	 ret=false
      else
	 log("check_array_entry: OUT #", i, " FAILED (but unsealed)")
	 add_msg(vres, "inf", "unknown entry '"..tostring(entry) .."' in array part")
      end
      vres_pop_context(vres, depth)
      ind_dec()
   end

   --- Check if key=entry are valid for the TableSpec 'self'.
   local function check_dict_entry(entry, key)
      ind_inc()
      log("check_dict_entry: ", key, "='", entry, "'")
      local depth = vres_push_context(vres, key2ctx(key))
      local sealed = self.sealed == 'both' or self.sealed=='dict'
      -- a model key '__other' must not pick up the spec list
      local kspec = key ~= '__other' and self.dict[key] or nil

      if kspec then
	 -- known key, check it.
	 local ok, res = match_specs(entry, kspec, vres)
	 vres_merge(vres, res)
	 if not ok then ret=false end
	 log("key '", key, "' found, spec check result:", ok)
      elseif not self.dict.__other and sealed then
	 -- unknown key, no __other and sealed -> err!
	 add_msg(vres, "err", "illegal field '"..ts(key).."' in sealed dict (value: "..tostring(entry)..")")
	 ret=false
      else
	 local ok, res = match_specs(entry, self.dict.__other, vres)
	 if ok then
	    log("found matching spec in __other table")
	    vres_merge(vres, res)
	 elseif sealed then
	    -- unknown key AND __other does not legitimize: report all errors
	    vres_merge(vres, res)
	    log("checking __other for key ", key, " failed")
	    ret=false
	 else
	    add_msg(vres, "inf", "ignoring unknown field "..ts(key).." in unsealed dict")
	 end
      end
      vres_pop_context(vres, depth)
      ind_dec()
   end

   -- Check that all non optional dict entries are there
   local function check_dict_optionals(dct)
      -- build a list of non-optionals
      ind_inc()
      local nopts={}
      local optional=self.optional or {}
      for field,spec in pairs(self.dict) do
	 if field~='__other' and not utils.table_has(optional, field) then
	    nopts[#nopts+1] = field
	 end
      end

      -- check all non optionals are defined
      for _,nopt_field in ipairs(nopts) do
	 if dct[nopt_field]==nil then
	    add_msg(vres, "err", "non-optional field '"..nopt_field.."' missing")
	    ret=false
	 end
      end
      ind_dec()
   end

   ind_inc()
   log("checking table spec ", (self.name or "unnamed"))

   -- check we have a table
   local t = type(obj)
   if t ~= "table" then
      add_msg(vres, "err", "not a table but a " ..t)
      ind_dec()
      return false -- fatal.
   end

   local name = self.name or "unnamed"
   -- local depth = vres_push_context(vres, name)
   if self.precheck then
      local nerr = vres and vres.err
      ret = self.precheck(self, obj, vres)
      assert(type(ret)=='boolean', "precheck did not return boolean")
      if not ret and vres and vres.err == nerr then add_msg(vres, "err", "precheck failed") end
   end


   if ret then
      local arr,dct = table_split(obj)
      utils.foreach(function (e,i) check_array_entry(e,i) end, arr)
      utils.foreach(function (e,k) check_dict_entry(e, k) end, dct)
      check_dict_optionals(dct)
   end

   if self.postcheck and ret then
      local nerr = vres and vres.err
      ret = self.postcheck(self, obj, vres)
      assert(type(ret)=='boolean', "postcheck did not return boolean")
      if not ret and vres and vres.err == nerr then add_msg(vres, "err", "postcheck failed") end
   end


   log("checked table spec ", name, ", result: ", ret)
   -- vres_pop_context(vres, depth)
   ind_dec()
   return ret
end

--- Check a class spec.
function ClassSpec.check(self, c, vres)
   ind_inc()
   log("validating class spec of type ", self.name)
   local depth = vres_push_context(vres, ts(self.name or "unnamed"))

   -- check that they are classes
   if uoo_type(c) ~= 'class' or uoo_type(self.type) ~= 'class' or not subclass_of(c, self.type) then
      add_msg(vres, "err", "'"..tostring(c) .."' not of (sub-)class '"..tostring(self.type).."'")
      vres_pop_context(vres, depth)
      ind_dec()
      return false
   end
   vres_pop_context(vres, depth)
   local res=TableSpec.check(self, c, vres)
   ind_dec()
   return res
end

--- Check an object spec.
function ObjectSpec.check(self, obj, vres)
   local res=true
   ind_inc()
   log("validating object spec of type ", self.name)
   -- local depth = vres_push_context(vres, self.name)
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
   -- vres_pop_context(vres, depth)
   if res then res=TableSpec.check(self, obj, vres) end
   log("validated object spec of type ", self.name, ": ", res)
   ind_dec()
   return res
end

--- Resolve string links to objects
-- Format: "<class_name>#<object_name>", the whole string must match,
-- <class_name> may only contain alphanumerics, "_" and ".".
-- Targets are uoo instances of class <class_name> with name=<object_name>.
-- @param root object
-- @param verbose (optional)
-- @return false if link resolving failed, true otherwise
function resolve_links(root, verbose)
   local failures = 0

   -- collect all tables once (incl. root) before rewriting links, so
   -- resolved links are neither walked again nor loop on cycles.
   local nodes, seen, targets = {}, {}, {}
   local function collect(t)
      if seen[t] then return end
      seen[t] = true
      nodes[#nodes+1] = t
      local klass = uoo_class(t)
      if klass and t.name ~= nil then
	 local id = klass.."#"..ts(t.name)
	 targets[id] = targets[id] or {}
	 table.insert(targets[id], t)
      end
      for _,v in pairs(t) do
	 if type(v) == 'table' then collect(v) end
      end
   end
   collect(root)

   for _,node in ipairs(nodes) do
      for k,v in pairs(node) do
	 if type(v) == 'string' and string.match(v, "^[%w_%.]+#[^#%s]+$") then
	    local tgts = targets[v] or {}
	    if #tgts == 0 then
	       print(ac.red("resolve_links: failed to resolve " .. ac.bright(v)))
	       failures = failures + 1
	    elseif #tgts > 1 then
	       print(ac.red("resolve_links: multiple targets found for ".. ac.bright(v)))
	       failures = failures + 1
	    else
	       if verbose then print("resolve_links: successfully resolved target " .. v) end
	       node[k] = tgts[1]
	    end
	 end
      end
   end
   return (failures == 0)
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
   log("check: IN")
   if not is_spec(spec) then print("err: spec not an instance of umf.Spec"); return false end
   if verb then print("checking spec "..ts(spec.name or "unnamed")) end

   local vres = { msgs={}, err=0, warn=0, inf=0, context={} }
   if not spec:check(obj, vres) and vres.err == 0 then
      -- e.g. a precheck/postcheck returned false without a message
      add_msg(vres, "err", "spec "..ts(spec.name or "unnamed").." check failed")
   end
   log("check: OUT")
   if verb then print_vres(vres) end
   return vres.err, vres
end

return M
