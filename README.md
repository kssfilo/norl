norl
==========

One Liner's NODE.js, Helps to write one line node.js stdin filter program like perl.(CLI tool/module)

## Install

```
sudo npm install -g norl
```

## Example

```
	echo '{"s":"Hello World"}' | norl -e 'console.log(JSON.parse($_).s)'
	# Hello World

	echo -e "Hello World\nGoodnight World"|norl -pe 'm=$_.match(/^Hello/);return(m?$_:"---")'
	# Hello World
	# ---

	echo -e "Hello World\nGoodnight World"|norl -ne 'console.log($_.length)'
	# 11
	# 15

	echo -e "Hello,World\nGoodnight,World"|norl -aF ','  -ne 'console.log($F[0])'
	# Hello
	# Goodnight

	echo -e "Hello World\nGoodnight World"|norl -ne '$G.count+=$_.length' -B '$G.count=0' -E 'console.log("chars:"+$G.count)'
	# chars:26
```

## Usage

```
@PARTPIPE@|dist/cli.js -h
See npmjs.com or norl -h
@PARTPIPE@
```

## Module

```
npm install norl

echo '{"s":"Hello World"}'| node -e 'require("norl").e(($_,$G)=>{console.log(JSON.parse($_).s);})'
# Hello World

echo -e "Hello\nWorld"| node -e 'require("norl").pe(($_,$G)=>{return $_.replace(/Hello/,"Hi!")})'
# Hi!
# World

echo -e "Hello\nWorld"| node -e 'require("norl").ne(($_,$G)=>{$G.count+=$_.length},($G)=>{$G.count=0},($G)=>{console.log(`Chars:${$G.count}`)})'
# Chars:10

# require.("norl").e(<function(-e)>)
# require.("norl").e(<RegExp|String>,<function(-e)>)

# require.("norl").ne(<function(-e)>,<function(-B)>,<Function(-E)>)
# require.("norl").ne(<RegExp|String>,[<function(-e)>,<function(-B)>,<Function(-E)>])

# require.("norl").pe(<function(-e)>,<function(-B)>,<Function(-E)>)
# require.("norl").pe(<RegExp|String>,<function(-e)>,[<function(-B)>,<Function(-E)>])

# each functions returns return(x) value of <Function(-E)>(ne()/pe()) or <function(-e)>(e())
# <RegExp|String> is seperator for .split() if you need to specify
```

## Change Log

- 0.0.1:first release
