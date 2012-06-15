-- Metacircular spec of spec, howdee!
return ObjectSpec{
   name='metaspec',
   type=umf.Spec,
   sealed='both',

   -- this is what the body of a spec might look like:
   dict={
      name=StringSpec{},
      sealed=EnumSpec{"both", "dict", "array", false},
      type=ClassSpec{ name='metaspec2', type=umf.Object, sealed=false, dict={} },

      -- it may have a dict field, described by the following
      -- TableSpec:
      dict=TableSpec{
	 sealed={}, -- true?
	 -- any field should be an instance of Spec
	 dict={ __other=TableSpec{umf.Spec{}} },
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
