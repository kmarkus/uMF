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
when defining a constraint model.

Future work
-----------

- json-schema import/export
- ECore import/export


Acknowledgement
---------------

The research leading to these results has received funding from the
European Community's Seventh Framework Programme (FP7/2007-2013) under
grant agreement no. FP7-ICT-231940-BRICS (Best Practice in Robotics)










