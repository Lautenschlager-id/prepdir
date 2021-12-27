------------------------------------------- Optimization -------------------------------------------
local assert       = assert

local setmetatable = setmetatable

local str_format   = string.format
local str_gmatch   = string.gmatch
local str_match    = string.match
local str_sub      = string.sub
----------------------------------------------------------------------------------------------------

local tokens = require("../tokens")
local prefix = tokens.prefix
local tokenMatchers = tokens.tokenMatchers

local utils = require("../utils")
local evaluateCondition = utils.evaluateCondition
local normalizeCondition = utils.normalizeCondition
local sliceString = utils.sliceString

local envMeta = {
	__index = _G.PREPDIR_SETTINGS
}

local Conditional = require("./conditional")

local Processor = { }
Processor.__index = Processor

--[[ Tokens ]]--
Processor.DEFINE = function(self)
	local env = self.envTbl

	-- Collect first
	local boundaries, totalBoundaries = { }, 0
	for iniPos, _, varName, varValue, endPos in str_gmatch(self.tmpSource, tokenMatchers.DEFINE) do
		env[varName] = normalizeCondition(varValue)

		totalBoundaries = totalBoundaries + 1
		boundaries[totalBoundaries] = iniPos

		totalBoundaries = totalBoundaries + 1
		boundaries[totalBoundaries] = endPos
	end

	-- Then transform
	for var, val in next, env do
		env[var] = evaluateCondition(val, env)
	end

	self.tmpSource = sliceString(self.tmpSource, boundaries)
	return self
end

Processor.IF = function(self)
	local iniPos, tabLevel, condition, endPos =
		str_match(self.tmpSource, prefix .. tokenMatchers.IF)
	if not iniPos then return end

	self.conditional = Conditional.new(iniPos, endPos, condition, tabLevel)

	return self.conditional
end

Processor.ELIF = function(self, cond)
	local iniPos, condition, endPos = str_match(self.tmpSource,
		cond.formattedPrefix .. tokenMatchers.ELIF, cond.endPos)
	assert(iniPos)

	cond:push(iniPos, endPos, condition)
end

Processor.ELSE = function(self, cond)
	local iniPos, endPos = str_match(self.tmpSource,
		cond.formattedPrefix .. tokenMatchers.ELSE, cond.endPos)
	assert(iniPos)

	cond:push(iniPos, endPos, "true")
end

Processor.ENDIF = function(self, cond)
	local iniPos, endPos = str_match(self.tmpSource,
		cond.formattedPrefix .. tokenMatchers.ENDIF, cond.endPos)
	assert(iniPos)

	cond.endif = {
		iniPos = iniPos,
		endPos = endPos
	}
	cond.endPos = endPos
end

Processor._NEXT_TOKEN = function(self, cond)
	local iniPos, token =
		str_match(self.tmpSource, cond.formattedPrefix .. tokenMatchers._NEXT, cond.endPos)
	if not iniPos then return end

	return token
end

--[[ Class ]]--
Processor.new = function(src)
	return setmetatable({
		rawSource = src,
		tmpSource = nil,

		conditional = nil,

		envTbl = setmetatable({ }, envMeta),
		lastDefinePos = nil
	}, Processor)
end

Processor.parse = function(self)
	local cond = self:IF()
	if not cond then return end

	local nextToken
	repeat
		nextToken = self:_NEXT_TOKEN(cond)

		-- Check all alternative conditions
		if nextToken == "ELIF" then
			self:ELIF(cond)
		else
			break
		end
	until false

	-- Check for else
	if nextToken == "ELSE" then
		self:ELSE(cond)
		nextToken = nil
	end

	-- End conditional
	nextToken = nextToken or self:_NEXT_TOKEN(cond)
	assert(nextToken == "ENDIF", str_format("[PREPDIR] @[%d:] Mandatory token ENDIF to \z
		close token IF @[%d:]", cond.endPos, cond[1].iniPos))
	self:ENDIF(cond)

	-- Normalize conditions
	for c = 1, cond.totalChunks do
		if cond[c].condition then
			cond[c].condition = normalizeCondition(cond[c].condition)
		end
	end

	return self
end

Processor.evaluate = function(self)
	local boundaries, totalBoundaries = { }, 0
	local nextCond

	local cond = self.conditional
	local env = self.envTbl

	totalBoundaries = totalBoundaries + 1
	boundaries[totalBoundaries] = cond[1].iniPos

	for c = 1, cond.totalChunks do
		nextCond = cond[c]

		if evaluateCondition(nextCond.condition, env) then
			totalBoundaries = totalBoundaries + 1
			boundaries[totalBoundaries] = nextCond.endPos

			totalBoundaries = totalBoundaries + 1
			boundaries[totalBoundaries] = (cond[c + 1] or cond.endif).iniPos
			break
		end
	end

	totalBoundaries = totalBoundaries + 1
	boundaries[totalBoundaries] = cond.endif.endPos

	self.tmpSource = sliceString(self.tmpSource, boundaries)
	return self
end

Processor.execute = function(self)
	self.tmpSource = "\n" .. self.rawSource .. "\n" -- For pattern matching

	self:DEFINE()
	while self:parse() do
		self:evaluate()
	end

	return str_sub(self.tmpSource, 2, -2)
end

return Processor