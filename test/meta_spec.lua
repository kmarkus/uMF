-- Metacircular spec of spec, howdee!
return ObjectSpec{
   name='metaspec',
   type=umf.Spec,
   sealed='both',

   -- this is what the body of a spec might look like:
   dict={
      name=StringSpec{},
      sealed=EnumSpec{"both", "dict", "array", true, false},
      type=ClassSpec{ name='metaspec-type', type=umf.Object, sealed=false, dict={} },

      -- it may have a dict field, described by the following
      -- TableSpec:
      dict=TableSpec{
	 sealed=false,
	 -- any field should be a Spec or a list of alternative Specs
	 dict={ __other={ umf.Spec{}, TableSpec{ array={umf.Spec{}} } } },
	 array={umf.Spec{}},
      },
      optional=TableSpec{
	 sealed='both',
	 array={StringSpec{}},
	 dict={},
      },

      -- type=ClassSpec{name="Object", type=umf.Object},

      array=TableSpec{
	 sealed='both',
	 dict={},
	 array={umf.Spec{}},
      },
   },
   optional={"array", "dict", "optional", "type"},
}
