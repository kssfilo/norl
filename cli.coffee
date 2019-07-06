#!/usr/bin/env coffee
$opt=require 'getopt'

$command='e'
$debugConsole=(a)->{}
$program=''
$beginProgram=null
$endProgram=null
$autoPrint=null
$ignoreNorlModules=false
$additionalModules=''
$outputSeperator=null
$executeMode=false

$autoSplit=false
$splitSep=null
$splitSepDefaults=
	pe:","
	ne:","
	e:"\n"


$P=console.log
$E=console.error

process.argv.shift()
$appName='norl'


try
	$opt.setopt 'XC::m:rMPjJpdh?ne:aF:B:E:'
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
			$debugConsole=$E
		when 'n'
			$command='ne'
		when 'p'
			$command='pe'
		when 'a'
			$autoSplit=true
		when 'F'
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
		when 'm'
			$additionalModules=p[0]
		when 'C'
			$outputSeperator=p[0] ? ','
		when 'X'
			$executeMode=true


$modules=((unless $ignoreNorlModules then (process.env['NORL_MODULES'] ? '') else '') + " #{$additionalModules ? ''}").replace(/^ +| +$/g,'').split(/ +/).filter((i)=>i!='') ? []

$debugConsole "Command: #{$command}"
$debugConsole "Seperator: #{$splitSep ? 'default'}"
$debugConsole "Auto Split: #{$autoSplit}"
$debugConsole "Remaining: #{$opt.params()}"
$debugConsole "ENV: #{$modules}"

switch $command
	when 'usage'
		console.log """
		#{$appName} <options> -e '<program>'  [-B '<program'>] [-E '<program>']
		Copyright(c) 2019,kssfilo(https://kanasys.com/gtech/)

		one liners node.js, helps to write one line stdin filter program by node.js Javascript like perl/ruby.+JSON/CSV/Promise feature(CLI tool/module)

		options:
			-h/-?:this help
			-d:debug
			-e <program>:one line program (without -n -p option, $_ contains whole data from stdin)
			-n:call -e program line by line. $_ contains received line from stdin.(like perl/ruby -ne)
			-p:assume loop like -n but console.log($_) each line after -e <program> (like perl/ruby -pe) you can delete current line by $_=null
			-a:autosplit mode (splits $_ into $F) default split() pattern is ','(with -n -p) or \\n(without -n -p)
			-F /pattern/ :split() pattern for -a switch (//'s are optional,you can use string instead of regex)
			-B <program>:(Begin) additional program which runs BEFORE -e program.for initializing(works with -n -p).
			-E <program>:(End) additional program which runs AFTER -e program.for finalizing(works with -n -p).
			-j JSON.parse stdin then stores into $_ (can't use with -n -p)
			-J JSON.stringfy($_,null,"\\t") and print it at end of stream (you can also print Promise result.see example)
			-P console.log($_) at end of stream  (you can also print Promise result.see example)
			-C [<seperator>]: CSV like output. works with -p. $_=$F.join(<seperator>) before console.log($_). use with -a to manipulate CSV like files
			-X execute $_ as shell command after -e <program> then print result line by line. works with -p. like xargs
			-M suppress preloading by NORL_MODULES environment variable.default you can preload modules by NORL_MODULES(see example)
			-m <modules> adds module list to NORL_MODULES.for example, -m 'fs request'
			-r Just run -e <program>. stdin will be ignored.


		example:
			echo -e 'Hello World\\nGoodnight World' | #{$appName} -e 'console.log($_.replace(/World/,"Norl"))'
			# Hello Norl 
			# Goodnight Norl ($_=whole stdin)
			
			echo '{"s":"Hello World"}' | #{$appName} -j -e 'console.log($_.s)'
			# Hello World (-j option: $_=JSON.parse(stdin) before -e <program>)
			
			echo '{"s":"Hello World"}' | #{$appName} -Pj -e '$_=$_.s'
			# Hello World (-P option: console.log($_) afer -e <program>)

			echo -e "Hello World\\nGoodnight World"|#{$appName} -ne 'console.log($_.length)'
			# 11
			# 15 (-n option: call -e <program> process line by line. $_ contains received line.)
			
			echo -e "Hello World\\nGoodnight World"|#{$appName} -pe 'm=$_.match(/^Hello/);$_=m?$_:"---"'
			# Hello World
			# --- (-p option: same as -n but console.log($_) after each -e <program>)

			echo -e "Hello,World\\nGoodnight,World"|#{$appName} -a -ne 'console.log($F[0])'
			# Hello
			# Goodnight (-a: $F=$_.split(',') before -e <program> , you can change seperator by -F option)
			
			echo -e "Hello,World\\nGoodnight,World"|norl -aXpe '$_=`echo ${$F[0]}|tr "o" "O"`'
			# HellO
			# GOOdnight (-X: execute $_ after -e <program> then print result, works with -p. you can use #{$appName} like xargs

			echo -e "Hello,World\\nGoodnight,World"|#{$appName} -a -C -pe '$F[1]="Norl"'
			# Hello,Norl
			# Goodnight,Norl (-C: $_=$F.join(',') after -e <program>. works with -p for CSV like data. you can change seperator like -C ' '
			
			echo -e "Hello,10\\nGoodnight,12"|#{$appName} -ane 'count+=parseInt($F[1])' -B 'count=0' -PE '$_=`total:${count}`'
			# total:22 (-B/-E: runs <program> at begining(-B) or end(-E) of stream.works with -n/-p option.)
			
			echo -e "Hello,10\\nGoodnight,12"|#{$appName} -ane 'count+=parseInt($F[1])' -B 'count=0' -JE '$_={total:count}'
			# {"total":22} (same as above but you can print JSON by using -J instead of -P)
			
			export NORL_MODULES="mathjs fs"
			echo -e "1+2\\n3*4"|#{$appName} -pe '$_=mathjs.evaluate($_)' 
			# 3
			# 12 (you can preload modules by NORL_MODULES env or -m option. variable name is same as module name but '-' and '.' will be '_' for example, rpn_js=require("rpn-js")

			export NORL_MODULES="request-promise"
			echo -e "https://www.google.com/robots.txt" |#{$appName} -Pe 'return request_promise($_)'
			# "User-agent: ..... (you can return promise object in -e or -E. #{$appName} waits result and print it if -P or -J is specified or simply drop it without -P/-J)

			export NORL_MODULES="request-promise fs"
			echo -e "https://www.google.com/robots.txt\\nhttps://www.yahoo.com/robots.txt" |#{$appName} -ne 'return request_promise($_)'  -E 'for(i in $_){fs.writeFileSync(`robots-${i}.txt`,$_[i]) }'
			# robots-0.txt:contains google.com's robots.txt / robots-1.txt:contains yahoo.com's robots.txt
			# (if Promise is returned by -e program in -n context, #{$appName} collects it and Promise.all() to wait before -E program then pass the result array into -E program.)
		"""
	else
		try
			if $splitSep==JSON and $command in ['pe','ne']
				throw '-j option is not able to use with -n/-p option'

			if $autoPrint and $command in ['pe','ne'] and !$endProgram
				throw '-P option needs -E <program> when -n/-p option is specified'
			
			if !($command in ['pe','ne']) and ($beginProgram? or $endProgram)
				throw '-B/-E options works with -n/-p option'
			
			if $outputSeperator and $command != 'pe'
				throw '-C option works with -p'

			if $executeMode and $command != 'pe'
				throw '-X option works with -p'

			$firstArg=switch
				when $autoSplit and $splitSep? and typeof $splitSep == 'object'
					$splitSep
				when $autoSplit
					"#{$splitSep ? $splitSepDefaults[$command]}"
				else
					""

			$lineName=if $autoSplit and $splitSep !=JSON then "$_,$F" else '$_'

			#jshint evil:true
			$beginFunc=null
			if $beginProgram?
				$prog="(function($G){#{$beginProgram}})"
				$debugConsole "begincode: #{$prog}"
				$beginFunc=eval $prog

			$endFunc=null
			if $endProgram?
				$prog="(function($G,$_){#{$endProgram}#{$autoPrint ? ''}})"
				$debugConsole "endcode: #{$prog}"
				$endFunc=eval $prog

			$printLine=switch
				when $command=='pe' and $outputSeperator
					";if(typeof $F!='undefined'&&Array.isArray($F)){console.log($F.join('#{$outputSeperator}'))};"
				when $command=='pe' and $executeMode
					";if(typeof $_!='undefined'&&typeof $_=='string'){console.log(require('child_process').execSync($_).toString().trim())};"
				when $command=='pe' and !$outputSeperator? and !$executeMode
					";if(typeof $_!='undefined'&&$_!=null){console.log($_)};"
				when $autoPrint and $command in ['e','r']
					$autoPrint
				else
					''
			
			$norl=require('./norl')
			$prog="(function($G,#{$lineName}){#{$program}#{$printLine}})"
			$debugConsole "code: #{$prog}"
			$func=eval($prog)

			$debugConsole "Preloading modules"

			$debugConsole $modules
			try
				for mod in $modules
					modval=mod.replace(/[-\.]/g,'_')
					$prg="#{modval}=require('#{mod}')"
					$debugConsole " #{$prg}"
					eval $prg
			catch e
				$E e
				throw "Failed to load one of NORL_MOODULES [#{$modules.join(',')}]\n Check NODE_PATH and set like 'export NODE_PATH=$(npm root -g)'"
				
			switch $command
				when 'r'
					$norl.r($func)

				when 'e'
					if $autoSplit
						$norl.e($firstArg,$func,$autoPrint)
					else
						$norl.e($func,$autoPrint)

				when 'ne','pe'
					if $autoSplit
						$norl.ne($firstArg,$func,$beginFunc,$endFunc,$autoPrint)
					else
						$norl.ne($func,$beginFunc,$endFunc,$autoPrint)

		catch e
			$E e
			process.exit 1

