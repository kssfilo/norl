#!/usr/bin/env bats

@test "e" {
	t="Hello World"
	r=$(echo $t|dist/cli.js -e 'console.log($_)')
	test "$t" == "$r"
}

@test "-pe" {
	test "$(echo Hello World|dist/cli.js -pe 'return($_.replace(/World/,"Earth"))')" == "Hello Earth"
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

@test "-ane" {
	r=$(echo -e "Hello World\nGood Night"|dist/cli.js -ane 'console.log($F[1])')
	test "$(echo $r)" == "World Night"
}

@test "-aFpe" {
	r=$(echo -e "Hello World\nGood Night"|dist/cli.js -aF /o/ -ne 'console.log($F[0])')
	test "$(echo $r)" == "Hell G"
}

@test "-neBE" {
	test "$(echo -e "Hello World\nGood Night"|dist/cli.js -B '$G.count=0;$G.lines=0;' -ne '$G.lines++;$G.count+=$_.length' -E 'console.log(`counts:${$G.count},lines:${$G.lines}`)')" == "counts:21,lines:2"
}

