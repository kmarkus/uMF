uMF: micro modelling framework (uMF)
====================================

uMF is a minimal, yet powerful modeling framework (DSL workbench) for
the Lua language. It permits defining and validating models by means
of placing structural, composable contraints on Lua tables.

**Features**

- supports defining constraints on all basic Lua types, tables and custom objects
- extensible, customizable, constraint language
- model checking produces high quality error messages


Simple Example
--------------

A constraint is model using a umf `Spec`. Multiple predefined specs
are available.

To model a 3D vector of the form ``{ x=1, y=0, z=0 }`` can be achieved
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
   optional={},
}
```

Further documentation will follow shortly. For now check out the
examples in the `test/` subdirectory.


Defining Model Elements
-----------------------


Defining Constraints
--------------------


Resolving references
--------------------

NOT implemented.

resolve `{type, <target>}` to point to the object whos field `{name}`
matches the value of `<target>`

matching rules:
- absolute if starts with a `/`
- relative without slash
- relative parent references `../`

Pitfalls
--------

It's a common pitfall to assign a spec class instead of an instance
when defining a constraint model.

Future work
-----------

- ECore import/export
- json-schema export

Acknowledgement
---------------

The research leading to these results has received funding from the
European Community's Seventh Framework Programme (FP7/2007-2013) under
grant agreement no. FP7-ICT-231940-BRICS (Best Practice in Robotics)










