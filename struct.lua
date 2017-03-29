local assert, pairs, tostring, type = assert, pairs, tostring, type
local ipairs = ipairs
local unpack = unpack
local setmetatable = setmetatable
local print = print
----------------------------------------------------------
local math = require 'math'
local table = require 'table'
local string = require 'string'
local io = require 'io'
----------------------------------------------------------
local c99 = require("ceg.c99")
local ceg = require("ceg")
local m = require("ejoy2dx.lpeg.c")
----------------------------------------------------------
local format = string.format
local P, V, R, S, C = m.P, m.V, m.R, m.S, m.C
----------------------------------------------------------

local SS = c99.SS
c99.typedefs.bool = "b"

local pack_conversion = {
	char="B",
	unsigned_char="B",
	signed_char="b",
	int="i",
	unsigned_int="I",
	signed_int="i",
	short="H",
	unsigned_short="H",
	signed_short="h",
	long="L",
	unsigned_long="L",
	signed_long="l",
	float="f",
	double="d",
	bool="b",
}

local function type_to_fmt(type_name)
	-- local name = type_name:match("[struct] ([%a%d_]+)")
	-- if name then
	-- 	return c99.typedefs[name]
	-- end
	
	local t = pack_conversion[type_name]
	if not t then
		t = c99.typedefs[type_name]
		if type(t) == "table" then
			if t.fmt then
				t = t.fmt
			elseif t[1] then
				return type_to_fmt(t[1])
			end
		end
	end
	if not t then
		t = string.gsub(type_name, " ", "_")
		t = pack_conversion[t]
	end
	return t
end

local function declarator_fmt(dec)
	local fmt
	if dec.is_pointer then
		fmt = "i"
	else
		fmt = type_to_fmt(dec.type)
	end

	if fmt and dec.array then
		fmt = string.rep(fmt, dec.array)
	end
	return fmt
end

local function struct_declarations(code, structs)
	-- print("code:", code)
	local rules = ceg.combine({
			[1] = V"followed",
			followed = V"anony_struct_or_union" + V"specifier_qualifier_list" * c99.SS * V"struct_declarator_list" * c99.SS * V";",
			specifier_qualifier_list = C(c99.specifier_qualifier_list),
			struct_declarator_list = C(c99.struct_declarator_list),
			anony_struct_or_union = C(c99.anony_struct_or_union),
			start_anony_struct_or_union = C(c99.start_anony_struct_or_union),
		}, 
		{
			comment = c99.comment,
		},
		c99.all_rules
	)
	
	local members = {}
	local last_type = nil
	-- local is_union = nil
	local last_identifier = nil
	local anony_stack = {}


	local captures = {
		identifier = function(v)
			last_identifier = v
			return v
		end,
		start_anony_struct_or_union = function(v)
			-- is_union = nil
			-- if string.find(v, "union") then
			-- 	is_union = true
			-- end
			table.insert(anony_stack, {})
			return v
		end,
		anony_struct_or_union = function(v)
			local is_union = nil
			if string.find(v, "union") then
				is_union = true
			end

			anony = table.remove(anony_stack)
			parent = anony_stack[#anony_stack] or members

			local data = {type="anony", name=last_identifier, is_union=is_union, body=anony}
			table.insert(parent, data)

			return v
		end,
		specifier_qualifier_list = function(v)
			last_type = v
			return v
		end,
		struct_declarator_list = function(v)
			name = v
			is_pointer = nil
			if string.sub(v, 1, 1) == "*" then
				is_pointer = true
				name = name:match("[* ]*([%a%d_]+)")
			end
			local a, array = name:match("([%a%d_]+)[ ]*[[][ ]*(%d+)[ ]*[]]")
			if a and array then
				name = a
				array = tonumber(array)
			end

			current = anony_stack[#anony_stack] or members
			assert(not current[name], name..":"..last_type)
			local data = {name=name, type=last_type, is_pointer=is_pointer, array=array}

			local struct_name = last_type:match("[struct] ([%a%d_]+)")
			if not is_pointer and struct_name then
				data.body = assert(structs[struct_name], struct_name)
				data.type = struct_name
			end

			data.fmt = declarator_fmt(data)

			table.insert(current, data)
			-- print("-->", #anony_stack, last_type, ":", name)
			last_type = nil
			return v
		end,

		followed = function(block)
			return block
		end,
	}

	local patt = ceg.scan(ceg.apply(rules, captures))
	local res = {patt:match(code)}

	return members
end

local function struct_pack(struct)
	local fmt = ""
	for k, v in ipairs(struct) do
		local t
		if v.type == "anony" then
			if v.is_union then
				local fmt
				local max_size
				for m, n in ipairs(v.body) do
					local tmp = struct_pack({n})
					local packsize = string.packsize(tmp)
					if not max_size or packsize > max_size then
						max_size = packsize
						fmt=tmp
					end
				end
				t = fmt
			else
				t = struct_pack(v.body)
			end
		elseif v.is_pointer then
			t = "i"
		elseif v.body then
			t = struct_pack(v.body)
		else
			t = type_to_fmt(v.type)
		end
		t = t or "?"

		if t and v.array then
			t = string.rep(t, v.array)
		end
		fmt = fmt..(t or "?")
	end
	assert(fmt~="")
	return fmt
end

local function struct_block(code)
	local rules = ceg.combine({
			[1] = V"followed",
			followed = V"struct_or_union_definition",
			struct_or_union_definition = C(c99.struct_or_union_definition)
		}, 
		{
			comment = c99.comment,
		},
		c99.all_rules
	)

	local structs = {}
	local captures = {
		struct_or_union_definition = function(v)
			return v
		end,

		followed = function(block)
			local name = block:match("[struct] ([%a%d_]+)")
			declarations = struct_declarations(block, structs)
			assert(not structs[name], name)
			structs[name] = declarations
			c99.typedefs[name] = struct_pack(declarations)
			return block
		end,
	}

	local patt = ceg.scan(ceg.apply(rules, captures))
	patt:match(code)

	-- structs.types = c99.typedefs
	return structs
end


local function types_to_fmt(types)
	local key = table.concat(types, "_")
	local fmt = pack_conversion[key]
	if fmt then
		return {types=types, fmt=fmt}
	else
		return types
	end
end

local function typedefs(code, rematch)
	local rules = ceg.combine({
			[1] = V"followed",
			followed = V"typedef_declarator",
			typedef_declarator = C(c99.typedef_declarator)
		}, 
		{
			comment = c99.comment,
		},
		c99.all_rules
	)
	
	last_type = {}
	local captures = {
		type_specifier = function(v)
			-- if rematch then
			-- 	print("....:", v)
			-- end
			table.insert(last_type, v)
			return v
		end,
		typeddef_identitifer = function(v)
			if #last_type == 0 then return end
			-- if rematch and c99.typedefs[v] then 
			-- 	print("...ignore:", v, last_type[1])
			-- 	last_type = {}
			-- 	return 
			-- end
			-- print("name:", v, table.concat(last_type, "+"))
			c99.typedefs[v] = types_to_fmt(last_type)
			last_type = {}
			return v
		end,

		followed = function(block)
			return block
		end,
	}

	c99.unknown_types = {}
	local patt = ceg.scan(ceg.apply(rules, captures))
	local res = {patt:match(code)}

	for k, v in ipairs(c99.unknown_types) do
		if c99.typedefs[v] then
			return typedefs(code, true)
		end
	end

	c99.unknown_types = nil
	return res
end

local function parse(code)
	typedefs(code)
	return struct_block(code)
end

local unpack_scheme_alias
local function unpack_union(scheme, bin)
	local tbl = {}

	local max_unread
	for k, v in ipairs(scheme) do
		local ret, idx = unpack_scheme_alias({v}, bin)
		table.insert(tbl, ret)
		max_unread = (not max_unread or idx > max_unread) and idx or max_unread
	end

	return tbl, max_unread
end

local function unpack_scheme(scheme, bin)
	local tbl = {}
	local idx = 1
	for k, v in ipairs(scheme) do
		if v.body then
			if v.is_union then
				local data, delta = unpack_union(v.body, string.sub(bin, idx))
				tbl[v.name] = data
				idx = idx + delta - 1
			else
				local data, delta = unpack_scheme(v.body, string.sub(bin, idx))
				tbl[v.name] = data
				idx = idx + delta - 1
			end
		else
			local data = table.pack(string.unpack(v.fmt, bin, idx))
			idx = data[#data]
			data[#data] = nil
			if #data == 1 then
				data=data[1]
			end
			tbl[v.name] = data
		end
	end
	return tbl, idx
end
unpack_scheme_alias = unpack_scheme

local function unpack(structs, struct_name, bin)
	local scheme = structs[struct_name]

	return unpack_scheme(scheme, bin)
end

local function pack(structs, struct_name, tbl)
	local layout = c99.typedefs[struct_name]
	assert(layout and type(layout) == "string", struct_name)
	local struct = structs[struct_name]
	local data = {}
	for k, v in ipairs(struct) do
		table.insert(data, tbl[v.name])
	end
	return string.pack(layout, table.unpack(data))
end

return {
	parse=parse,
	unpack=unpack,
	pack=pack,
}
