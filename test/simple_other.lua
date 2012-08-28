
require "umf"

ts = umf.TableSpec {
   name="other_field_check",
   sealed='both',
   dict = { __other={ umf.BoolSpec{} } },
}

m1 = { foo=false, bar=false, ick=true }
m2 = { foo="strasdas", bar=22, ick=true }

umf.check(m1, ts, true)
umf.check(m2, ts, true)