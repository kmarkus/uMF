
-- micro modelling framework
module("umf")

function make_class(name, super)
   local c = { name=name, super=super }
   setmetatable(c, { __tostring = function() return "class " .. name end,
		     __index = 
		   
end

Object = make_class("Object", nil)


--- misc
function is_a(obj, type)
end


--- validate
function validate(obj, spec)
end

function validate_spec