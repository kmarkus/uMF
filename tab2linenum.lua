require "lpeg"
require "luarocks.loader"
require "lxsh"
require "utils"
local pretty = require "pl.pretty"

function lex_luastr(data)
   local res = {}
   for kind, text, lnum, cnum in lxsh.lexers.lua.gmatch(data) do
      res[#res+1] = { kind=kind, text=text, lnum=lnum, cnum=cnum }
   end
   return res
end


function build_ident_tree(tl)
   local function is_named_ident(i)
      return tl[i].kind == 'identifier' and 
	 tl[i+1].kind == 'operator' and tl[i+1].text == '=' and
	 tl[i+2].kind == 'operator' and tl[i+2].text == '{' 
   end

   local function is_unnamed_ident(i)
      return tl[i].kind == 'identifier' and 
	 tl[i+1].kind == 'operator' and tl[i+1].text == '{'
   end

   local function is_closing_bracket(i)
      return  tl[i].kind=='operator' and tl[i].text=='}'
   end

   local function __build_ident_tree(xstart)
      local i = xstart
      local ident_tree = {}
      local stack = { ident_tree }

      while i <= #tl do
	 if is_named_ident(i) then
	    local newtab = { _estart=tl[i] }
	    local top_of_stack = stack[#stack]
	    top_of_stack[tl[i].text] = newtab  -- push to dict
	    stack[#stack+1] = newtab -- push
	    i=i+2
	 elseif is_unnamed_ident(i) then
	    local newtab = { _estart=tl[i] }
	    local top_of_stack = stack[#stack]
	    top_of_stack[#top_of_stack] = newtab -- push to array
	    stack[#stack+1] = newtab -- push
	    i=i+1
	 elseif is_closing_bracket(i) then
	    stack[#stack]._estop=tl[i]
	    stack[#stack]=nil -- pop
	 end
	 i=i+1
      end
      assert(#stack==1, "stack != 1")
      return ident_tree
   end

   local return_index = 0

   for i,v in ipairs(tl) do
      if v.kind=='keyword' and v.text=='return' then return_index=i end
   end

   if i==0 then error("invalid model, not missing 'return' keyword found") end
   return __build_ident_tree(return_index+1)
end

function filter_whitespace(token_list)
   return utils.filter(function(e) if e.kind~='whitespace' then return true end end, token_list)
end

local filename = arg[1] or error("missing file argument")
print("Processing ".. filename)
local f = assert(io.input(filename), "failed to open file "..filename)
data = f:read("*all")
print("data\n", data)

local tl = filter_whitespace(lex_luastr(data))

-- for k,v in ipairs(tl) do print(utils.tab2str(v)) end

ident_tree = build_ident_tree(tl)


pretty.dump(ident_tree)