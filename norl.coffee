### js-hint -W083 ###

T=console.log
E=console.error

getSepRegex=(regOrStr)=>
	m=regOrStr.match /^\/(.+)\/([im]?)$/
	if m
		new RegExp(m[1],m[2] ? '')
	else
		regOrStr

getSep=(sep)=>
	regex=null
	if typeof sep=='string'
		regex=getSepRegex sep
	else if sep instanceof RegExp
		regex=sep

	return(regex)

execfunc=($G,sep,func,$_)=>
	if sep?
		func $_.split(sep),$G
	else
		func $_,$G

exports.e=(sep,func,beginFunc,endFunc)=>
	unless getSep(sep)
		endFunc=beginFunc
		beginFunc=func
		func=sep
		sep=null
	else
		sep=getSep(sep)

	$G={}
	beginFunc $G if typeof beginFunc=='function'

	$_=require('fs').readFileSync('/dev/stdin', 'utf8').toString()

	r=0
	r=execfunc $G,sep,func,$_ if typeof func=='function'
	r=endFunc($G) if typeof endFunc=='function'
	process.exit r

lineExec=(sep,func,beginFunc,endFunc,cb)=>
	unless getSep(sep)
		endFunc=beginFunc
		beginFunc=func
		func=sep
		sep=null
	else
		sep=getSep(sep)

	$G={}
	beginFunc $G if typeof beginFunc=='function'

	readLine=require('readline').createInterface(
		input:process.stdin
	)
	readLine.on 'line',($_)=>
		cb $G,sep,func,$_

	readLine.on 'close',()=>
		r=0
		r=endFunc($G) if typeof endFunc=='function'
		process.exit r

exports.pe=(sep,func,beginFunc,endFunc)=>
	lineExec sep,func,beginFunc,endFunc,($G,sep,func,$_)=>
		T execfunc $G,sep,func,$_

exports.ne=(sep,func,beginFunc,endFunc)=>
	lineExec sep,func,beginFunc,endFunc,execfunc

