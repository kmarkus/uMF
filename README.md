uMF: micro modelling framework (uMF)
====================================

uMF is a small modelling framework (aka DSL workbench) based on Lua. Models are
plain Lua data structures, constraints on them are defined by composing specs.
Checking a model reports all errors with their location, not just the first.

**Features**

- DSL definition by defining constraints on Lua data structures
- lightweight OO support to define typed tables
- predefined constraints are extensible and configurable
- easy definition of new constraints
- constraints can be composed and can be recursive
- all errors are reported, each with the path to the offending value
- specs are plain data and can themselves be checked against a metaspec

uMF runs on Lua 5.1 to 5.5 and LuaJIT.

Installation
------------

Put `umf.lua` and `utils.lua` on the `LUA_PATH`. The only dependency is
`ansicolors` (`luarocks install ansicolors`).

Simple Example
--------------

A constraint is modelled using a uMF `Spec`. A 3D vector of the form `{ x=1,
y=0, z=0 }` and a path made of vectors are described as:

```Lua
local umf = require("umf")

Vector3DSpec = umf.TableSpec{
   name = 'Vector3D',
   sealed = 'both',
   dict = {
      x = umf.NumberSpec{},
      y = umf.NumberSpec{},
      z = umf.NumberSpec{},
   },
}

Path3DSpec = umf.TableSpec{
   name = 'Path3D',
   sealed = 'both',
   array = { Vector3DSpec },
}

umf.check({ x=1, y=0, z=0 }, Vector3DSpec, true)
umf.check({ {x=1,y=0,z=0}, {x=0,z="foo"} }, Path3DSpec, true)
```

Output:

```
checking spec Vector3D
0 errors, 0 warnings, 0 informational messages.
checking spec Path3D
err @ [2]: illegal/invalid array entry #2 'table: 0x5600669ef500'. Error(s) follow:
err @ [2].z: not a number but a string
err @ [2]: non-optional field 'y' missing
3 errors, 0 warnings, 0 informational messages.
```

The same specs written with the shortcuts (see below):

```Lua
Vector3DSpec = umf.table{ name='Vector3D', sealed=true,
                          dict={ x=umf.number{}, y=umf.number{}, z=umf.number{} } }
Path3DSpec = umf.table{ name='Path3D', sealed=true, array=Vector3DSpec }
```

Checking Models
---------------

```Lua
local nerr, vres = umf.check(model, spec, verbose)
```

- `nerr`: number of errors, or `false` if `spec` is not a Spec instance
- `vres`: validation result: `msgs` (list of message strings), `err`, `warn`,
  `inf` (message counts per level)
- `verbose`: if true, print the spec name and all messages

`umf.print_vres(vres)` prints the messages and the summary line.

Each message has a level and the path to the value it is about, e.g. `err @
.location.M.Y_x: not a number but a string`. Array entries appear as `[2]`,
non-string keys as `[key]`. Levels:

- `err`: the model violates the spec
- `inf`: accepted, but worth knowing, e.g. an unknown field in an unsealed table
- `warn`: available to custom specs

Messages are colored with ANSI escape codes.

Specs
-----

| Spec           | Short form      | Accepts                                    | Options               |
|----------------|-----------------|--------------------------------------------|-----------------------|
| `AnySpec`      | `umf.any`       | any value but `nil`                        |                       |
| `NumberSpec`   | `umf.number`    | numbers, not NaN                           | `min`, `max`          |
| `StringSpec`   | `umf.string`    | strings                                    | `regexp`              |
| `BoolSpec`     | `umf.bool`      | booleans                                   |                       |
| `FunctionSpec` | `umf.func`      | functions                                  |                       |
| `EnumSpec`     | `umf.enum`      | one of the listed values                   | the values, as list   |
| `TableSpec`    | `umf.table`     | tables                                     | see below             |
| `ObjectSpec`   | `umf.object`    | instances of `type` or a subclass          | `type`, as TableSpec  |
| `ClassSpec`    | `umf.classof`   | the class `type` or a subclass             | `type`, as TableSpec  |

- `regexp` is a Lua pattern and is not anchored: use `^...$` to match the whole
  string.
- `EnumSpec` values may be of any type, e.g. `umf.enum{ "both", true, false }`.

**TableSpec options**

| Option      | Meaning                                                                |
|-------------|------------------------------------------------------------------------|
| `name`      | name used in messages                                                  |
| `dict`      | `key = spec` for the dictionary part                                   |
| `array`     | spec (or list of alternative specs) for each entry of the array part   |
| `optional`  | list of dict keys that may be missing                                  |
| `sealed`    | reject entries not covered by `dict` or `array`, see below             |
| `precheck`  | `function(self, obj, vres)` run before the entries are checked         |
| `postcheck` | `function(self, obj, vres)` run after the entries are checked          |

All keys in `dict` are required unless listed in `optional` or wrapped in
`umf.optional()`. A missing key is a key whose value is `nil`; `false` is a
value.

`dict.__other` is a spec (or list of specs) for keys not listed in `dict`.
Rules for such a key:

| `__other` matches | `sealed` covers the dict | Result                       |
|-------------------|--------------------------|------------------------------|
| yes               | any                      | accepted                     |
| no / no `__other` | yes                      | `err`                        |
| no / no `__other` | no                       | `inf`, accepted              |

`sealed` takes `'dict'`, `'array'` or `'both'` (`true` is `'both'`). `false` or
no `sealed` means unsealed. Array entries that match no spec are an error in a
sealed array and an `inf` otherwise. Any other value of `sealed` raises an error
when the spec is created.

**Alternatives**

Where a spec is expected in `array`, `__other` or as a `dict` value, a list of
specs is accepted too. The value is valid if one of them matches. If none
matches, the errors of all alternatives are reported. If the value is a uMF
object and one alternative is an `ObjectSpec` of its class, only that one is
checked, so the errors are about the right type.

`umf.oneof{ A, B }` is the same as the list `{ A, B }`, but is itself a spec, so
it also works nested inside another list.

**Shortcuts**

These forms are equivalent to the long ones and can be mixed with them:

| Long form                                   | Shortcut                                  |
|---------------------------------------------|-------------------------------------------|
| `x = NumberSpec{}` plus `optional={'x'}`    | `x = umf.optional(NumberSpec{})`          |
| `array = { NumberSpec{} }`                  | `array = NumberSpec{}`                    |
| `__other = { StringSpec{} }`                | `__other = StringSpec{}`                  |
| list of alternatives `{ A, B }`             | `umf.oneof{ A, B }`, also as a dict value |
| `sealed = 'both'`                           | `sealed = true`                           |
| `umf.NumberSpec{}`                          | `umf.number{}`                            |

The short constructors are the spec classes themselves: `umf.number{min=0}` is
`umf.NumberSpec{min=0}`. `ClassSpec` is `umf.classof`, since `umf.class` creates
classes (see below).

**Recursive specs**

Specs are tables, so a spec can refer to itself. A state that contains
transitions and further states (from `test/rfsm_spec.lua`, which also defines
`trans_spec`):

```Lua
state_spec = umf.TableSpec{
   name = 'rfsm_state',
   sealed = 'both',
   dict = {
      entry = umf.FunctionSpec{},
      exit = umf.FunctionSpec{},
      __other = { trans_spec },
   },
   optional = { 'entry', 'exit' },
   array = { trans_spec },
}
table.insert(state_spec.dict.__other, state_spec)
```

Defining Model Elements
-----------------------

uMF has a minimal OO system to give tables a type. That allows constraints like
"an array of robots" and better error messages.

```Lua
Robot = umf.class("Robot")            -- umf.class(name, [superclass])
Mobile = umf.class("Mobile", Robot)

function Robot:init() self.payload = self.payload or 0 end   -- constructor hook
function Robot:describe() return self.name .. " " .. self.payload end

r = Mobile{ name="youbot" }           -- the table becomes the object
print(r:describe())                   -- youbot 0
```

| Function                             | Returns                                              |
|--------------------------------------|------------------------------------------------------|
| `umf.instance_of(Class, obj)`        | true if `obj` is an instance of `Class` or subclass  |
| `umf.subclass_of(Sub, Class)`        | true if `Sub` is `Class` or derives from it          |
| `umf.uoo_type(x)`                    | `'class'`, `'instance'` or `false`                   |
| `umf.uoo_class(obj)`                 | class name of an instance, or `false`                |
| `Class:classname()`, `Class:super()` | name and superclass                                  |

`instance_of` and `subclass_of` raise an error if the arguments are not a class
and an instance or class.

An `ObjectSpec` checks the type and then the fields like a `TableSpec`:

```Lua
robot_spec = umf.object{
   name = 'robot', type = Robot, sealed = true,
   dict = { name = umf.string{},
            kind = umf.enum{ "mobile", "industrial" },
            payload = umf.optional(umf.number{ min=0 }) },
}

umf.check(Robot{ name="r2", kind="insect", payload=-1, color="red" }, robot_spec, true)
```

```
checking spec robot
err @ .kind: invalid enum value: insect (valid: mobile, industrial)
err @ .payload: number value=-1 beneath min=0
err @ .color: illegal field 'color' in sealed dict (value: red)
3 errors, 0 warnings, 0 informational messages.
```

Defining Constraints
--------------------

**Pre- and postchecks**

For constraints across fields use `precheck` or `postcheck` on a `TableSpec`.
Both must return a boolean. Report the reason with `umf.add_msg(vres, level,
msg)`; a check that returns `false` without a message gets a generic `precheck
failed` / `postcheck failed` error. `vres` is `nil` when uMF only tests whether
a value matches, `add_msg` handles that.

```Lua
range_spec = umf.table{
   name = 'range',
   dict = { lo = umf.number{}, hi = umf.number{} },
   postcheck = function(self, obj, vres)
      if obj.lo > obj.hi then
         umf.add_msg(vres, "err", "lo > hi")
         return false
      end
      return true
   end,
}
```

The `postcheck` only runs if the entries were valid. A failed `precheck` skips
the entry checks.

**New spec types**

Subclass a spec and define `check(self, obj, vres)`, returning a boolean:

```Lua
EvenSpec = umf.class("EvenSpec", umf.NumberSpec)

function EvenSpec.check(self, obj, vres)
   if not umf.NumberSpec.check(self, obj, vres) then return false end
   if obj % 2 ~= 0 then
      umf.add_msg(vres, "err", tostring(obj) .. " is odd")
      return false
   end
   return true
end

umf.check({ n=3 }, umf.table{ dict={ n=EvenSpec{} } }, true)
-- err @ .n: 3 is odd
```

To add a path element to the messages, wrap them in `local d =
umf.vres_push_context(vres, "name")` and `umf.vres_pop_context(vres, d)`. Pop on
every return path, the pop checks that the stack is balanced. See
`test/rospack_spec.lua` for a spec that checks a string against the ROS
package list.

**Checking specs**

Specs are uMF objects, so they can be checked too. `test/meta_spec.lua` is a
spec for specs:

```
umfcheck robot_spec.lua meta_spec.lua
```

Model Transformations
---------------------

**Resolving references**

```Lua
ok = umf.resolve_links(model, [verbose])
```

Replaces every string `"<Class>#<name>"` in the model with the uMF object of
class `<Class>` whose `name` field is `<name>`. The whole string must match and
`<Class>` may only contain letters, digits, `_` and `.`. Links may point
anywhere in the model, including the root and objects that link back. Returns
`false` and prints an error for each link with no target or more than one.

```Lua
Node = umf.class("Node")
m = { Node{ name="a", next="Node#b" }, Node{ name="b" } }
umf.resolve_links(m)
assert(m[1].next == m[2])
```

The umfcheck Tool
-----------------

```
umfcheck [-q] <modelfile> <specfile>
```

Both files are Lua chunks returning the model and the spec. Spec files see the
globals `umf`, `AnySpec`, `NumberSpec`, `StringSpec`, `BoolSpec`,
`FunctionSpec`, `EnumSpec`, `TableSpec`, `ClassSpec` and `ObjectSpec`. `-q`
suppresses the output. Exit codes:

- `0`: model is valid
- `1`: usage error, file missing or returned no value
- `2`: validation errors, or the spec file returned no Spec

Debugging
---------

`umf.log_enabled = true` prints a trace of the checker.

Tests
-----

```
sh test/runtest.sh [lua interpreters...]
```

Runs `test/regress.lua` and the example models with all installed interpreters
from Lua 5.1 to 5.5 and LuaJIT, one `match` / `DIFFER` line per test.

Pitfalls
--------

- Assigning a spec class instead of an instance (`NumberSpec` instead of
  `NumberSpec{}`). The check then reports `invalid spec ...: not an umf.Spec
  instance`.
- `StringSpec` `regexp` is not anchored, see above.
- An `ObjectSpec` only accepts uMF instances: a plain table with the right
  fields fails with `given object is not an umf class instance`.
- `Class{...}` turns the passed table into the object, it is not copied.
- `umf.string` and `umf.table` are spec constructors, not the Lua libraries.

Future work
-----------

- json-schema import/export
- ECore import/export
- code generation from specs
- generic reference resolution: `resolve(src_field, tgt_field, model,
  [src_filter], [tgt_filter])` replaces the value of `src_field` with the table
  whose `tgt_field` has the same value, with absolute (`/a/b`), relative and
  parent (`../`) references
- creating parent links (`create_parent_ref()`)
- generic model traversal

License
-------

BSD-3-Clause, see `LICENSE`.

Acknowledgement
---------------

The research leading to these results has received funding from the
European Community's Seventh Framework Programme (FP7/2007-2013) under
grant agreement no. FP7-ICT-231940-BRICS (Best Practice in Robotics)
