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
      M= { val=TableSpec:new{
	      name='kdl_rotation',
	      sealed='both',
	      dict = { 
		 X_x = { val=NumberSpec:new{}, optional=false }, 
		 Y_x = { val=NumberSpec:new{}, optional=false },
		 Z_x = { val=NumberSpec:new{}, optional=false },
		 X_y = { val=NumberSpec:new{}, optional=false },
		 Y_y = { val=NumberSpec:new{}, optional=false },
		 Z_y = { val=NumberSpec:new{}, optional=false },
		 X_z = { val=NumberSpec:new{}, optional=false},
		 Y_z = { val=NumberSpec:new{}, optional=false},
		 Z_z = { val=NumberSpec:new{}, optional=false} 
	      },
	   },
	},

      p= { val=TableSpec:new{
	      name='kdl_vector',
	      sealed='both',
	      dict={ 
		 X = { val=NumberSpec:new{} },
		 Y = { val=NumberSpec:new{} },
		 Z = { val=NumberSpec:new{} },
	      },
	   },
	}
   }
}

Robot=umf.class("Robot")
Foo=umf.class("Foo")

-- Robot spec
robot_spec = umf_check.ClassSpec:new{
   name='itasc_robot',
   type=Robot,
   sealed='both',
   
   dict={
      name = { val=StringSpec:new{} },
      location = { val=frame_spec },
      package = { val=StringSpec:new{} },
      type = { val=StringSpec:new{} },
   },
}


-- Sample Model:
r1=Robot:new{
   name='youbot',
   package="youbot-master-rtt",
   type="iTaSC::youBot",
   location={M={X_x=1,Y_x=0,Z_x=0,X_y=0,Y_y=1,Z_y=0,X_z=0,Y_z=0,Z_z=1},p={X=0.0,Y=0.0,Z=0.0}},
}

umf_check.check(r1, robot_spec)
   

   
   
   
