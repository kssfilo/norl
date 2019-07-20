# norl - one-liner's node.js like perl / ruby (CLI tool)

one-liners node.js, helps to write one line stdin filter program by node.js Javascript like perl/ruby. + JSON/CSV/Promise/Async/MultiStream feature(CLI tool/module)

- [Documentation(npmjs)](https://www.npmjs.com/package/norl)
- [Bug Report(GitHub)](https://github.com/kssfilo/norl)
- [Home Page](https://kanasys.com/gtech/)

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

$ cat test2.txt | norl -B 'total=0' -ane 'total+=Number($F[1])' -PE '$_=`total:${total}`'
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

## Demo

### wc -l (counting lines)

```
$ cat README.md | wc -l | sed 's/^ *//'
#wc -l prints unnecessary white space

$ cat README.md | norl -aPe '$_=$F.length'
#norl version
```

### JSON Pretty Print

```
$ cat test.json
{"a":1,"b":2}

$ cat test.json|norl -jJ
{
	"a": 1,
	"b": 2
}
```

### Embed version string to muliple files(like sed + bash for)

```
$ norl -Pe '$_=$_.replace(/_VERSION_/g,"1.2.0")' -O destDir/  package.json README.md LICENSE.txt
destDir/package.json
destDir/README.json
destDir/LICENSE.json  (All files "_VERSION_" strings were replaced by 1.2.0)
```

### unix join (sort is not necessary :)

```
$ cat address.csv
norl,moon
partpipe,mars

$ cat tel.csv
norl,010-342-234
partpipe,010-122-444

$ norl address.csv tell.csv a.csv tel.csv -B 'res={};' -ane '_.set(res,[$F[0],$S],$F[1]);' -E '_.forIn(res,(v,r)=>{$P([r,v[0],v[1]].join(","))})'
norl,010-342-234,moon
partpipe,010-122-444,mars
```

@PARTPIPE@|dist/cli.js -h| perl -pe 'if(!m/^    /){s/_/\\_/g}'

You can see detail usage on npmjs.com or norl -h 

- [Documentation(npmjs)](https://www.npmjs.com/package/norl)

@PARTPIPE@

## Use as Module

norl provides module interface. you can write your own CLI filter program easier. 

```
npm install norl

echo '{"s":"Hello World"}'| node -e 'require("norl").e(($G,$_)=>{console.log(JSON.parse($_).s);})'
# Hello World

echo -e "Hello\nWorld"| node -e 'require("norl").ne(($G,$_)=>{console.log($_.replace(/Hello/,"Hi!"))})'
# Hi!
# World

echo -e "Hello\nWorld"| node -e 'require("norl").ne(($G,$_)=>{$G.count+=$_.length},($G)=>{$G.count=0},($G)=>{console.log(`Chars:${$G.count}`)})'
# Chars:10

# require.("norl").r(<function(-e)>)

# require.("norl").e(<function(-e)>)
# require.("norl").e(<RegExp|String>,<function(-e)>)

# require.("norl").ne(<function(-e)>,[<function(-B)>,<Function(-E)>)
# require.("norl").ne(<RegExp|String>,<function(-e)>,[<function(-B)>,<Function(-E)>])

# <RegExp|String> is seperator for .split() 
# function(-e):  function($G,$_,$F){...} 
# function(-B):  function($G){...} 
# function(-E):  function($G){...} 
# $G is global object for communicating each functions.
```

## Change Log

- 2.4.x: -m './foo/bar' style module path support/-S search node\_modules before NODE\_PATH/async func at -B suppport/automatic => detection/automatic print for async func on -pe
- 2.3.x: added Multi-Input-Multi-Out mode (-O)
- 2.2.x: supports file input and multi-input mode.
- 2.1.x: controling process.exit(n) code by returning number at final function.(-P -J will be cancelled)
- 2.0.x: -x/-X option, async.js style callback support. -L option
- 1.1.x: adds -c option/able to omit -a when -F is specified
- 1.0.x: first release
