norl
==========

one liner's node.js, helps to write one line stdin filter program like perl/ruby.(CLI tool/module)

## Example

```
	$ cat test.txt
	Hello World
	Goodnight World

	$ cat test.txt | norl -pe '$_=$_.replace(/World/,"Norl")'
	Hello Norl
	Goodnight Norl

	# -p: execute -e <program> line by line. $_: input/output line from/to stdin/out

	$ cat test2.txt
	Apple,12
	Google,3

	$ cat test2.txt | norl -B 'total=0' -ane 'total+=parseInt($F[1])' -PE '$_=`total:${total}`'
	total:15

	# -n: same as p but doesn't print at -e <program> line by line
	# -a: $F=$_.split(',') before -e <program>
	# -B <program> / -E <program>: execute <program> before(-B) / after(-E) stdin processing of -e <program>
	# -P print $_ at end of stream
```

## Install

```
npm install -g norl
```

## More Examples

### Automatic JSON.parse 

```
	$ cat test3.json
	{
		"s":"Hello World"
	}

	$ cat test3.json | norl -j -Pe '$_=$_.s'
	Hello World

	# -j: $_=JSON.parse($_) before calling -e program 
```

### Automatic JSON.stringify 

```
	$ cat test2.txt
	Apple,12
	Google,3

	cat test2.txt| norl -B 'a={}' -ane 'a[$F[0]]=$F[1]' -JE '$_=a'
	{
		"apple": "12",
		"google": "3"
	}

	# -J: JSON.stringify($_,null,"\t") at end of stream
```

## CSV Processing

```
	$ cat test2.txt
	Apple,12
	Google,3

	cat test2.txt| norl -ape '$F[1]=parseInt($F[1])*2' -C
	Apple,24
	Google,6

	# -C: $_=$F.join(',') after -e <program>.You can change seperator like -C ' ' (output) -F / +/ (input)
```

## Shell Execution

```
	$ cat test3.txt
	Hello,Norl
	Goodnight,Norl

	cat test3.txt| norl -aXpe '$_=`echo ${$F[0]}|tr "o" "O"`'
	HellO
	GOOdnight

	# -X: execute $_ as shell command after each -e <program> then print result.works with -p. you can use norl like xargs
```


### Module Preloading

```
	$ export NORL_MODULES="mathjs fs"
	$ echo "1+2"|norl -pe '$_=mathjs.evaluate($_)' 
	3

```

you can preload modules by NORL_MODULES environment variable or -m option.

variable name is same as module name but '-' and '.' will be '_'

for example, rpn_js=require("rpn-js")

set NODE_PATH if you want to use global (npm install -g) module.  or example, $ export NODE_PATH=$(npm root -g))

### Promise

```
	$ export NORL_MODULES="request-promise"
	$ echo "https://www.google.com/robots.txt" |norl -Pe 'return request_promise($_)'
	# "User-agent: ..... 
```
you can return promise object in -e  or -E. norl waits result and print it if -P or -J is specified.

```
	$ cat urls.txt
	https://www.google.com/robots.txt
	https://www.yahoo.com/robots.txt

	$ export NORL_MODULES="request-promise fs"
	cat urls.txt |norl -ne 'return request_promise($_)' -E 'for(i in $_){fs.writeFileSync(`robots-${i}.txt`,$_[i]) }'

	# robots-0.txt <- google.com's robots.txt
	# robots-1.txt <- contains yahoo.com's robots.txt
```

if Promise is returned by -e program in -n context, norl collects it and Promise.all() to wait before -E program then pass the result array into -E program.

## Usage

```
@PARTPIPE@|dist/cli.js -h
See npmjs.com or norl -h
@PARTPIPE@
```

## Module

```
npm install norl

echo '{"s":"Hello World"}'| node -e 'require("norl").e(($G,$_)=>{console.log(JSON.parse($_).s);})'
# Hello World

echo -e "Hello\nWorld"| node -e 'require("norl").ne(($G,$_)=>{console.log($_.replace(/Hello/,"Hi!"))})'
# Hi!
# World

echo -e "Hello\nWorld"| node -e 'require("norl").ne(($G,$_)=>{$G.count+=$_.length},($G)=>{$G.count=0},($G)=>{console.log(`Chars:${$G.count}`)})'
# Chars:10

# require.("norl").e(<function(-e)>)
# require.("norl").e(<RegExp|String>,<function(-e)>)

# require.("norl").ne(<function(-e)>,[<function(-B)>,<Function(-E)>)
# require.("norl").ne(<RegExp|String>,<function(-e)>,[<function(-B)>,<Function(-E)>])

# require.("norl").r(<function(-e)>)

# <RegExp|String> is seperator for .split() 
# function(-e):  function($G,$_,$F){...} 
# function(-B):  function($G){...} 
# function(-E):  function($G){...} 
# $G is global object for communicating each functions.
```
## Change Log

- 1.0.0:first release
