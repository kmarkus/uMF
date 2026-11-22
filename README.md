uMF: micro modelling framework (uMF)
====================================

uMF is a minimal, yet powerful modeling framework (aka DSL workbench)
based on the Lua language. It permits defining and validating models
by means of placing structural, composable contraints on Lua types.

**Features**

- DSL defininition by defining constraints on Lua data structures
- lightweight OO support to define typed tables
- predefined constraints are extensible and configurable
- easy definition of new constraints
- constraints can be composed
- localized error reporting during model checking

Simple Example
--------------

A constraint is model using a umf `Spec`. Multiple predefined specs
are available.

Defining a 3D vector of the form `{ x=1, y=0, z=0 }` can be achieved
with the following Spec:

```Lua
Vector3DSpec = umf.TableSpec{
   name = 'Vector3D',
   sealed = 'both',
   dict = {
	  x = umf.NumberSpec{},
	  y = umf.NumberSpec{},
	  z = umf.NumberSpec{},
   },
}
```

uMF runs on Lua 5.1 to 5.5 and LuaJIT.

**Shortcuts**

These forms are equivalent to the long ones and can be mixed with them:

| Long form                                   | Shortcut                                  |
|---------------------------------------------|-------------------------------------------|
| `x = NumberSpec{}` plus `optional={'x'}`    | `x = umf.optional(NumberSpec{})`          |
| `array = { NumberSpec{} }`                  | `array = NumberSpec{}`                    |
| `__other = { StringSpec{} }`                | `__other = StringSpec{}`                  |
| list of alternatives `{ A, B }`             | `umf.oneof{ A, B }`, also as a dict value |
| `sealed = 'both'`                           | `sealed = true`                           |

A dict value can be a list of alternatives, e.g. `x = { NumberSpec{},
StringSpec{} }`. `umf.oneof{}` does the same and also works where a single spec
is expected, e.g. nested inside another list.

Debug output of the checker is enabled with `umf.log_enabled = true`.

Defining Model Elements
-----------------------


Defining Constraints
--------------------


Basic transformations
---------------------

These functions provide additional model transformations that may be
applied after successfull validation.

**NOT implemented!**


**Resolving references**

```Lua
resolve(src-field, tgt-field, model, [src-filter-fun], [tgt-filter-fun])
```

*Behavior*:

For each table (or object) in the model, the function will search for
tables (or objects) whos value of `tgt-field` matches that of
`src-field`. If such a match is found, the value of `src-field` of
this object is modified to directly reference the target object.

If the optional `src-filter-fun` and/or `tgt-filter-fun` predicate
functions are provided, the resolving will only take place if these
functions when applied to the respective table (or objects) return
`true`.

matching rules:
- absolute if starts with a `/`
- relative without slash
- relative parent references `../` (only if

**Creating parent links**

```Lua
create_parent_ref()
```

**Generic traversal**


Code generation
---------------


Pitfalls
--------

It's a common pitfall to assign a spec class instead of an instance
when defining a constraint model (`NumberSpec` instead of `NumberSpec{}`).
The check then reports `invalid spec ...: not an umf.Spec instance`.

`sealed` only accepts `'both'`, `'dict'`, `'array'`, `true` and `false`;
other values raise an error when the spec is created.

Future work
-----------

- json-schema import/export
- ECore import/export

Acknowledgement
---------------

The research leading to these results has received funding from the
European Community's Seventh Framework Programme (FP7/2007-2013) under
grant agreement no. FP7-ICT-231940-BRICS (Best Practice in Robotics)
