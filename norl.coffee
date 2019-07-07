### js-hint -W083 ###

T=console.log
E=console.error
$async=require("async")

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

finish=(r,options)=>
	if typeof r?.then=='function'
		r.then ($_)=>
			eval(options.finalEval) if options?.finalEval?
			process.exit 0
		.catch (e)=>
			E "#{JSON.stringify(e)}"
			process.exit 1

	else if typeof r=='function'
		r (e,$_)=>
			if e
				E "#{JSON.stringify(e)}"
				process.exit 1
			else
				eval(options.finalEval) if options?.finalEval?
				process.exit 0
	else
		eval(options.finalEval) if options?.finalEval?
		process.exit 0

exports.r=(func,options)=>
	$G={}
	r=execfunc $G,null,func,'' if typeof func=='function'
	finish r,options

exports.e=(sep,func,options)=>
	unless getSep(sep)
		options=func
		func=sep
		sep=null
	else
		sep=getSep(sep)

	$_=require('fs').readFileSync('/dev/stdin', 'utf8').toString()

	$G={}
	r=execfunc $G,sep,func,$_ if typeof func=='function'
	finish r,options

lineExec=(sep,func,beginFunc,endFunc,options,cb)=>
	unless getSep(sep)
		options=endFunc
		endFunc=beginFunc
		beginFunc=func
		func=sep
		sep=null
	else
		sep=getSep(sep)

	$asyncList=[]
	$results=[]
	$G={}
	beginFunc $G if typeof beginFunc=='function'

	readLine=require('readline').createInterface(
		input:process.stdin
	)

	readLine.on 'line',($_)=>
		r=cb $G,sep,func,$_

		if typeof r?.then=='function'
			$asyncList.push ((cb)->
				this.then (ret)->cb null,ret
					.catch (e)->cb  e,null
			).bind(r)

		else if typeof r == 'function' ## must be function(callback){..}. callback is async.js style like  callback(error,object). parameters can be passed via bind(null,arg1,arg2...).  for example 'return( ((cb)=>cb(null,this)).bind(null,$_) )'
			$asyncList.push r

		else
			$results.push r


	readLine.on 'close',()=>
		f=($G,results)=>
			r=null
			r=endFunc($G,results) if typeof endFunc=='function'
			finish r,options

		if $asyncList.length>0
			$async.parallelLimit($asyncList,options?.numExecute ? 1)
			.then (rs)=>
				f($G,rs)

			.catch (e)=>
				if e.cmd? && e.code?
					E "stopped(#{e.code}):command( #{e.cmd} )"
				else
					E "#{JSON.stringify(e)}"
		else
			f($G,$results)

exports.ne=(sep,func,beginFunc,endFunc,options)=>
	lineExec sep,func,beginFunc,endFunc,options,execfunc

