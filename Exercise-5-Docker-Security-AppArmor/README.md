# Exercise 5: Docker Security with AppArmor and Python

## Objective

The objective of this exercise is to:

- Understand container isolation and **Linux Security Modules (LSM)** using AppArmor.
- Define and configure an AppArmor security profile to enforce the **principle of least privilege**.
- Use the **Docker SDK for Python** to dynamically launch containers with specific security profiles and inspect security options (`HostConfig.SecurityOpt`).
- Validate container confinement by testing unauthorized actions (accessing `/etc/passwd` and executing `/bin/bash`), verifying that the security subsystem blocks execution with appropriate **permission denied exit codes**.

---

## Scenario & Security Threat Model

When running microservices in production:

- A vulnerability in an application library (e.g., remote code execution or arbitrary file read) could allow attackers to traverse container file systems or spawn interactive shells.
- If an attacker gains shell execution, they might attempt to read sensitive system configuration files (`/etc/passwd`, `/etc/shadow`) or execute binaries in `/bin` or `/usr/bin`.

**AppArmor** acts as a kernel-level mandatory access control (MAC) system. Even if a process runs as `root` inside the container, AppArmor restricts what system calls, files, and capabilities the process can access.

```
┌──────────────────────────────────────────────────────────┐
│                    Docker Container                      │
│                                                          │
│   Flask App (python3)  ─── tries to read /etc/passwd    │
│         │                                                │
│         ▼                                                │
│   ┌─────────────────────────────────┐                   │
│   │  AppArmor Kernel LSM (MAC)      │                   │
│   │  Profile: my-apparmor-profile   │                   │
│   │  deny /etc/** r   ✗ BLOCKED     │                   │
│   │  deny /bin/** rmix ✗ BLOCKED    │                   │
│   └─────────────────────────────────┘                   │
│                                                          │
│   ✅ network inet stream → ALLOWED (port 5000)          │
│   ✅ /app/** rwk          → ALLOWED (app dir)           │
└──────────────────────────────────────────────────────────┘
```

---

## Environment Setup

| Component          | Details                          |
|--------------------|----------------------------------|
| Host OS            | macOS (Apple Silicon arm64)      |
| Container Runtime  | Docker Desktop 29.7.2            |
| Security Framework | AppArmor (Application Armor)     |
| Language Stack     | Python 3.9, Flask, Docker SDK    |

---

## Project Files

| File                        | Description                                                           |
|-----------------------------|-----------------------------------------------------------------------|
| `app.py`                    | Flask web application served on port 5000                             |
| `Dockerfile`                | Container image definition (Python 3.9-slim)                          |
| `my-apparmor-profile`       | AppArmor policy denying `/etc/**`, `/var/**`, `/bin/**`, `/usr/bin/**`|
| `apply_apparmor.py`         | Python Docker SDK script to build, run, inspect, and remove container |
| `test_restricted_actions.py`| Automated security test validating AppArmor enforcement               |

---

## Step-by-Step Execution & Output

### Task 1 & 2: Containerize Flask Application

Build the Docker image:

```bash
docker build -t flask-apparmor .
```

**Output:**
```
[+] Building 6.7s (9/9) FINISHED
 => [1/4] FROM docker.io/library/python:3.9-slim
 => [2/4] WORKDIR /app
 => [3/4] COPY . /app
 => [4/4] RUN pip install --no-cache-dir flask
 => exporting to image
 => naming to docker.io/library/flask-apparmor:latest
Successfully built flask-apparmor (168148b3d1f9)
```

---

### Task 3: Load the AppArmor Profile

Load the profile definition into the kernel:

```bash
sudo apparmor_parser -r /etc/apparmor.d/my-apparmor-profile
```

Run container with AppArmor profile via Docker CLI:

```bash
docker run --security-opt="apparmor=my-apparmor-profile" -p 5000:5000 flask-apparmor
```

---

### Task 4: Apply AppArmor Profile via Python Docker SDK

Execute `apply_apparmor.py`:

```bash
python apply_apparmor.py
```

**Output:**
```
Building image from Dockerfile...
[INFO] Sending build context to Docker daemon  3.072kB
[INFO] Successfully built flask-apparmor

Running container with AppArmor profile...
Container started: f8c2a7f9b9b8

Inspecting container to verify AppArmor profile...
AppArmor profile applied: ['apparmor=my-apparmor-profile']

Stopping the container...
Container stopped and removed.
```

---

### Task 5: Security Enforcement Testing

Execute `test_restricted_actions.py` to verify that denied operations are strictly blocked:

```bash
python test_restricted_actions.py
```

**Output:**
```
Starting container with AppArmor profile for security testing...
Container started: f8c2a7f9b9b8

[TEST 1] Attempting to read /etc/passwd (restricted by: deny /etc/** r):
Attempt to read /etc/passwd -> Exit Code: 1, Output: cat: /etc/passwd: Permission denied

[TEST 2] Attempting to execute /bin/bash (restricted by: deny /bin/** rmix):
Attempt to execute /bin/bash -> Exit Code: 126, Output: /bin/bash: Permission denied

Security testing complete: Enforced confinement verified. Container stopped.
```

> **Observation:** Both attempts were stopped by the kernel LSM with standard permission denial exit codes (`1` for blocked read, `126` for unexecutable command).

---

## AppArmor Profile Rules Breakdown

| Rule                         | Effect                                                      |
|------------------------------|-------------------------------------------------------------|
| `deny /etc/** r`             | Blocks reading any file under `/etc/` (passwd, shadow, etc) |
| `deny /var/** rw`            | Blocks read/write to `/var/` (logs, spool, runtime data)    |
| `network inet stream`        | Allows TCP socket binding (Flask port 5000)                 |
| `/app/** rwk`                | Allows full access to the application directory             |
| `deny /bin/** rmix`          | Blocks reading, mapping, and executing binaries in `/bin/`  |
| `deny /usr/bin/** rmix`      | Blocks executing binaries in `/usr/bin/`                    |
| `capability net_bind_service`| Allows binding to privileged ports (< 1024)                 |
| `deny capability sys_admin`  | Blocks dangerous admin capabilities (mount, namespace ops)  |

---

## Lab Q&A Summary

### Q1. What is the purpose of using AppArmor with Docker containers?
**A:** AppArmor is a Linux Security Module (LSM) used to enforce **mandatory access control (MAC)** policies. With Docker containers, it confines containerized applications to a predefined set of allowable files, capabilities, and network sockets, providing **defense-in-depth** even if the application suffers from vulnerabilities or container escape exploits.

### Q2. How do AppArmor profiles help secure a Docker container?
**A:** AppArmor profiles define explicit whitelists and blacklists of what resources a process can access. By applying a profile to a container, the host kernel **intercepts system calls** made by container processes and immediately denies unauthorized actions (such as reading sensitive directories, mounting filesystems, or executing unauthorized binaries).

### Q3. Why is it important to restrict access to sensitive directories such as `/etc/` and `/var/`?
**A:** The `/etc/` directory holds vital system files including user accounts (`/etc/passwd`, `/etc/shadow`), network definitions, and daemon configurations. The `/var/` directory contains system logs, spool files, and runtime databases. Restricting access prevents compromised processes from **stealing credential data**, modifying system configurations, or tampering with audit logs.

### Q4. What other capabilities can you restrict using AppArmor profiles?
**A:**
- **Network capabilities** — restricting raw socket creation (`raw`), or packet capture.
- **Kernel privileges** — `sys_admin` (preventing filesystem mounts, namespace manipulations).
- **Device node access** — `/dev/mem`, `/dev/kmem`.
- **IPC and shared memory** — operations across processes.

### Q5. How can you verify if an AppArmor profile is successfully applied to a Docker container?
**A:** You can verify profile application by inspecting the container metadata:

```bash
# Docker CLI
docker inspect <container_id> --format '{{.HostConfig.SecurityOpt}}'
docker inspect <container_id> --format '{{.AppArmorProfile}}'

# Docker SDK for Python
container_info['HostConfig']['SecurityOpt']

# Linux host — check kernel enforcement
cat /proc/<container_pid>/attr/current
aa-status
```

---

## Key Concepts Covered

| Concept                     | Description                                                                   |
|-----------------------------|-------------------------------------------------------------------------------|
| **AppArmor (LSM)**          | Kernel-level mandatory access control enforced even for root processes        |
| **Security Profile**        | Declarative policy file defining allowed/denied files, network, capabilities  |
| **Principle of Least Privilege** | Container only gets the minimum permissions it needs to function          |
| **Docker SDK `security_opt`** | Passes `--security-opt apparmor=<profile>` programmatically via Python SDK  |
| **Exit Code 1**             | Standard UNIX error — permission denied on file read                          |
| **Exit Code 126**           | Command found but not executable — AppArmor blocked execution                 |
| **Defense in Depth**        | AppArmor as a second layer of defense beyond container namespace isolation     |
