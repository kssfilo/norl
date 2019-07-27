#!/usr/bin/env bats

setup() {
	echo -e "hello,1\nnorlworld,2"  >test1.txt
	echo -e "norl,3\nhello,4"  >test2.txt
	echo -e '{"a":1,"b":2}' >test1.json
	echo -e '{"c":1,"b":4}' >test2.json
	mkdir -p test.dir
}

teardown() {
	rm test1.txt test2.txt test1.json test2.json 
	rm -r test.dir
}

@test "-pe async" {
	r=$(echo -e "hoge\naaaa" | dist/cli.js -pe 'return (cb)=>setTimeout(()=>cb(null,$_+"HO"),100)')
	test "$(echo $r)" == "hogeHO aaaaHO"
}

@test "-cape async" {
	r=$(echo -e "hoge,1\naaaa,2" | dist/cli.js -cape 'return (cb)=>setTimeout(()=>cb(null,$F),100)')
	test "$(echo $r)" == "hoge,1 aaaa,2"
}

@test "-B promise" {
	test $(echo hoge| dist/cli.js -B 'return Promise.resolve("OK")' -pe '$_="HO"+$_') == "HOhoge"
}

@test "-B async" {
	test $(echo hoge| dist/cli.js -B 'return (cb)=>setTimeout(()=>cb(null,"OK"),100)' -pe '$_="HO"+$_' ) == "HOhoge"
}

@test "node_modules -S" {
	cd test.dir
	r=$(../dist/cli.js -m "math.js" -re 'console.log("OK")' -S -d 2>&1 |grep 'norl:found.using abs path')
	cd ..
	test "$r" = 'norl:found.using abs path'
}

@test "large stream" {
	test $(dist/cli.js -re 'i=1000000;a="";while(--i){a+="A"};console.log(a)'|dist/cli.js -P |wc -c|norl -Pe '$_=Number($_)') == "1000001"
}

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

@test "-pe =>" {
	test "$(echo Hello|dist/cli.js -pe '=>$_+" Earth"')" == "Hello Earth"
}

@test "-E =>" {
	test "$(echo Hello|dist/cli.js -ne '=>$_+" Ear"' -PE '=>$_[0]+"th"' )" == "Hello Earth"
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

@test "MultiStream -e" {
	a=$(dist/cli.js test1.txt test2.txt -Pe '$_=`stream0:${$_[0].length} stream1:${$_[1].length}`')
	test "$a" == "stream0:20 stream1:15"
}

@test "MultiStream -ae" {
	a=$(dist/cli.js test1.txt test2.txt -aPe '$_=`${$F[0][1]} ${$F[1][0]}`')
	test "$a" == "norlworld,2 norl,3"
}

@test "MultiStream -je" {
	a=$(dist/cli.js test1.json test2.json -jJe '$_=_.merge($_[0],$_[1])')
	test "$(echo $a)" == '{ "a": 1, "b": 4, "c": 1 }'
}

@test "MultiStream -pe" {
	a=$(dist/cli.js test1.txt test2.txt -ape '$_=$S+" "+$F[1]')
	test "$(echo $a)" == '0 1 0 2 1 3 1 4'
}

@test "MIMO -Pe" {
	dist/cli.js test1.txt test2.txt -cape '$F[1]++' -O test.dir
	test "$(cat test.dir/test1.txt test.dir/test2.txt|tr "\n" "x")" == "hello,2xnorlworld,3xnorl,4xhello,5x"
}

@test "MIMO -Pe Promise" {
	dist/cli.js test1.txt test2.txt -ne 'return Promise.resolve($_.replace(/,/g,"!"))' -E 'console.log($_.join("X"))' -O test.dir
	test "$(cat test.dir/test1.txt test.dir/test2.txt|tr "\n" "x")" == "hello!1Xnorlworld!2xnorl!3Xhello!4x"
}

@test "MIMO -ne Promise+console.log" {
	dist/cli.js test1.txt test2.txt -ne 'return Promise.resolve($_.replace(/,/g,"_"))' -E 'console.log($_.join("X"));' -O test.dir
	test "$(cat test.dir/test1.txt test.dir/test2.txt|tr "\n" "x")" == "hello_1Xnorlworld_2xnorl_3Xhello_4x"
}

@test "MIMO not exists" {
	test "$(dist/cli.js test1.txt test2.txt test3.txt -cape '$F[1]++' -O test.dir 2>&1)" == "failed to open test3.txt"
}
