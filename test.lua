
local struct = require "struct"
local ltest = require "ltest"

local function print_tbl(tbl, ref)
	ref = ref or {}
	local dbg = {}
	for k, v in pairs(tbl) do
		if type(v) == "table" then
			if ref[v] then
				table.insert(dbg, tostring(k).."=".."ref_"..tostring(v))
			else
				ref[v] = true
				table.insert(dbg, tostring(k).."="..print_tbl(v, ref).."\n")
			end
		else
			table.insert(dbg, tostring(k).."="..tostring(v))
		end
	end
	return "{"..table.concat(dbg, ",").."}"
end

local function table_equals(o1, o2)
    if o1 == o2 then return true end
    local o1Type = type(o1)
    local o2Type = type(o2)
    if o1Type ~= o2Type then return false end
    if o1Type ~= 'table' then return false end

    local keySet = {}

    for key1, value1 in pairs(o1) do
        local value2 = o2[key1]
        if value2 == nil or table_equals(value1, value2) == false then
            return false
        end
        keySet[key1] = true
    end

    for key2 in pairs(o2) do
        if not keySet[key2] then return false end
    end
    return true
end

local function test()
    f=io.open("ltest.c", "r")
    local code = f:read("*a")
    f:close()


    local scheme = struct.parse(code)

    local json = require "json"
    local dump = json:encode_pretty(scheme)
    f=io.open("struct.json", "w")
    f:write(dump)
    f:close()

    ----------------------------------------------------------------------------------------------
    local bin = ltest.particle_config()
    local particle = struct.unpack(scheme, "particle_config", bin, {1})
    -- print(print_tbl(particle))

    local rlt = {startSpin=0.0,startSizeVar=19.0,startSize=18.0,emitterMode=0,endSpin=234.0,startColor={b=0.0,a=0.0,r=0.0,g=0.0}
    ,angle=16.0,startSpinVar=0.0,emitterMatrix=0,srcBlend=1,mode={A={tangentialAccelVar=6.0,radialAccelVar=8.0,speedVar=4.0,radialAccel=7.0,gravity={x=1.0,y=2.0}
    ,rotationIsDir=1,speed=3.0,tangentialAccel=5.0}
    }
    ,totalParticles=123,posVar={x=12.0,y=13.0}
    ,emissionRate=0.0,endSpinVar=0.0,endColorVar={b=0.0,a=0.0,r=0.0,g=0.0}
    ,endColor={b=0.0,a=0.0,r=0.0,g=0.0}
    ,lifeVar=15.0,startColorVar={b=0.0,a=0.0,r=0.0,g=0.0}
    ,dstBlend=769,endSizeVar=21.0,life=14.0,endSize=20.0,angleVar=17.0,positionType=1,sourcePosition={x=10.0,y=11.0}
    ,duration=9.0}

    assert(table_equals(particle.dump(), rlt), "particle_config failed")

    ----------------------------------------------------------------------------------------------

    bin = ltest.union_align()
    local union = struct.unpack(scheme, "union_align", bin, {[4] = 2, [7] = 2})
    -- print(print_tbl(union))

    union.set("k.i", 4, 2)

    rlt = {d=3,c={a=2}
    ,l={f={d=8,e=33}
    }
    ,h=4,g={e=33}
    ,k={i={5,--[[6]]4,7}
    }
    ,m={e={d={b=9}}}
    ,n={a=33}
    ,o=10
    ,head=33}
    assert(table_equals(union.dump(), rlt), "union_align failed")
    ----------------------------------------------------------------------------------------------


    bin = ltest.struct_align()
    local sa = struct.unpack(scheme, "struct_align", bin)
    -- print(print_tbl(struct.dump()))

    sa.set("g.a", 3)

    bin = sa.pack()
    sa = struct.unpack(scheme, "struct_align", bin)

    rlt = {h=63,g={b=33,a=--[[1]]3}
    ,f=63,e={b=33,a=0}
    ,d=4294967295,c={b=33,a=0}
    ,i={b=33,a=0}
    }

    assert(table_equals(sa.dump(), rlt), "struct_align failed")

    print("test succeed")
end

-- local code = [[
-- struct a {
--     struct inner {
--         int b;
--     } c;
-- };
-- ]]

-- local scheme = struct.parse(code)
-- print(print_tbl(scheme))

test()