# Exercise 8: Creating "Hello World" Jenkins Job

## Objective

The objective of this exercise is to:

- Write and configure an automated executable bash script (`hello-world.sh`).
- Integrate a local Git repository with GitHub for CI/CD version control.
- Create, configure, and trigger a Jenkins **Freestyle Project** named `HelloWorld`.
- Link Jenkins **Source Code Management (SCM)** to a remote Git repository.
- Add an automated build execution step (`sh hello-world.sh`) and inspect real-time console logs.

---

## Workflow Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                   Jenkins Freestyle CI Flow                      │
│                                                                  │
│  Developer          GitHub                   Jenkins             │
│     │                  │                        │                │
│     │─ git push ──────►│                        │                │
│     │                  │◄── SCM poll / webhook ─│                │
│     │                  │                        │                │
│     │                  │── clone repo ─────────►│                │
│     │                  │                        │                │
│     │                  │        Workspace: /var/jenkins_home/    │
│     │                  │        workspace/HelloWorld             │
│     │                  │                        │                │
│     │                  │        Execute Shell:  │                │
│     │                  │        sh hello-world.sh               │
│     │                  │                        │                │
│     │                  │        → "Hello, Jenkins!"             │
│     │                  │        → Finished: SUCCESS             │
│     │◄─ build result ──┼────────────────────────│                │
└──────────────────────────────────────────────────────────────────┘
```

---

## Environment Setup

| Component       | Details                                                   |
|-----------------|-----------------------------------------------------------|
| OS              | macOS (Apple Silicon arm64)                               |
| CI Server       | Jenkins 2.580.1 LTS (Docker container)                    |
| Repository      | https://github.com/korisagar/kubernetes-hands-on.git      |
| Build Step      | UNIX Shell execution (`/bin/sh -xe`)                      |

---

## Project Files

| File              | Description                                     |
|-------------------|-------------------------------------------------|
| `hello-world.sh`  | Minimal bash script — prints "Hello, Jenkins!" |

---

## Step-by-Step Execution & Output

### Step 1: Create and Verify the Script Locally

Create `hello-world.sh` and make it executable:

```bash
cat << "EOF" > hello-world.sh
#!/bin/bash
echo "Hello, Jenkins!"
EOF

chmod +x hello-world.sh
./hello-world.sh
```

**Output:**
```
Hello, Jenkins!
```

---

### Step 2: Push the Script to GitHub Repository

Stage, commit, and push `hello-world.sh` to the remote GitHub repository:

```bash
git add hello-world.sh
git commit -m "Add hello-world.sh for Jenkins Freestyle job"
git push origin main
```

**Output:**
```
[main 4be1c56] Add hello-world.sh
 1 file changed, 2 insertions(+)
 create mode 100755 Exercise-08-Jenkins-Hello-World-Job/hello-world.sh
Writing objects: 100% (3/3), 306 bytes, done.
To https://github.com/korisagar/kubernetes-hands-on.git
   b5b67be..4be1c56  main -> main
```

---

### Step 3: Create Freestyle Project in Jenkins

1. Open Jenkins at **http://localhost:8080**
2. Click **New Item** on the left menu
3. Enter item name: `HelloWorld`
4. Select **Freestyle project** and click **OK**

---

### Step 4: Configure the Job

**General:**
- Description: `Hello World! Jenkins automated Freestyle build job.`

**Source Code Management:**
- Select **Git**
- Repository URL: `https://github.com/korisagar/kubernetes-hands-on.git`
- Branch Specifier: `*/main`

**Build Steps:**
- Add build step → **Execute shell**
- Command:
```bash
sh Exercise-08-Jenkins-Hello-World-Job/hello-world.sh
```
- Click **Save**

---

### Step 5: Trigger Build and Inspect Console Output

1. On the project page, click **Build Now**
2. Build `#1` appears under **Build History**
3. Click build `#1` → **Console Output**

**Console Output:**
```
Started by user Admin (korisagar)
Running as SYSTEM
Building in workspace /var/jenkins_home/workspace/HelloWorld
Cloning the remote Git repository
Cloning repository https://github.com/korisagar/kubernetes-hands-on.git
 > git init /var/jenkins_home/workspace/HelloWorld # timeout=10
Fetching upstream changes from https://github.com/korisagar/kubernetes-hands-on.git
Checking out Revision 4be1c568912ef (origin/main)
[HelloWorld] $ /bin/sh -xe /tmp/jenkins1281930102.sh
+ sh Exercise-08-Jenkins-Hello-World-Job/hello-world.sh
Hello, Jenkins!
Finished: SUCCESS
```

---

## Jenkins Freestyle Job Configuration Reference

```
Jenkins Dashboard
└── New Item
    └── HelloWorld (Freestyle Project)
        ├── General
        │   └── Description: Hello World! Jenkins automated Freestyle build job.
        ├── Source Code Management
        │   └── Git
        │       ├── Repository URL: https://github.com/korisagar/kubernetes-hands-on.git
        │       └── Branch Specifier: */main
        ├── Build Triggers
        │   └── (optional) Poll SCM: H/5 * * * *
        └── Build Steps
            └── Execute shell
                └── sh Exercise-08-Jenkins-Hello-World-Job/hello-world.sh
```

---

## Key Learnings

### Freestyle vs. Pipeline Projects

| Feature              | Freestyle Project                        | Pipeline Project (Jenkinsfile)               |
|----------------------|------------------------------------------|----------------------------------------------|
| **Configuration**    | GUI-driven (point-and-click)             | Code-driven (`Jenkinsfile`)                  |
| **Version Control**  | Config stored in Jenkins (not in Git)    | Pipeline-as-code — stored in repo            |
| **Complexity**       | Simple, single-stage tasks               | Multi-stage, parallel, conditional workflows |
| **Best For**         | Quick jobs, learning, simple scripts     | Production CI/CD pipelines                   |
| **Portability**      | Tied to Jenkins instance                 | Portable across Jenkins instances            |

### Workspace Isolation
Jenkins isolates each job inside its own dedicated directory:
```
/var/jenkins_home/workspace/<job_name>/
```
This prevents contamination across concurrent builds running on the same agent.

### Exit Code Behaviour

| Exit Code | Meaning              | Jenkins Result         |
|-----------|----------------------|------------------------|
| `0`       | Command succeeded    | `Finished: SUCCESS` ✅ |
| Non-zero  | Command failed       | `Finished: FAILURE` ❌ |

Jenkins treats any non-zero shell exit code as a **build failure**, ensuring immediate alerting when an automated step fails.

---

## Lab Q&A Summary

### Q1. What is a Jenkins Freestyle Project?
**A:** A Freestyle Project is Jenkins' most basic job type, configured through the Web UI. It allows you to define build steps (shell commands, Maven goals, etc.), SCM settings, and triggers without writing any code. Ideal for simple tasks and learning CI basics.

### Q2. How does Jenkins fetch source code for a build?
**A:** Jenkins uses the **SCM plugin** (Git plugin in this case) to clone or pull the repository into a dedicated workspace directory (`/var/jenkins_home/workspace/<job_name>`). It checks out the specified branch (`*/main`) before executing any build steps.

### Q3. What does `/bin/sh -xe` mean in Jenkins shell execution?
**A:**
- `-x` — **Trace mode**: Prints each command before executing it (shown as `+ sh hello-world.sh` in console output). Helps debug build failures.
- `-e` — **Exit on error**: The shell exits immediately if any command returns a non-zero exit code, marking the build as `FAILURE`.

### Q4. What is the significance of `Finished: SUCCESS` in console output?
**A:** It indicates that all build steps completed with exit code `0`. Jenkins uses this to update the build status badge (blue/green), trigger downstream jobs, send pass notifications, and record the build in the history.

### Q5. How would you trigger a Jenkins build automatically on every git push?
**A:** Two approaches:
1. **Webhook (recommended):** GitHub sends a POST request to `http://<jenkins-host>/github-webhook/` on every push → Jenkins triggers immediately.
2. **Poll SCM:** Jenkins checks the repository on a cron schedule (e.g., `H/5 * * * *` = every 5 minutes) and triggers a build if new commits are detected.
