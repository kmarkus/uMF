
-- A foo must consist only of dictionary entries of type String or
-- Number.
return TableSpec{
   name='foo',
   sealed='array',
   dict={__other={StringSpec{}, NumberSpec{}}},
}
