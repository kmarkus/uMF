
Robot=umf.class("Robot")

frame_spec=dofile("kdl_frame_spec.lua")

-- Robot spec
robot_spec = umf.ObjectSpec{
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

   optional={'robot_type'},
}
robot_spec.array[#robot_spec.array+1]=BoolSpec{}

return robot_spec