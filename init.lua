if not _G.PREPDIR_SETTINGS then
	return false
end

--[[ Syntax

@#DEFINE VAR_NAME VAR_VALUE

@#IF expression
chunk

	@#IF expression
	chunk
	@#ENDIF

@#ELIF expression
chunk

@#ELSE
chunk

@#ENDIF

]]

------------------------------------------- Optimization -------------------------------------------
local loadstring = loadstring
----------------------------------------------------------------------------------------------------

local Processor = require("classes/processor")

_G.loadstring = function(src, path)
	src = Processor.new(src):execute()
	return loadstring(src, path)
end

return Processor