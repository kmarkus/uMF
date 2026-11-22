-- regression tests, run from test/: lua regress.lua
package.path = "../?.lua;" .. package.path
local umf = require("umf")
local utils = require("utils")

local pass, fail = 0, 0
local function T(name, f)
   local ok, res = pcall(f)
   if ok and res then pass = pass + 1; print("match   " .. name)
   else fail = fail + 1; print("DIFFER  " .. name .. (ok and "" or ": " .. tostring(res))) end
end

local function nerr(m, s) return (umf.check(m, s)) end
local function msgs(m, s)
   local _, v = umf.check(m, s)
   return utils.strip_ansi(table.concat(v.msgs, "\n"))
end

local A, B = umf.class("A"), umf.class("B")

T("enum with non-string values", function()
     return nerr(true, umf.EnumSpec{"a", false}) == 1 and nerr(false, umf.EnumSpec{"a", false}) == 0 end)
T("classspec non-class is an error", function()
     return nerr(5, umf.ClassSpec{name="c", type=umf.Object}) == 1 end)
T("classspec wrong class keeps context", function()
     return nerr({x=B}, umf.TableSpec{dict={x=umf.ClassSpec{name="c", type=A}}}) == 1 end)
T("unnamed objectspec", function() return nerr(A{}, umf.ObjectSpec{type=A}) == 0 end)
T("non-string dict keys", function()
     return nerr({[5]=1}, umf.TableSpec{}) == 0 and nerr({[true]=1}, umf.TableSpec{sealed='both'}) == 1 end)
T("model key __other", function()
     return nerr({__other=1}, umf.TableSpec{sealed='both', dict={__other={umf.NumberSpec{}}}}) == 0 end)
T("silent precheck failure counted", function()
     return nerr({}, umf.TableSpec{precheck=function() return false end}) == 1 end)
T("silent nested postcheck located", function()
     return msgs({x={}}, umf.TableSpec{dict={x=umf.TableSpec{postcheck=function() return false end}}})
	:match("%.x: postcheck failed") ~= nil end)
T("sealed=true means both", function() return nerr({foo=1}, umf.TableSpec{sealed=true}) == 1 end)
T("invalid sealed rejected", function() return not pcall(umf.TableSpec, {sealed='dicts'}) end)
T("NaN rejected", function() return nerr(0/0, umf.NumberSpec{}) == 1 end)
T("plain table as spec reported", function()
     return nerr({1}, umf.TableSpec{sealed='both', array={{}}}) >= 1 end)
T("spec class instead of instance reported", function()
     return nerr({x=1}, umf.TableSpec{dict={x=umf.NumberSpec}}) == 1 end)
T("invalid check() spec", function() return umf.check({}, {}) == false end)
T("no global leaks", function()
     umf.check({}, umf.TableSpec{dict={a=umf.NumberSpec{}}, optional={"a"}})
     umf.subclass_of(A, umf.Object)
     return rawget(umf, "nopts") == nil and rawget(umf, "sc_of") == nil and rawget(umf, "__resolve_links") == nil end)
T("info messages of matched alternative kept", function()
     return nerr({x={y=1}}, umf.TableSpec{dict={x={umf.NumberSpec{}, umf.TableSpec{}}}}) == 0 and
	msgs({x={y=1}}, umf.TableSpec{dict={x={umf.NumberSpec{}, umf.TableSpec{}}}}):match("ignoring unknown field y") end)

T("linear re-checking of nested entries", function()
     local calls = 0
     local Cnt = umf.class("Cnt", umf.Spec)
     function Cnt.check() calls = calls + 1; return false end
     local s = umf.TableSpec{sealed='both', dict={}}
     s.dict.__other = { s, Cnt{} }
     local m, cur = {}, nil
     cur = m
     for _=1,10 do cur.x = {}; cur = cur.x end
     cur.leaf = 1
     umf.check(m, s)
     return calls <= 11 end)

-- resolve_links prints failures, silence it
local function quiet(f, ...) local p = print; print = function() end; local r = f(...); print = p; return r end
local N = umf.class("N")
T("resolve_links cycle", function()
     local m = { a = N{name="a", ref="N#b"}, b = N{name="b", ref="N#a"} }
     return quiet(umf.resolve_links, m) and m.a.ref == m.b and m.b.ref == m.a end)
T("resolve_links root and link to root", function()
     local root = N{name="r", self="N#r"}
     root.kids = { N{name="a", up="N#r"} }
     return quiet(umf.resolve_links, root) and root.self == root and root.kids[1].up == root end)
T("resolve_links failure counted once", function()
     local fails = 0
     local p = print; print = function() fails = fails + 1 end
     local ok = umf.resolve_links({ a = N{name="a", ref="N#zz"}, b = N{name="b", ref="N#a"} })
     print = p
     return not ok and fails == 1 end)
T("resolve_links ignores non-links", function()
     local m = { url="http://x/#anchor", txt="see A#b here" }
     return quiet(umf.resolve_links, m) and m.url == "http://x/#anchor" end)

-- syntax extensions
local ext = umf.TableSpec{ sealed=true,
			   dict={ a=umf.optional(umf.NumberSpec{}),
				  b=umf.oneof{ umf.NumberSpec{}, umf.BoolSpec{} },
				  c={ umf.StringSpec{}, umf.NumberSpec{} } },
			   array=umf.NumberSpec{} }
T("ext: optional field may be missing", function() return nerr({b=1, c=1}, ext) == 0 end)
T("ext: optional field still checked", function() return nerr({a="x", b=1, c=1}, ext) == 1 end)
T("ext: oneof and list alternatives", function()
     return nerr({b=true, c="s"}, ext) == 0 and nerr({b="s", c={}}, ext) == 4 end)
T("ext: single array spec", function() return nerr({1, 2, b=1, c=1}, ext) == 0 and nerr({"z", b=1, c=1}, ext) == 2 end)
T("ext: single __other spec", function()
     return nerr({x=true}, umf.TableSpec{sealed=true, dict={__other=umf.BoolSpec{}}}) == 0 end)

T("ext: short constructors", function()
     local v = umf.table{ sealed=true, dict={ x=umf.number{min=0}, s=umf.string{},
					  e=umf.enum{"a"}, o=umf.object{type=A},
					  c=umf.classof{name="c", type=A}, f=umf.func{},
					  b=umf.bool{}, n=umf.any{} } }
     return nerr({x=1, s="s", e="a", o=A{}, c=A, f=print, b=true, n=0}, v) == 0 and
	nerr({x=-1, s=1, e="b", o=B{}, c=B, f=1, b=1}, v) == 8 and
	umf.number == umf.NumberSpec and table.concat({"ok"}) == "ok" end)

print(string.format("%s: %d match, %d DIFFER", _VERSION, pass, fail))
os.exit(fail == 0 and 0 or 1)
