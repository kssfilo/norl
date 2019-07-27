### js-hint -W083 ###

T=console.log
E=console.error
D=(opt,str)=>
	E "norl:"+str if opt?.isDebugMode

$async=require("async")
fs=require 'fs'

exitProcess=(opt,r)=>
	D opt,"exitprocess:#{r}"
	if opt?.exitCallback?
		D opt,"calling exitCallback:"
		opt.exitCallback (if r==0 then null else r),{code:r,opt:opt}
	else
		D opt,"there are no exitCallback.exit process."
		process.exit r
	r

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

execfunc=($G,sep,func,$_,streamId)=>
	r=null
	if sep?
		if (sep instanceof RegExp) or (typeof(sep)=='string')
			if Array.isArray $_
				f=(x.split(sep) for x in $_)
			else
				f=$_.split sep
			r=func $G,$_,f,streamId
		else
			if Array.isArray $_
				j=(JSON.parse x for x in $_)
			else
				j=JSON.parse $_
			r=func $G,j,[],streamId
	else
		r=func $G,$_,[],streamId
	r

#jshint evil:true 

finish=(r,opt)=>
	D opt,"all programs have been completed in this process.finalizing."

	if typeof r?.then=='function'
		D opt,"result is Promise. waiting complete."
		r.then ($_)=>
			D opt,"Promise finished."
			eval(opt.finalEval) if opt?.finalEval?
			return exitProcess opt,0

		.catch (e)=>
			E "#{JSON.stringify(e)}"
			return exitProcess opt,1

	else if typeof r=='function'
		D opt,"result is async function. waiting complete."
		r (e,$_)=>
			D opt,"async function finished."
			if e
				E "#{JSON.stringify(e)}"
				return exitProcess opt,1
			else
				eval(opt.finalEval) if opt?.finalEval?
				return exitProcess opt,0
	else if typeof(r)=='string'
		D opt,"result is string '#{r}'. copy it to $_"
		$_=r
		eval(opt.finalEval) if opt?.finalEval?
		return exitProcess opt,0
	else
		D opt,"result: #{if r? then JSON.stringify r else 'null'}"
		eval(opt.finalEval) if opt?.finalEval?
		return exitProcess opt,(if (typeof r == 'number') then r else 0)

exports.r=(func,opt)=>
	$G={}
	D opt,"-r mode:no input streams."
	r=execfunc $G,null,func,'',0 if typeof func=='function'
	finish r,opt

exports.e=(sep,func,opt)=>
	unless getSep(sep)
		opt=func
		func=sep
		sep=null
	else
		sep=getSep(sep)

	inputStreams=opt?.inputFiles ? ['/dev/stdin']
	D opt,"input streams:#{JSON.stringify inputStreams}"

	try
		streams=(fs.readFileSync(inputStream, 'utf8') for inputStream in inputStreams)
	catch e
		E "failed to open #{e.path ? 'stream'}"
		return exitProcess opt,1

	$G={}

	$_=if streams.length>1 then streams else streams[0]

	D opt,"$_=#{JSON.stringify $_}"

	r=execfunc $G,sep,func,$_,0 if typeof func=='function'
	finish r,opt


lineExec=(sep,func,beginFunc,endFunc,opt,cb)=>
	unless getSep(sep)
		opt=endFunc
		endFunc=beginFunc
		beginFunc=func
		func=sep
		sep=null
	else
		sep=getSep(sep)

	##
	setupStream=()=>

		$asyncList=[]
		$results=[]

		inputStreams=opt?.inputFiles ? [process.stdin]
		D opt,"input streams:#{JSON.stringify ((if x==process.stdin then "stdin" else x) for x in inputStreams)}"

		rl=require 'readline'
		readLines=[]

		# Callbacks

		fromSid=(sid)=>
			x=inputStreams[sid]
			if x==process.stdin then "stdin" else x

		streamClosed=(streamId)=>
			numClosed++
			numOpening=readLines.length-numClosed
			D "closed:#{numClosed} / opening:#{numOpening}"

			if numOpening>0
				return

			D "all streams have been closed"
			f=($G,results)=>
				D "executing -E $_=#{JSON.stringify results}"
				r=null
				r=endFunc($G,results) if typeof endFunc=='function'
				finish r,opt

			if $asyncList.length>0
				D opt,"waiting asyncList: #{$asyncList.length} items / parallel: #{opt?.numExecute ? 1}"

				$async.parallelLimit($asyncList,opt?.numExecute ? 1)
				.then (rs)=>
					if opt.funcAfterLine && rs?.length>0
						D opt,"applying after program to async results #{JSON.stringify rs}"
						opt.funcAfterLine($G,r,r) for r in rs

					f($G,rs)

				.catch (e)=>
					if e.cmd? && e.code?
						E "stopped(#{e.code}):command( #{e.cmd} )"
					else
						E "unknown error:#{JSON.stringify(e)}"
			else
				f($G,$results)

		lineCallback=(streamId,$_)->
			D opt,"stream:#{streamId}:#{fromSid streamId}: -e: $_=\"#{$_}\""
			r=cb $G,sep,func,$_,streamId

			if typeof r?.then=='function'
				D opt,"-e returns Promise.add it to queue."
				$asyncList.push ((cb)->
					this.then (ret)->cb null,ret
						.catch (e)->cb  e,null
				).bind(r)

			else if typeof r == 'function' ## must be function(callback){..}. callback is async.js style like  callback(error,object). parameters can be passed via bind(null,arg1,arg2...).  for example 'return( ((cb)=>cb(null,this)).bind(null,$_) )'
				D opt,"-e returns Async function .add it to queue."
				$asyncList.push r

			else if typeof(r) == 'string' and typeof(opt.funcAfterLine)=='function'
				D opt,"-e returns #{r},pass it to opt.funcAfterLine"
				opt.funcAfterLine($G,r,r)
				$results.push r
			else
				D opt,"-e returns #{(JSON.stringify r) ? 'null'}"
				$results.push r

		closeCallback=(streamId)->
			D opt,"stream:#{streamId}:#{fromSid streamId}: closed"
			streamClosed streamId

		##

		try
			fs.statSync(inputStream) for inputStream in inputStreams when typeof inputStream is 'string'

			streams=for inputStream in inputStreams
				if typeof inputStream == 'object'
					inputStream
				else
					fs.createReadStream inputStream


			readLines=(rl.createInterface {input:inputStream} for inputStream in streams)
		catch e
			#E e
			E "failed to open #{e.path ? 'stream'}"
			return exitProcess opt,1

		numClosed=0
		streamId=0
		for readLine in readLines
			readLine.on 'line',lineCallback.bind null,streamId
			readLine.on 'close',closeCallback.bind null,streamId
			streamId++
	## 

	D opt,"options:"+JSON.stringify opt
	$G={}

	if typeof beginFunc=='function'
		D opt,"executing:-B program"
		r=null
		r=beginFunc $G if typeof beginFunc=='function'

		if typeof r?.then=='function'
			D opt,"-B returns promsie,waiting for complete"
			r.then (result)=>
				D opt,"-B promise complete with:#{JSON.stringify result}"
				setupStream()
			.catch (e)=>
				E "-B promise throws error:#{e.toString()}"
				exitProcess opt,1
		else if typeof r == 'function' ## function(callback){..}.
			D opt,"-B Async function,waiting for complete"
			r (e,result)=>
				if e?
					E "-B async function returns error:#{e.toString()}"
					exitProcess opt,1
				else
					D opt,"-B async function complete with:#{JSON.stringify result}"
					setupStream()
		else
			D opt,"-B returns :#{JSON.stringify r}"
			setupStream()
	else
		setupStream()


exports.ne=(sep,func,beginFunc,endFunc,opt)=>
	lineExec sep,func,beginFunc,endFunc,opt,execfunc

