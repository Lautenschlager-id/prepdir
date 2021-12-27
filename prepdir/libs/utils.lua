------------------------------------------- Optimization -------------------------------------------
local assert     = assert

local load       = load

local str_format = string.format
local str_gsub   = string.gsub
local str_sub    = string.sub
----------------------------------------------------------------------------------------------------

local evaluateCondition = function(condition, env)
	local f, err = load("return " .. condition, '', 't', env)
	assert(f, str_format("[PREPDIR] Bad expression %q: %s", condition, err))
	return f()
end

local normalizeCondition
do
	local conditionalSymbols = {
		['&'] = "and",
		['|'] = "or",
		['!'] = "not ",
		["!="] = "~="
	}

	local symbolReplace = "[&|!]=?"

	normalizeCondition = function(condition)
		return str_gsub(condition, symbolReplace, conditionalSymbols)
	end
end

local sliceString = function(str, boundaries)
	assert(#boundaries % 2 == 0, str_format("[PREPDIR] Slicing a string cannot be performed with \z
		odd boundaries (#%d)", #boundaries))

	for b = #boundaries, 1, -2 do
		str = str_sub(str, 1, boundaries[b - 1] - 1) .. str_sub(str, boundaries[b])
	end

	return str
end

return {
	evaluateCondition = evaluateCondition,
	normalizeCondition = normalizeCondition,
	sliceString = sliceString
}