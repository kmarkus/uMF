require "umf"
require "umf_check"

NumberSpec=umf_check.NumberSpec
StringSpec=umf_check.StringSpec
BoolSpec=umf_check.BoolSpec
EnumSpec=umf_check.EnumSpec
TableSpec=umf_check.TableSpec
ClassSpec=umf_check.ClassSpec

--- Specification of a frame
frame_spec = TableSpec:new{
   name='kdl_frame',
   sealed='both',
   
   dict={
      M=TableSpec:new{
	 name='kdl_rotation',
	 sealed='both',
	 dict = { 
	    X_x = NumberSpec:new{}, Y_x = NumberSpec:new{}, Z_x = NumberSpec:new{},
	    X_y = NumberSpec:new{}, Y_y = NumberSpec:new{}, Z_y = NumberSpec:new{},
	    X_z = NumberSpec:new{}, Y_z = NumberSpec:new{}, Z_z = NumberSpec:new{},
	 },
      },

      p=TableSpec:new{
	 name='kdl_vector',
	 sealed='both',
	 dict={ X = NumberSpec:new{}, Y = NumberSpec:new{}, Z = NumberSpec:new{} }
      }
   }
}

Robot=umf.class("Robot")
Foo=umf.class("Foo")

-- Robot spec
robot_spec = umf_check.ClassSpec{
   name='itasc_robot',
   type=Robot,
   sealed='both',

   array={ NumberSpec{} },

   dict={
      name = StringSpec:new{},
      location = frame_spec,
      package = StringSpec:new{},
      type = StringSpec:new{},
      robot_type=EnumSpec:new{"industrial", "mobile", "aerial", "underwater"},
   },

   optional={'robo_type'},
}
robot_spec.array[#robot_spec.array+1]=BoolSpec{}

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


umf_check.check(r1, robot_spec)
umf_check.check(r2, robot_spec)
   

   
   
   
