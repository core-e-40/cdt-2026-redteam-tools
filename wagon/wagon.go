package main

import (
	"bytes"
	_ "embed"
	"fmt"
	"os"
	"os/exec"
)

//go:embed scripts/test.sh
var simple_bash_script []byte

func main() {

	cmd := exec.Command("/bin/bash")
	cmd.Stdin = bytes.NewReader(simple_bash_script)
    cmd.Stdout = os.Stdout // debugging
    cmd.Stderr = os.Stderr // debugging 
    cmd.Run()
	fmt.Println("Ran!")
	// fmt.Println(cmd.Stdout)
	// fmt.Println(cmd.Stderr)

}
