norl
==========

one liners node.js, helps to write one line stdin filter program by node.js Javascript like perl/ruby.+JSON/CSV/Promise feature(CLI tool/module)

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

## Features

you must enclose your program by quote ' or ". if you want to use single quote(') inside '. use bash single quote escape like ( norl -re $'console.log("\'")' )

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
apple,12
google,3

cat test2.txt| norl -B 'a={}' -ane 'a[$F[0]]=Number($F[1])' -JE '$_=a'
{
	"apple": 12,
	"google": 3
}

# -J: JSON.stringify($_,null,"\t") at end of stream
```

### Supor Short JSON Processing (-j + -J)

```
$ cat test2.json
{
	"apple": 12,
	"google": 3
}

cat test2.json| norl -jJe '$_.apple+=1'
{
	"apple": 13,
	"google": 3
}
```

### CSV Processing

```
$ cat test2.txt
Apple,12
Google,3

cat test2.txt| norl -cape '$F[1]=Number($F[1])+2' 
Apple,14
Google,5

# -c: $_=$F.join(',') after -e <program>.You can change seperator by -C ' ' (output) -F / +/ (input)
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
User-agent: ..... 
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

if Promise is returned by -e program in -n context, norl collects it and wait all like Promise.all()  before -E program then pass the result array into -E program.

### Async.js

```
$ cat waits.txt
A,5
B,1
C,3

$ cat waits.txt | norl -ane 'return ((name,timeout,cb)=>{console.log(`${name}:${timeout}secs`);setTimeout(()=>{cb(null,name+":OK");},timeout*1000)}).bind(null,$F[0],Number($F[1]));'
A:5secs
B:1secs
C:3secs

```
returnning function in -n context will be queued and waits all callbacks before running -E program.  the function must be async.js style like "function(cb){cb(null,"OK");)" 

you can pass parameters via .bind().like above. 

by default, execution is sequentional. you can control it by -L [<number>] option. try to append -L 2 to the example above to check behavior. 2 is number of executables in parallel. if you omit <number>, 16 will be used.

### Shell Execution

```
$ cat test3.txt
Hello,Norl
Goodnight,Norl

cat test3.txt| norl -axpe '$_=`echo ${$F[0]}|tr "o" "O"`'
HellO
GOOdnight
```

-x: execute $_ as shell command after each -e <program> then print stdout result.works with -p. you can use norl like xargs

process stops at error condition ($?!=0) at last command. you can ignore error code by appendding '|cat' at end of shell command  like $_='wc -l noexists | cat' )

```
$ cat test4.txt
README.md
NOT_EXISTS.FILE
package.json

$ cat test4.txt|norl -Xpe '$_=`test -e ${$_}`'
README.md
package.json
```

-X: same as x but path throw input line instead of stdout of shell command.checks $? result code each line then print input line if $?==0. DONT stop execution if $!=0)

you can easy to create filter program with 'test' or 'grep'. All data(code/stdin/stdout/cmd) is passed to -E <program> . try -E "console.error(JSON.stringify($_,null,2))" to see the object structure.(useful for debugging)

#### Tips

if you want to use single quote(') inside '. use bash single quote escape mode ($'..') like ( norl -re $'console.log("\'")' )

## Demo

### wc -l (counts lines)

```
cat README.md | wc -l | sed 's/^ *//'
#wc -l prints unnesessary white space

cat README.md | norl -aPe '$_=$F.length'
#norl version
```

## JSON Pretty Print

```
cat package.json|norl -jJ
```

## Detail Usage

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

- 2.0.x:-x/-X option, async.js style callback support. -L option
- 1.1.x:adds -c option/able to omit -a when -F is specified
- 1.0.x:first release
