if not _G.PREPDIR_SETTINGS then
	return false
end

--[[Syntax

#IF (expression)
chunk
#ELIF (expression)
chunk
#ELSE
chunk
#ENDIF
]]

local prepdir
do
	local format = string.format
	local gsub = string.gsub
	local match = string.match
	local sub = string.sub

	local conditionalSymbols = {
		['&'] = "and",
		['|'] = "or",
		['!'] = "not ",
		["!="] = "~="
	}
	local symbolReplace = "[&|!]"

	local prefix = "()\t*@#"
	local endOfLine = "[\r\n]+()"
	local expression = "([%w_ %+%-%*/%[%]%(%){}&|!%.~='\"]+)"

	local tokenCallbacks = { }
	local tokenMatchers = {
		IF     = prefix .. "IF "   .. expression .. endOfLine,
		ELIF   = prefix .. "ELIF " .. expression .. endOfLine,
		ELSE   = prefix .. "ELSE"  .. endOfLine,
		ENDIF  = prefix .. "ENDIF" .. endOfLine,
		__NEXT = prefix .. "(%S+)"
	}

	local READING_CHUNK, chunks = false

	tokenCallbacks.IF = function(src, endPos)
		if READING_CHUNK then return end

		local iniPos, condition, endPos = match(src, tokenMatchers.IF, endPos)
		if not iniPos then return end

		READING_CHUNK = true

		chunks[#chunks + 1] = {
			__len = 1,
			c = {
				[1] = {
					iniPos = iniPos,
					endPos = endPos,
					condition = condition
				}
			}
		}

		return endPos
	end

	tokenCallbacks.ELIF = function(src, endPos)
		if not READING_CHUNK then return end

		local iniPos, condition, endPos = match(src, tokenMatchers.ELIF, endPos)
		assert(iniPos)

		local chunk = chunks[#chunks]
		chunk.__len = chunk.__len + 1
		chunk.c[chunk.__len] = {
			iniPos = iniPos,
			endPos = endPos,
			condition = condition
		}

		return endPos
	end

	tokenCallbacks.ELSE = function(src, endPos)
		if not READING_CHUNK then return end

		local iniPos, endPos = match(src, tokenMatchers.ELSE, endPos)
		assert(iniPos)

		local chunk = chunks[#chunks]
		chunk.__len = chunk.__len + 1
		chunk.c[chunk.__len] = {
			iniPos = iniPos,
			endPos = endPos,
			condition = "true"
		}

		return endPos
	end

	tokenCallbacks.ENDIF = function(src, endPos)
		if not READING_CHUNK then return end

		local iniPos, endPos = match(src, tokenMatchers.ENDIF, endPos)
		if not iniPos then return end

		READING_CHUNK = false

		local chunk = chunks[#chunks]
		chunk.c.endif = {
			iniPos = iniPos,
			endPos = endPos
		}

		return endPos
	end

	tokenCallbacks.__NEXT = function(src, endPos)
		local iniPos, token = match(src, tokenMatchers.__NEXT, endPos)
		if not iniPos then return end

		return token
	end

	local parser = function(src)
		READING_CHUNK, chunks = false, { }

		local endPos, ifPos
		repeat
			-- Opens the conditional
			endPos = tokenCallbacks.IF(src, endPos)
			if not endPos then
				break
			end
			ifPos = endPos

			-- Gets all sub conditionals
			local nextToken
			repeat
				nextToken = tokenCallbacks.__NEXT(src, endPos)
				if nextToken == "ELIF" then
					endPos = tokenCallbacks.ELIF(src, endPos)
				else
					break
				end
			until false

			-- Check of else
			if nextToken == "ELSE" then
				endPos = tokenCallbacks.ELSE(src, endPos)
				nextToken = nil
			end

			-- Finish conditional
			nextToken = nextToken or tokenCallbacks.__NEXT(src, endPos)
			if nextToken ~= "ENDIF" then
				error(string.format("[PREPDIR] @[%d:] Mandatory token ENDIF to close \z
					token IF in @[%d]", endPos, ifPos))
			end
			endPos = tokenCallbacks.ENDIF(src, endPos)
		until false

		local cc
		for c = 1, #chunks do
			c = chunks[c]
			cc = c.c
			for sc = 1, c.__len do
				sc = cc[sc]
				sc.condition = gsub(sc.condition, symbolReplace, conditionalSymbols)
			end
		end
	end

	local evaluateCondition = function(condition)
		return load("return " .. condition, '', 't', _G.PREPDIR_SETTINGS)()
	end

	local sliceString = function(str, boundaries)
		assert(#boundaries % 2 == 0)

		for b = #boundaries, 1, -2 do
			str = sub(str, 1, boundaries[b - 1] - 1) .. string.sub(str, boundaries[b])
		end

		return str
	end

	local matcher = function(src)
		local boundaries, totalBoundaries = { }, 0

		local cc, scObj
		for c = 1, #chunks do
			c = chunks[c]
			cc = c.c

			totalBoundaries = totalBoundaries + 1
			boundaries[totalBoundaries] = cc[1].iniPos

			for sc = 1, c.__len do
				scObj = cc[sc]
				if evaluateCondition(scObj.condition) then
					totalBoundaries = totalBoundaries + 1
					boundaries[totalBoundaries] = scObj.endPos

					totalBoundaries = totalBoundaries + 1
					boundaries[totalBoundaries] = (cc[sc + 1] or cc.endif).iniPos
					break
				end
			end

			totalBoundaries = totalBoundaries + 1
			boundaries[totalBoundaries] = cc.endif.endPos
		end

		return sliceString(src, boundaries)
	end

	prepdir = function(src)
		-- Retrieve
		src = "\n" .. src .. "\n" -- For pattern matching

		-- Get chunks
		parser(src)

		src = matcher(src)

		return sub(src, 2, -2)
	end
end

local loadstring = loadstring
_G.loadstring = function(src, path)
	return loadstring(prepdir(src), path)
end

return true