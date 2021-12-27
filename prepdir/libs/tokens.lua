local expression = "([%w_ %+%-%*/%[%]%(%){}&|!%.~='\"]+)"

local endOfLine = "\r?\n"
local prefix = endOfLine .. "()([\t ]*)@#"
local prefixByTab = endOfLine .. "()%s@#"
endOfLine = endOfLine .. "()"

local tokenMatchers = { -- Other prefixes are defined in the class
	IF     =            "IF "                .. expression .. endOfLine,
	ELIF   =            "ELIF "              .. expression .. endOfLine,
	ELSE   =            "ELSE"                             .. endOfLine,
	ENDIF  =            "ENDIF"                            .. endOfLine,
	DEFINE = prefix  .. "DEFINE (%a[%w_]+) " .. expression .. endOfLine,
	_NEXT  =            "(%S+)"
}

return {
	prefix = prefix,
	prefixByTab = prefixByTab,
	tokenMatchers = tokenMatchers
}