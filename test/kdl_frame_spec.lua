--- Specification of a frame
return TableSpec{
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
