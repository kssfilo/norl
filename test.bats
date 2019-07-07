#!/usr/bin/env bats

@test "e" {
	t="Hello World"
	r=$(echo $t|dist/cli.js -e 'console.log($_)')
	test "$t" == "$r"
}

@test "-je" {
	test "$(echo '{"A":"Hello World"}'|dist/cli.js -je 'console.log($_.A)')" == "Hello World"
}

@test "-Je" {
	test "$(echo "Hello World"|dist/cli.js -Je '$_={"A":"Norl"}'|tr -d '\t\n ')" == '{"A":"Norl"}'
}

@test "-Je with null" {
	test "$(echo "Hello World"|dist/cli.js -Je '$_=null')" == ''
}

@test "-Pe" {
	test "$(echo '{"A":"Hello World"}'|dist/cli.js -Pje '$_=$_.A')" == "Hello World"
}

@test "-Pe with null" {
	test "$(echo '{"A":"Hello World"}'|dist/cli.js -Pje '$_=null')" == ""
}

@test "-pe" {
	test "$(echo Hello World|dist/cli.js -pe '$_=$_.replace(/World/,"Earth")')" == "Hello Earth"
}

@test "-pe with null" {
	test "$(echo -e "Hello\nWorld"|dist/cli.js -pe 'if($_=="Hello")$_=null')" == "World"
}

@test "-ne" {
	test "$(echo Hello World|dist/cli.js -ne 'console.log($_.replace(/World/,"Earth"))')" == "Hello Earth"
}

@test "-ae" {
	r=$(echo -e "Hello World\nGood Night"|dist/cli.js -ae 'console.log($F[1])')
	test "$r" == "Good Night"
}

@test "-aF" {
	r=$(echo -e "Hello World\nGood Night"|dist/cli.js -F /oo/ -ae 'console.log($F[1])')
	test "$r" == "d Night"
}

@test "-F" {
	r=$(echo -e "Hello World\nGood Night"|dist/cli.js -F /oo/ -e 'console.log($F[1])')
	test "$r" == "d Night"
}

@test "-ane" {
	r=$(echo -e "Hello,World\nGood,Night"|dist/cli.js -ane 'console.log($F[1])')
	test "$(echo $r)" == "World Night"
}

@test "-aFpe" {
	r=$(echo -e "Hello World\nGood Night"|dist/cli.js -aF /o/ -ne 'console.log($F[0])')
	test "$(echo $r)" == "Hell G"
}

@test "-C ' '" {
	r=$(echo -e "Hello,World\nGood,Night"|dist/cli.js -C ' ' -ape '$F[1]="Norl"')
	test "$(echo $r)" == "Hello Norl Good Norl"
}

@test "-c" {
	r=$(echo -e "Hello,World\nGood,Night"|dist/cli.js -C -ape '$F[1]="Norl"')
	test "$(echo $r)" == "Hello,Norl Good,Norl"
}

@test "-C" {
	r=$(echo -e "Hello,World\nGood,Night"|dist/cli.js -cape '$F[1]="Norl"')
	test "$(echo $r)" == "Hello,Norl Good,Norl"
}

@test "-x" {
	r=$(echo -e "HelloWorld\nGoodNight"|dist/cli.js -xpe '$_=`echo ${$_}|tr "o" "x"`')
	test "$(echo $r)" == "HellxWxrld GxxdNight"
}

@test "-X" {
	r=$(echo -e "Hello\nNorl\nNorl\nGoodNight"|dist/cli.js -Xpe '$_=`test "${$_}" != "Norl"`')
	test "$(echo $r)" == "Hello GoodNight"
}

@test "-neBE" {
	test "$(echo -e "Hello World\nGood Night"|dist/cli.js -B 'count=0;lines=0;' -ne 'lines++;count+=$_.length' -E 'console.log(`counts:${count},lines:${lines}`)')" == "counts:21,lines:2"
}

@test "NORL_MODULE/-r" {
	test "$(NORL_MODULES='mathjs' dist/cli.js -Pre '$_=mathjs.evaluate("1+1")')" == "2"
}

@test "NORL_MODULE/-rm" {
	test "$(NORL_MODULES='fs' dist/cli.js -m mathjs -Pre '$_=mathjs.evaluate("1+1")')" == "2"
}

@test "NORL_MODULE/-rM" {
	test "$(NORL_MODULES='mathjs' dist/cli.js -M -Pre '$_=typeof mathjs')" == "undefined"
}

@test "Promise/-Pe" {
	test "$(echo Hello|dist/cli.js -Pe 'return Promise.resolve($_)')" == "Hello"
}

@test "Promise/-Pre" {
	test "$(dist/cli.js -Pre 'return Promise.resolve("Hello")')" == "Hello"
}

@test "Promise/-ne -PE" {
	test "$(echo Hello|dist/cli.js -ne '$_=$_+"World"' -PE 'return Promise.resolve($_)')" == "[ 'HelloWorld' ]"
}

@test "Promise/-ne" {
	test "$(echo -e "Hello\nWorld"|dist/cli.js -Pne 'return Promise.resolve($_)' -E 'return Promise.resolve($_.join(" "))')" == "Hello World"
}

@test "Promise/-Jne" {
	test "$(echo -e "Hello\nWorld"|dist/cli.js -Pne 'return Promise.resolve($_)' -E 'return Promise.resolve({a:$_[0],b:$_[1]})')" == "{ a: 'Hello', b: 'World' }"
}

@test "Aync.js line by line" {
	a=$(echo -e "A,1\nB,1"|dist/cli.js -ane 'return ((name,timeout,cb)=>{console.log(`${name}:${timeout}secs`);setTimeout(()=>{cb(null,name+":OK");},timeout*1000)}).bind(null,$F[0],Number($F[1]));' -E 'console.log($_) ')	
	test "$(echo $a)" == "A:1secs B:1secs [ 'A:OK', 'B:OK' ]"
}

@test "Aync.js line by line with -L" {
	a=$(echo -e "A,1\nB,1"|dist/cli.js -L 2 -ane 'return ((name,timeout,cb)=>{console.log(`${name}:${timeout}secs`);setTimeout(()=>{cb(null,name+":OK");},timeout*1000)}).bind(null,$F[0],Number($F[1]));' -E 'console.log($_) ')	
	test "$(echo $a)" == "A:1secs B:1secs [ 'A:OK', 'B:OK' ]"
}

@test "Aync.js finally" {
	a=$(echo -e "hoge\nfuga" |dist/cli.js -ne '$_=$_.length' -PE  'return ((g,cb)=>setTimeout(()=>cb(null,g),1000)).bind(null,$_);')
	test "$a" == "[ 4, 4 ]"
}

@test "Aync.js -e" {
	a=$(echo -e "hoge\nfuga" |dist/cli.js -Pe 'return ((g,cb)=>setTimeout(()=>cb(null,"hoge"),1000)).bind(null,$_);')
	test "$a" == "hoge"
}

@test "Aync.js -re" {
	a=$(dist/cli.js -Pre 'return ((g,cb)=>setTimeout(()=>cb(null,"hoge"),1000)).bind(null,$_);')
	test "$a" == "hoge"
}
