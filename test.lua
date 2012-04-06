require "umf"
require "umf_check"

NumberSpec=umf_check.NumberSpec
StringSpec=umf_check.StringSpec
BoolSpec=umf_check.BoolSpec
EnumSpec=umf_check.EnumSpec
TableSpec=umf_check.TableSpec
ClassSpec=umf_check.ClassSpec
ObjectSpec=umf_check.ObjectSpec


-- Metacircular spec of spec, howdee!
metaspec = ObjectSpec{
   name='metaspec',
   type=umf_check.Spec,
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
	 dict={ __other=TableSpec{umf_check.Spec{}} },
	 array={umf_check.Spec{}},
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
	 array={umf_check.Spec{}},
      },
   },
   optional={"array", "dict", "optional", "type"},
}

--- Specification of a frame
frame_spec = TableSpec{
   name='kdl_frame',
   sealed='both',

   dict={
      M=TableSpec{
	 name='kdl_rotation',
	 sealed='both',
	 dict = {
	    X_x = NumberSpec{}, Y_x = NumberSpec{}, Z_x = NumberSpec{},
	    X_y = NumberSpec{}, Y_y = NumberSpec{}, Z_y = NumberSpec{},
	    X_z = NumberSpec{}, Y_z = NumberSpec{}, Z_z = NumberSpec{},
	 },
      },

      p=TableSpec{
	 name='kdl_vector',
	 sealed='both',
	 dict={ X = NumberSpec{}, Y = NumberSpec{}, Z = NumberSpec{} }
      }
   }
}

Robot=umf.class("Robot")
Foo=umf.class("Foo")

-- Robot spec
robot_spec = umf_check.ObjectSpec{
   name='itasc_robot',
   type=Robot,
   sealed='both',

   array={ NumberSpec{} },

   dict={
      name = StringSpec{},
      location = frame_spec,
      package = StringSpec{},
      type = StringSpec{},
      robot_type=EnumSpec{"industrial", "mobile", "aerial", "underwater"},
   },

   optional={'robo_type'},
}
robot_spec.array[#robot_spec.array+1]=BoolSpec{}

foo_spec=TableSpec{
   name='foo',
   sealed='array',

   dict={__other={StringSpec{}, NumberSpec{}}},
}

a_foo={
   a="string",
   b=33,
   c={},
   d=function() end,
}



-- Sample Model:
r1=Robot{
   name='youbot',
   package="youbot-master-rtt",
   type="iTaSC::youBot",
   location={M={X_x=1,Y_x=0,Z_x=0,X_y=0,Y_y=1,Z_y=0,X_z=0,Y_z=0,Z_z=1},p={X=0.0,Y=0.0,Z=0.0}},
   robot_type='mobile',
}

-- Sample Model:
r2=Robot{
   true,
   name={},
   33,
   "asdasd",
   package="package",

   -- type="iTaSC::youBot",
   location={M={X_x=1,Y_x='foo',Z_x=0,X_y={},Y_y=1,Z_y=0,X_z=0,Y_z=0,Z_z=1},p={X=100,Y=0.0,Z=0.0}},
   robot_type='insect',
}


print("\nchecking valid robot_spec:")
umf_check.check(r1, robot_spec)

print("\nchecking erronous robot_spec:")
umf_check.check(r2, robot_spec)

print("\nchecking foo against foo_spec:")
umf_check.check(a_foo, foo_spec)

print("\nchecking frame_spec against metaspec")
umf_check.check(frame_spec, metaspec)

print("\nchecking robot_spec against metaspec")
umf_check.check(robot_spec, metaspec)


print("\nchecking metaspec against metaspec (autsch)")
umf_check.check(metaspec, metaspec)
