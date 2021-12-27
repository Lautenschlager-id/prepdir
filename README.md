# prepdir
Preprocessor Directives for Luvit's Require

Whenever a module is required, _prepdir_ - once required - will check the file's source and make the changes according to the given settings.

It works by overwriting the function `loadstring`, used by Luvit's `require` function. Make sure to use relative paths or else Lua's `require` will be used instead, thus not triggering prepdir.

You can also access the class `Processor` that is returned in _prepdir_'s require, and use it outside the `loadstring` function.

```Lua
_G.PREPDIR_SETTINGS = {
	-- content ...
}
local modifiedStr = Processor.new(str):execute()
if str:find("@#", 1, true) then
	assert(modifiedStr ~= str)
else
	assert(modifiedStr == str)
end
```

### Requirements

- `Luvit`
- A global table named `PREPDIR_SETTINGS`. This table contains the ENV in which the expressions will be executed. You can create variables and other fields. Example:
```
-- File a.lua
_G.PREPDIR_SETTINGS = {
	DEBUG = true
}

require("prepdir")

require("b")

-- File b.lua
@#IF DEBUG
print("DEBUGGING!")
@#ELSE
print("NOT DEBUGGING!")
@#ENDIF

print(1 + 1)
```

### Installing

Run the following command
```
lit install Lautenschlager-id/prepdir
```

### Syntax

A Preprocessor Directive is started by `@#`. Make use of the tokens in the beginning of a new line.

The following tokens are available:
`IF`, `ELIF`, `ELSE`, `ENDIF`, and `DEFINE`.

The syntax is:
```
@#IF expression
CHUNK
[@#ELIF expression
CHUNK
...]
[@#ELSE
CHUNK]
@#ENDIF

[@#DEFINE varname expression]
```

Nested proprocessor directives are now possible, however you should keep in mind that they now rely on the tab levels.


### Examples
```Lua
@#IF IS_SUMMING
function sum(a, b)
@#ELIF IS_SUBTRACTING
function sub(a, b)
@#ENDIF
	return
		a
		@#IF IS_SUMMING
			@#IF PLUS_ONE
			+ 1
			@#ENDIF
		+
		@#ELIF IS_SUBTRACTING
		-
		@#ENDIF
		b
end
```

Depending on the settings, the result is:

```Lua
function sum(a, b)
	return
		a
		+
		b
end
```
or
```Lua
function sum(a, b)
	return
		a
			+ 1
		+
		b
end
```
or
```Lua
function sub(a, b)
	return
		a
		-
		b
end
```

