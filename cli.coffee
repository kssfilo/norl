#!/usr/bin/env coffee
$opt=require '@kssfilo/getopt'
_=require 'lodash'
fs=require 'fs'
path=require 'path'
$async=require 'async'

$command='e'
$isDebugMode=false
$program=''
$beginProgram=null
$endProgram=null
$autoPrint=null
$ignoreNorlModules=false
$additionalModules=''
$outputSeparator=null
$executeMode=null
$numExecute=1
$targetDir=null
$searchModulesInParentDirs=false

$autoSplit=false
$splitSep=null
$splitSepDefaults=
	pe:","
	ne:","
	e:"\n"

$P=console.log
$E=console.error
$D=(str)=>
	$E "norl:"+str if $isDebugMode



$optUsages=
	h:"help"
	d:"debug mode"
	e:["program","one line program (without -n -p option, $_ contains whole data from stdin)"]
	n:"call -e program line by line. $_ contains received line from stdin.(like perl/ruby -ne)"
	p:"assume loop like -n but console.log($_) each line after -e <program> (like perl/ruby -pe) you can delete current line by $_=null"
	a:"autosplit mode (splits $_ into $F) default split() pattern is ','(with -n -p) or \\n(without -n -p)"
	F:["/regexp/","split() pattern for -a switch (you can use string instead of regex.dont need -a when -F option is specified)"]
	B:["program","(Begin) additional program which runs BEFORE -e program.for initializing(works with -n -p)."]
	E:["program","(End) additional program which runs AFTER -e program.for finalizing(works with -n -p)."]
	j:"JSON.parse stdin then stores into $_ (can't use with -n -p)"
	J:'JSON.stringfy($_,null,"\\t") and print it at end of stream after -E program (you can also print Promise/Async.js result.see example)'
	P:"console.log($_) at end of stream after -E program (you can also print Promise/Async.js callback result.see example)"
	C:["sep","CSV like output. works with -p. $_=$F.join(<sep>) before console.log($_). use with -a to manipulate CSV like files"]
	c:"same as -C but use default ',' separator.useful for joining options like -cape <program>"
	X:"execute $_ as shell command after -e <program> then print result line by line. works with -p. like xargs.if you store null into $_. do nothing for this line"
	x:"same as X but doesn't print the shell command's result. pass through input line to stdout. stops process if shell command returns non zero error. "
	L:["number","by default, shell commands will be executed sequencial. with -L option, commands will run parallel. same effect for async.js style function but Promise()."]
	m:["modules","preload module list for example, -m 'fs request'"]
	M:"suppress preloading by NORL_MODULES environment variable.default you can preload modules by NORL_MODULES(see example)"
	S:"search modules according to node.js manner i.e. <currentdir>/node_modules,<parentdir>/node_modules.. then NODE_PATH(default:NODE_PATH only)"
	r:"Just run -e <program>. stdin and files will be ignored."
	O:["dir","output directory.if you specify this option,and mutiple files are in arguments. writes output to <dir> with same filenames.see Multi-Output mode section."]


try
	#$opt.setopt 'L::cxXC::m:rMPjJpdh?ne:aF:B:E:'
	$opt.setopt 'h?de:npaF:B:E:jJPC::cXxL::m:MSrO:'
catch e
	switch e.type
		when 'unknown'
			$E "Unknown option:#{e.opt}"
		when 'required'
			$E "Required parameter for option:#{e.opt}"
	process.exit(1)

$opt.getopt (o,p)->
	switch o
		when 'h','?'
			$command='usage'
		when 'd'
			$isDebugMode=true
		when 'n'
			$command='ne'
		when 'p'
			$command='pe'
		when 'a'
			$autoSplit=true
		when 'F'
			$autoSplit=true
			$splitSep=p[0]
		when 'e'
			$program=p[0]
		when 'r'
			$command='r'
		when 'B'
			$beginProgram=p[0]
		when 'E'
			$endProgram=p[0]
		when 'j'
			$autoSplit=true
			$splitSep=JSON
		when 'J'
			$autoPrint=';if(typeof $_!="undefined"&&typeof $_=="object"&&$_!=null){console.log(JSON.stringify($_,null,"\t"))};'
		when 'P'
			$autoPrint=';if(typeof $_!="undefined"&&$_!=null){console.log($_)};'
		when 'M'
			$ignoreNorlModules=true
		when 'S'
			$searchModulesInParentDirs=true
		when 'm'
			$additionalModules=p[0]
		when 'C'
			$outputSeparator=if p[0] =='' then ',' else p[0]
		when 'L'
			$numExecute=Number(p[0]) ? 16
		when 'c'
			$outputSeparator?=','
		when 'x'
			$executeMode='result'
		when 'X'
			$executeMode='passthrough'
		when 'O'
			$targetDir=p[0]


$modules=((unless $ignoreNorlModules then (process.env['NORL_MODULES'] ? '') else '') + " #{$additionalModules ? ''}").replace(/^ +| +$/g,'').split(/ +/).filter((i)=>i!='') ? []

$inputFiles=null
if $opt.params()?.length>0
	$inputFiles=$opt.params()

$D "==starting norl"
$D "-options"
$D "command: #{$command}"
$D "separator: #{$splitSep ? 'default'}"
$D "auto Split: #{$autoSplit}"
$D "target Dir: #{$targetDir ? ''}"
$D "ENV: #{$modules}"
$D "input files: #{$inputFiles ? 'stdin'}"
$D "-------"

$D "sanity checking.."
try
	if $splitSep==JSON and $command in ['pe','ne']
		throw '-j option is not able to use with -n/-p option'

	#if $autoPrint and $command in ['pe','ne'] and !$endProgram
	#	throw '-P option needs -E <program> when -n/-p option is specified'

	if !($command in ['pe','ne']) and ($beginProgram? or $endProgram)
		throw '-B/-E options works with -n/-p option'

	if $outputSeparator and $command != 'pe'
		throw '-C option works with -p'

	if $executeMode and $command != 'pe'
		throw '-x/-X option works with -p'

	if $targetDir? and  !(fs.statSync($targetDir)?.isDirectory())
		throw "target dir #{$targetDir} not found"
	
	if $targetDir? and !$inputFiles?
		throw "-O needs one or more input files"

	$D "..OK"
catch e
	$E e.toString()
	process.exit 1

switch $command
	when 'usage'
		console.log """
		## Command line

		    norl <options> -e '<program>' [-B '<program'>] [-E '<program>'] [files...]
		
		    Copyright(c) 2019,kssfilo(https://kanasys.com/gtech/)
		    one-liners node.js, helps to write one line stdin filter program by node.js Javascript like perl/ruby.+JSON/CSV/Promise/Async/MultiStream feature(CLI tool/module)

		## Options

		#{$opt.getHelp $optUsages}		
		## Program and Namespace

		you must enclose your program by single quote '. if you want to use single quote inside, use bash single quote escape mode like this ( norl -re $'console.log("\'")' )

		- $_: input line or object (-j) or array(multi-input mode w/o -n -p). and output for auto print option (-p / -P / -J)
		- $F: splitted array when you specify auto split option (-a / -F).
		- $S: stream number when you specify multiple files(multi-input mode) with -n -p option.

		other variables which started '$' are preserved.don't use in your program.

		by default, only lodash module is preloaded into '_'. you can add other modules by NORL_MODULES or -m option.

		## Examples
			
		### 1. Perl/Ruby like stdin processing(-e / -ne / -pe / -a)

		    $ cat test.txt
		    Hello World
		    Goodnight World

		    $ cat test.txt | norl -pe '$_=$_.replace(/World/,"Norl")'
		    Hello Norl 
		    Goodnight Norl

		-e <program> : program code. without (-n/-p), -e program is called only one time. $_ contains whole stdin data.

		    $ cat test.txt|norl -pe 'm=$_.match(/^Hello/);$_=m?$_:"---"'
		    Hello World
		    ---
		
		-pe <program> : execute program line by line.then print $_ after each -e <program> by console.log($_)

		    $ cat test2.txt
		    Apple,12
		    Google,3

		    $ cat test2.txt | norl -B 'total=0' -ane 'total+=parseInt($F[1])' -PE '$_=`total:${total}`'
		    total:15

		-ne <program>: same as -pe but doesn't print $_ each line.

		-B <program>/-E <program>: executs <program> at begining(-B) / end(-E) of stream. works with -n/-p option.
		    
		    $ cat test2.txt|norl -a -pe '$_=$F[1]'
		    12
		    30

		-a option: automatic split. $F=$_.split(',') before -e <program> , you can change separator by -F option
		    
		    
		### 2. Automatic JSON.parse
		    
		    $ cat test3.json
		    {
		    	"s":"Hello World"
		    }
		    
		    $ cat test3.json|norl -j -e 'console.log($_.s)'
		    Hello World
		    
		-j option: assume stdin is JSON. $_=JSON.parse(stdin) before -e <program>. only works without (-n / -p)
		    
		### 3. Automatic Print (Text/JSON/CSV) (-P / -J / -c)
		    
		    $ cat test3.json|norl -je '$_=$_.s'
		    Hello World (shorthand of above example)
		    
		-P option: you can omit console.log($_) by -P option. just assign result into $_ at -e program (without -n) or -E program(with -n) 
		
		tips: every $_ of -ne/-pe program result is stored into an Array then pass it to -E <program> via $_. you can check -ne results by just add -P option. redirecting to stderr (-E 'console.error($_') is useful for debugging -ne program.
		    
		    $ cat test2.txt
		    Apple,12
		    Google,3

		    $ cat test2.txt|norl  -B 'count=0' -ane 'count+=Number($F[1])' -JE '$_={total:count}'
		    {"total":15}

		-J option: same as -P but prints JSON. you must assign any object to $_ in -e(without -n) or -E(with -n) 

		    $ cat test.txt
		    Hello World
		    Goodnight World
		    
		    $ cat test.txt|norl -cpe '$F[0]=$_.length;$F[1]=$_'
		    11 chars,Hello World
		    15 chars,Goodnight World
		
		-c option: CSV like output. Joins $F array by $_=$F.join(',') after each -pe <program>. works only with -p. you can change separator by -C
		    
		### 4. Super Short JSON Handling (combine -J + -j)

		    $ cat test.json
		    { "apple": 12, "google": 3 }
		    
		    $ cat test.json | norl -jJe '$_.google+=1'
		    { "apple": 12, "google": 4 }
		
		combining -j +J option: easy to modify JSON file.

		    $ cat test2.json
		    { "status":{ "apple": 12, "google": 3 }}

		    $ cat test2.json | norl -jJe '$_=$_.status'
		    { "apple": 12, "google": 3 }
		    
		you can assign a part of input JSON to $_. for extracting some properties. 
		
		builtin lodash (_) helps to manipulate objects easier. you can combine multiple JSON files by muti input mode(see another section)

		### 5. Super Short CSV Handling (combine -a + c)
		
		    $ cat test.txt
		    Apple,12
		    Google,3
		    
		    $ cat test.txt | norl -cape '$F[1]=Number($F[1])+1'
		    Apple,13
		    Google,4
		
		combining -c +a option: you can modify CSV columns by just rewrite $F[n] fields

		    $ cat test2.txt
		    partpipe,mars,010-1234-5678,2015
		    norl,moon,010-9876-5432,2019
		    
		    cat test2.txt | norl -cape '$F=[$F[0],$F[2]]'
		    partpipe,010-1234-5678
		    norl,010-9876,5432
		
		-c + -a option: you can reassign new array into $F, useful to filter columns like this example.

		### 6. Modules
		    
		    $ export NORL_MODULES="mathjs fs"
		    $ echo -e "1+2\\n3*4"|norl -pe '$_=mathjs.evaluate($_)' 
		    3
		    12
		    
		you can preload modules by NORL_MODULES environment variable. or -m option.(separated by space with in quote' ')

		    $ echo -e "1+2\\n3*4"|norl -m 'mathjs fs' -pe '$_=mathjs.evaluate($_)' 
		    3
		    12

		module are searched in NODE_PATH if you want to use global (npm install -g) module. i.e. $ export NODE_PATH=$(npm root -g))

		node_modules dirs of current/parent dirs(same manner as node.js) are also used if -S specified(high priority than NODE_PATH)

		variable name is basically same as module name but '-' and '.' will be '_'. and @private/ prefix is not used.  i.e.  
		
		    request_promise=require("request-promise"); getopt=require("@kssfilo/getopt");

		by default. lodash module is pre-loaded into '_'. and 'path' / 'fs' is available. 

		### 7. Promise
		    
		    $ export NORL_MODULES="request-promise"
		    $ echo -e "https://www.google.com/robots.txt" |norl -Pe 'return request_promise($_)'
		    User-agent: ..... 
		
		you can return promise object from -e or -E. norl waits result and print it if -P or -J is specified or simply drop it without -P/-J

		    $ cat urls.txt
		    https://www.google.com/robots.txt
		    nhttps://www.yahoo.com/robots.txt

		    $ export NORL_MODULES="request-promise fs"
		    $ cat urls.txt | norl -ne 'return request_promise($_)'  -E 'for(i in $_){fs.writeFileSync(`robots-${i}.txt`,$_[i]) }'
		    robots-0.txt:contains google.com's robots.txt
		    robots-1.txt:contains yahoo.com's robots.txt

		 if Promise is returned by each -ne program, norl collects it and Promise.all() to wait before -E program then pass the result array into -E program via $_

		### 8. async.js 
		    
		    $ cat waits.txt
		    A,5
		    B,1
		    C,3

		    $ cat waits.txt | norl -ane 'return ((name,timeout,cb)=>{console.log(`${name}:${timeout}secs`);setTimeout(()=>{cb(null,name+":OK");},timeout*1000)}).bind(null,$F[0],Number($F[1]));'
		    A:5secs
		    B:1secs (<-after 5secs from 1st line)
		    C:3secs (<-after 1secs from 2nd line)
		    
		returned function from each -ne program will be queued and waits for all callbacks before running -E program.  the function must be async.js style like '(cb)=>cb(null,"OK")'  

		you can pass parameters via .bind() like this example. by default, execution is sequential. you can control it by -L [<number>] option. try to append -L 2 to the example above to check behavior. 2 is a number of executables in parallel. if you omit <number>, 16 will be used.

		### 9. Shell Execution
		    
		    $ cat test.txt
		    Hello,World
		    Goodnight,World"

		    $ cat test.txt | norl -axpe '$_=`echo ${$F[0]}|tr "o" "O"`'
		    HellO
		    GOOdnight 

		-x option: execute $_ as shell command after each -pe <program> then print stdout of the command, works only with -p. you can use norl like xargs

		note that don't forget to assign $_. -x option executes $_ string not your -pe program itself.

		tips: process stops at error condition ($?!=0) at LAST command. you can ignore error code by appending '|cat' at end of shell command like $_='wc -l noexists | cat' 
		    
		    $ echo -e "README.md\\nnotexists.txt\\npackage.json"|norl -Xpe '$_=`test -e ${$_}`'
		    README.md
		    package.json

		-X option: same as x but pass-through input line instead of printing stdout of shell command. checks $? result code each execution then print input line if $?==0. unlike -x,  -X DOESNT stop execution when $!=0 

		you can easy to create filter program with 'test' or 'grep'. 
		
		tips: all data(code/stdin/stdout/cmd) from each shell command will be collected and passed to -E <program> via $_. appending -E "console.error(JSON.stringify($_,null,2))" is useful for debugging.

		### 10. Result Code

		    $ if cat README.md|norl -ae 'return $F.length<15?0:1';then echo "README.md is too short";fi
		    README.md is too short  (if number of lines of README.md are under 15)

		if you return a number at the final (-e or -E) program. the number will be norl's shell result code ($?). You can use norl like 'test' command inside bash if.

		### 11. Multi-Input Mode
		    
		    $ norl -jJe '$_=_.merge($_[0],$_[1])' test1.json test2.json
		    { "a": 1, "b": 4, "c": 1 }
		    # merging 2 json files (using buildin lodash(_))

		specifying file instead of stdin is ok. if the number of file is 1. norl treats this file as same as stdin.
		but you specify 2 or more files on command line, norl will be 'multi-input mode'

		without (-p / e), each files are stored in array which passed via $_. i.e. $_=[file1's contents,file2's contents,....]

		auto parsing (-J / -a) are also working on multi-input mode. with -J,  $_=[parsed1stjson,parsed2ndjson...]. with -a,$F=[splited1stfile,splited2ndfile...]

		    $ norl -pe '$_=`stream:${$S} ${$_}`' file1.txt file2.txt
		    stream:0 file1's 1st line
		    stream:0 file1's 2nd line
		    stream:1 file2's 1nd line
		    stream:2 file2's 2nd line

		with (-p / -n), same -e program will be called with every file's line. -e program is able to know the file number (0,1,..) by special value $S. 

		### 12. Multi-Input-Multi-Out(MIMO) mode

			$ norl -Pe '$_=$_.replace(/_VERSION_/g,"1.2.0")' -O destDir/  package.json README.md LICENSE.txt
			destDir/package.json
			destDir/README.json
			destDir/LICENSE.json  (All files "_VERSION_" strings were replaced by 1.2.0)

		Similar to Multi-Input Mode, but MIMO mode is very simpler than Multi-Input (single out) mode.

		if you specify destination dir by -O option with multiple input files.  program will be execute file by file. MIMO mode is just a short hand of 
			
			$ for f in file1 file2;do cat $f | norl -Pe 'program' >destdir/$f; done. 

		unlike Multi-Input(single out) mode, you can't join each file. but MIMO mode is very useful when embed something to template file like example above.

		### 13. More Tips

		all variable names which start from $.. (execept $_ /$F / $S) and _(for lodash) are preserved. but $P and $E are predefined to console.log and console.error

		this means you can rewrite console.log/console.error by $P / $E  e.g.
		
		    $ echo "Hello" | norl -e 'console.log($_);console.error("warning")'
		    #can be
		    $ echo "Hello" | norl -e '$P($_);$E("warning")'

		"""
	else
		try

			$firstArg=switch
				when $autoSplit and $splitSep? and typeof $splitSep == 'object'
					$splitSep
				when $autoSplit
					"#{$splitSep ? $splitSepDefaults[$command]}"
				else
					""
			$D "autosplit:#{if $firstArg!="" then 'enabled' else 'disabled'}"

			#$lineName=if $autoSplit and $splitSep !=JSON then "$_,$F" else '$_'
			
			#jshint evil:true
			$beginFunc=null
			if $beginProgram?
				$prog="(function($G){#{$beginProgram}})"
				$D "-B code: #{$prog}"
				$beginFunc=eval $prog
				
			$endFunc=null
			if $endProgram?
				$prog="(function($G,$_){#{$endProgram}#{$autoPrint ? ''}})"
				$D "-E code: #{$prog}"
				$endFunc=eval $prog
			else if $autoPrint
				$prog="(function($G,$_){#{$autoPrint}})"
				$D "-E code: #{$prog}"
				$endFunc=eval $prog

			$afterProgram=switch
				when $command=='pe' and $outputSeparator
					";if(typeof $F!='undefined'&&Array.isArray($F)){console.log($F.join('#{$outputSeparator}'))};"
				when $command=='pe' and $executeMode=='result'
					";if(typeof $_!='undefined'&&typeof $_=='string'){return (function(cmd,cb){require('child_process').exec(cmd,function(e,so,se){if(se!=''){console.error(se.trim())};if(so!=''){console.log(so.trim())};cb(e,so);})}).bind(null,$_);};"
				when $command=='pe' and $executeMode=='passthrough'
					";if(typeof $_!='undefined'&&typeof $_=='string'){return (function(cmd,$_originalLine,cb){require('child_process').exec(cmd,function(e,so,se){if(!e){console.log($_originalLine);};cb(null,{code:e?e.code:0,cmd:cmd,stdout:so,stderr:se})});}).bind(null,$_,$_originalLine);};"
				when $command=='pe' and !$outputSeparator? and !$executeMode
					";if(typeof $_!='undefined'&&$_!=null){console.log($_)};"
				when $autoPrint and $command in ['e','r']
					$autoPrint
				else
					';return $_;'

			$D "internal final code:#{$afterProgram}"

			$beforeProgram=switch
				when $command=='pe' and $executeMode=='passthrough'
					"$_originalLine=$_;"
				else
					''
			$D "internal first code:#{$beforeProgram}"
			
			$norl=require('./norl')
			$prog="(function($G,$_,$F,$S){#{$beforeProgram}#{$program}#{$afterProgram}})"
			$D "-e code: #{$prog}"
			$func=eval($prog)

			$D "Preloading modules.."

			$D "modules:#{JSON.stringify $modules}"
			try
				for $mod in $modules
					$modpath=$mod
					unless $modpath.match(/^@/) or !$modpath.match(path.sep)
						#path
						unless  path.isAbsolute $modpath
							$modpath=path.join process.cwd(),$modpath
					else
						#module name
						if $searchModulesInParentDirs
							$cwd=process.cwd()
							$root=path.parse($cwd).root
							loop
								$check=path.join $cwd,'node_modules',$mod
								try
									$D "checking #{$check}"
									if fs.statSync($check)?.isDirectory()
										$modpath=$check
										$D "found.using abs path"
										break
								catch e
									e=e

								if $cwd==$root
									$D "couldn't found in parent dirs.using NODE_PATH"
									break

								$cwd=path.normalize path.join $cwd,'..'

					$modval=path.basename $modpath
					$modval=$modval.replace(/[-\.]/g,'_')
					$prg="#{$modval}=require('#{$modpath}')"
					$D "assign:#{$prg}"
					eval $prg
			catch e
				#$E e
				throw "Failed to load one of NORL_MOODULES [#{$modules.join(',')}]\n Check NODE_PATH and set like 'export NODE_PATH=$(npm root -g)'"

			if !$targetDir
				$D "Begin Single-in or Multi-in-Single-out mode"

				$exitCallback=(e,r)=>
					$D "exit callback:e:#{e}/r:#{r?.code}"
					if e? or r?.code>0
						process.exit r.code

				$options=
					finalEval:$autoPrint
					numExecute:$numExecute
					inputFiles:$inputFiles
					isDebugMode:$isDebugMode
					exitCallback:$exitCallback
					
				switch $command
					when 'r'
						$norl.r $func,$options

					when 'e'
						if $autoSplit
							$norl.e $firstArg,$func,$options
						else
							$norl.e $func,$options

					when 'ne','pe'
						if $autoSplit
							$norl.ne $firstArg,$func,$beginFunc,$endFunc,$options
						else
							$norl.ne $func,$beginFunc,$endFunc,$options
			else
				$D "-O option is specified. begin Multi-in-Multi-out mode"

				$numInputStreams=$inputFiles.length
				$numExit=0
				$numErrors=0

				$async.eachSeries $inputFiles,(file,cb)=>

					$targetFile=path.join($targetDir,path.basename(file))

					$D "starting process for #{path.basename file}"
					$D "hooking up stdout to #{$targetFile}"
					$originalStdoutWrite=process.stdout.write
					$currentTargetFile=fs.createWriteStream($targetFile)
					process.stdout.write=$currentTargetFile.write.bind($currentTargetFile)
					
					$exitCallback=(e,r)=>
						$D "exit callback:e:#{e}/r:#{r?.code}/file:'#{r?.opt.inputFiles[0]}'"

						$D "restore redirection to #{$targetFile} and wait for close"
						process.stdout.write=$originalStdoutWrite
						$currentTargetFile.end ()=>
							$numExit++
							$D "finished:#{$numExit} / remains:#{$inputFiles.length-$numExit}"
							if e>0
								$D "result code of program seems error, abort."
								cb (e)
							else
								cb(null,r.code)

					$D "run module..."
					$options=
						finalEval:$autoPrint
						numExecute:$numExecute
						inputFiles:[file]
						isDebugMode:$isDebugMode
						exitCallback:$exitCallback
						
					switch $command
						when 'r'
							$norl.r $func,$options

						when 'e'
							if $autoSplit
								$norl.e $firstArg,$func,$options
							else
								$norl.e $func,$options

						when 'ne','pe'
							if $autoSplit
								$norl.ne $firstArg,$func,$beginFunc,$endFunc,$options
							else
								$norl.ne $func,$beginFunc,$endFunc,$options
				,(err,result)=>
					$D "final callback, err:#{err}, result:#{result}"

		catch e
			$E e.toString()
			#$E e
			process.exit 1

