------------------------------------------- Optimization -------------------------------------------
local setmetatable = setmetatable

local str_format = string.format
----------------------------------------------------------------------------------------------------

local prefixByTab = require("../tokens").prefixByTab

local conditional = { }
conditional.__index = conditional

conditional.new = function(iniPos, endPos, condition, tabLevel)
	return setmetatable({
		totalChunks = 1,

		tabLevel = tabLevel,
		formattedPrefix = str_format(prefixByTab, tabLevel),

		endPos = endPos,

		[1] = {
			iniPos = iniPos,
			endPos = endPos,

			condition = condition
		},
	}, conditional)
end

conditional.push = function(self, iniPos, endPos, condition)
	self.totalChunks = self.totalChunks + 1
	self[self.totalChunks] = {
		iniPos = iniPos,
		endPos = endPos,
		condition = condition
	}

	self.endPos = endPos
end

return conditional