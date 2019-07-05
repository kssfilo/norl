#!/usr/bin/env coffee
opt=require 'getopt'

command='e'
debugConsole=(a)->{}
program=''
beginProgram=null
endProgram=null

autoSplit=false
splitSep=null
splitSepDefaults=
	pe:"/[	 ]+/"
	ne:"/[	 ]+/"
	e:"\n"


T=console.log
E=console.error

#process.argv.shift()
appName='norl'


try
	opt.setopt 'pdh?ne:aF:B:E:'
catch e
	switch e.type
		when 'unknown'
			E "Unknown option:#{e.opt}"
		when 'required'
			E "Required parameter for option:#{e.opt}"
	process.exit(1)

opt.getopt (o,p)->
	switch o
		when 'h','?'
			command='usage'
		when 'd'
			debugConsole=E
		when 'n'
			command='ne'
		when 'p'
			command='pe'
		when 'a'
			autoSplit=true
		when 'F'
			splitSep=p[0]
		when 'e'
			program=p[0]
		when 'B'
			beginProgram=p[0]
		when 'E'
			endProgram=p[0]

debugConsole "Command: #{command}"
debugConsole "Seperator: #{splitSep ? 'default'}"
debugConsole "Auto Split: #{autoSplit}"
debugConsole "Remaining: #{opt.params()}"

#jshint evil:true
switch command
	when 'usage'
		console.log """
		#{appName} <options> -e '<program>' 
		Copyright(c) 2019,kssfilo(https://kanasys.com/gtech/)

		One Liner's NODE.js, Helps to write one line node.js stdin filter program like perl.

		options:
			-h/-?:this help
			-d:debug
			-e <program>:one line program (without -n -p option, $_ contains whole data from stdin) $G object is also available(see -B -E)
			-n:assume "perl like while(<>) { ... }" loop around program. $_ contains received line from stdin.
			-p:assume loop like -n but print returned value.(see example)
			-a:autosplit mode (splits $_ into $F) default split() pattern is space(with -n -p) or \\n(without -n -p)
			-F /pattern/ :split() pattern for -a switch (//'s are optional,you can use string instead of regex)
			-B <program>:additional program which runs before -e program.for initializing -n -p loop.You can use $G object to store global variables.
			-E <program>:additional program which runs after -e program.for finalizing -n -p loop.$G object available.return value will be process.exit param.

		example:
			echo '{"s":"Hello World"}' | #{appName} -e 'console.log(JSON.parse($_).s)'
			# Hello World

			echo -e "Hello World\\nGoodnight World"|#{appName} -pe 'm=$_.match(/^Hello/);return(m?$_:"---")'
			# Hello World
			# ---

			echo -e "Hello World\\nGoodnight World"|#{appName} -ne 'console.log($_.length)'
			# 11
			# 15

			echo -e "Hello,World\\nGoodnight,World"|#{appName} -aF ','  -ne 'console.log($F[0])'
			# Hello
			# Goodnight
			
			echo -e "Hello World\\nGoodnight World"|#{appName} -ne '$G.count+=$_.length' -B '$G.count=0' -E 'console.log("chars:"+$G.count)'
			# chars:26
			
			echo -e "Hello World\\nGoodnight World"|#{appName} -ne '$G.count+=$_.length' -B '$G.count=0' -E 'return $G.count'
			echo $?
			# 26
		"""
	else
		try
			firstArg=if autoSplit then "#{splitSep ? splitSepDefaults[command]}" else null
			lineName=if autoSplit then "$F" else '$_'

			beginFunc=null
			if beginProgram?
				prog="(function($G){#{beginProgram}})"
				debugConsole "begincode: #{prog}"
				beginFunc=eval prog

			endFunc=null
			if endProgram?
				prog="(function($G){#{endProgram}})"
				debugConsole "endcode: #{prog}"
				endFunc=eval prog

			norl=require('./norl')
			prog="(function(#{lineName},$G){#{program}})"
			debugConsole "code: #{prog}"
			func=eval(prog)

			switch command
				when 'e'
					if autoSplit
						norl.e(firstArg,func,beginFunc,endFunc)
					else
						norl.e(func,beginFunc,endFunc)

				when 'pe'
					if autoSplit
						norl.pe(firstArg,func,beginFunc,endFunc)
					else
						norl.pe(func,beginFunc,endFunc)

				when 'ne'
					if autoSplit
						norl.ne(firstArg,func,beginFunc,endFunc)
					else
						norl.ne(func,beginFunc,endFunc)

		catch e
			E e
			process.exit 1

