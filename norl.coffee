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
	else if typeof(sep)=='object'
		regex=sep
	return(regex)

execfunc=($G,sep,func,$_)=>
	r=null
	if sep?
		if (sep instanceof RegExp) or (typeof(sep)=='string')
			r=func $G,$_,$_.split(sep)
		else
			r=func $G,JSON.parse($_)
	else
		r=func $G,$_
	r

#jshint evil:true
finish=(r,thenProgram)=>
	if typeof r?.then=='function'
		r.then ($_)=>
			eval(thenProgram) if thenProgram?
			process.exit 0
	else
		process.exit 0

exports.r=(func,thenProgram)=>
	$G={}
	r=execfunc $G,null,func,'' if typeof func=='function'
	finish r,thenProgram

exports.e=(sep,func,thenProgram)=>
	unless getSep(sep)
		thenProgram=func
		func=sep
		sep=null
	else
		sep=getSep(sep)

	$_=require('fs').readFileSync('/dev/stdin', 'utf8').toString()

	$G={}
	r=execfunc $G,sep,func,$_ if typeof func=='function'
	finish r,thenProgram

lineExec=(sep,func,beginFunc,endFunc,thenProgram,cb)=>
	unless getSep(sep)
		thenProgram=endFunc
		endFunc=beginFunc
		beginFunc=func
		func=sep
		sep=null
	else
		sep=getSep(sep)

	$promiseList=[]
	$G={}
	beginFunc $G if typeof beginFunc=='function'

	readLine=require('readline').createInterface(
		input:process.stdin
	)

	readLine.on 'line',($_)=>
		r=cb $G,sep,func,$_

		if typeof r?.then=='function'
			$promiseList.push r

	readLine.on 'close',()=>
		f=($G,results)=>
			r=null
			r=endFunc($G,results) if typeof endFunc=='function'
			finish r,thenProgram

		if $promiseList.length>0
			Promise.all $promiseList
			.then (r)=>f($G,r)
		else
			f($G)

exports.ne=(sep,func,beginFunc,endFunc,thenProgram)=>
	lineExec sep,func,beginFunc,endFunc,thenProgram,execfunc

