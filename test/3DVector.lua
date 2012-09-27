require "umf"

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

Path3DSpec = umf.TableSpec{
   name = 'Path3D',
   sealed = 'both',
   array = { Vector3DSpec },
}


p1 = { x=1, y=0, z=0 }
p2 = { x=2, y=1, z=0 }
p3 = { x=0, y=1, z=2 }


umf.check(p1, Vector3DSpec, true)
umf.check(p2, Vector3DSpec, true)
umf.check(p3, Vector3DSpec, true)


-- Invalid:

path1 = { p1, p3, p2 }
umf.check(path1, Path3DSpec, true)

p4 = { x=0, z="foo" }
path2 = { p1, p3, p2, p4 }

umf.check(path2, Path3DSpec, true)

path2 = { p1, p3, p2, p4 }

