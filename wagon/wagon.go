package main

import (
	_ "embed"
	"sync"
	"os/exec"
)

//go:embed scripts/test1.sh
var test1 []byte

//go:embed scripts/test2.sh
var test2 []byte

//go:embed scripts/test3.sh
var test3 []byte

// //go:embed scripts/disorder_file_sys.sh
// var file_system_scrambler []byte

// // example of how to embed more scripts/payloads
// //go:embed scripts/<script_name>.sh
// var <script_name> []byte


// Uses concurrency to run all payloads/scripts at once
func main() {
	payloads := [][]byte{
		test1,
        test2,
        test3,
	}

    var wg sync.WaitGroup
    
    for _, payload := range payloads {
        wg.Add(1)
        go func(p []byte) {
            defer wg.Done()
            script := "sudo -n bash "+ string(p) 
            cmd := exec.Command("/bin/bash", "-c", script)
            cmd.Run()
        }(payload)
    }
    
    wg.Wait()
}


