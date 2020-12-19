# prepdir
Luvit's Require Preprocessor Directives

Whenever a module is required, prepdir - once required - will check the file's source and make the changes requested based on its syntax.

It works by overwriting the function `loadstring`, used by Luvit's `require` function. Make sure to use relative paths or else Lua's `require` will be used instead, thus not triggering prepdir.

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

A Preprocessor Directive is started by `@#`. It is **HIGHLY recommended** to use it in the beginning of a new line.

The following tokens are available:
`IF`, `ELIF`, `ELSE` and `ENDIF`.

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
```

You **must not** nest proprocessor directives.


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
function sub(a, b)
	return
		a
		-
		b
end
```

