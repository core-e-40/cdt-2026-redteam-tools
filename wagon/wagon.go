package main

import (
    _ "embed"
    "sync"
    "os/exec"
    "bytes"
    "fmt"
    "os"
    "path/filepath"
)

//go:embed scripts/test1.sh
var test1_sh []byte

//go:embed scripts/test2.sh
var test2_sh []byte

//go:embed scripts/test3.sh
var test3_sh []byte

//go:embed scripts/test4.ps1
var test4_ps1 []byte

//go:embed scripts/test5.ps1
var test5_ps1 []byte

//go:embed scripts/test6.ps1
var test6_ps1 []byte

func run_bash(script []byte, wg *sync.WaitGroup) {
    defer wg.Done()
    cmd := exec.Command("bash")
    cmd.Stdin = bytes.NewReader(script)
    cmd.Run() // silent fail
}

func run_ps1(script []byte, wg *sync.WaitGroup) {
    defer wg.Done()
    // write to temp file, powershell can't take stdin easily
    tmp, err := os.CreateTemp("", "*.ps1")
    if err != nil {
        return
    }
    defer os.Remove(tmp.Name())
    tmp.Write(script)
    tmp.Close()

    cmd := exec.Command("powershell", "-ExecutionPolicy", "Bypass", "-File", filepath.Clean(tmp.Name()))
    cmd.Run() // silent fail
}

func main() {
    var wg sync.WaitGroup

    bash_scripts := [][]byte{test1_sh, test2_sh, test3_sh}
    ps1_scripts  := [][]byte{test4_ps1, test5_ps1, test6_ps1}

    // always try bash (silent fail on Windows)
    for _, s := range bash_scripts {
        wg.Add(1)
        go run_bash(s, &wg)
    }

    // always try ps1 (silent fail on Linux)
    for _, s := range ps1_scripts {
        wg.Add(1)
        go run_ps1(s, &wg)
    }

    wg.Wait()
    fmt.Println("FINISHED")
}