# Exercise 7: Introduction to Continuous Integration (CI) and Jenkins Installation

## Objective

The objective of this exercise is to:

- Understand the core principles, architecture, and operational benefits of **Continuous Integration (CI)**.
- Survey popular modern **CI/CD orchestration tools** across cloud and self-hosted environments.
- Gain hands-on experience **installing, running, and configuring Jenkins** using Docker containers.
- Learn how to retrieve the Jenkins **initial administrator secret password** and perform first-time setup and plugin initialization.

---

## What is Continuous Integration (CI)?

Continuous Integration is a software engineering practice where developers integrate their code into a shared repository **frequently** (often multiple times per day). Each commit triggers an automated build and test pipeline to detect integration bugs early, accelerate time-to-market, and enforce consistent code quality.

### Key Features of CI

| Feature                | Description                                                                 |
|------------------------|-----------------------------------------------------------------------------|
| **Frequent Integration** | Code changes merged regularly rather than large delayed batch releases    |
| **Automated Builds**   | Every commit automatically compiles binaries and resolves dependencies      |
| **Automated Testing**  | Unit, integration, and security regression tests run automatically          |
| **Immediate Feedback** | Instant build notifications alert developers of regressions within minutes  |

### Benefits of CI

- 🐛 **Early Bug Detection** — Catch syntax, logic, and dependency errors before staging or production.
- 🔀 **Reduced Merge Conflicts** — Frequent updates eliminate complexity of large merge conflicts.
- ⚡ **Enhanced Productivity** — Developers focus on features, not manual builds and verification.
- 📦 **Reliable Release Cadence** — High confidence in stability through verifiable test coverage.

---

## How CI Works

```
┌─────────────────────────────────────────────────────────────────┐
│                    CI Pipeline Flow                             │
│                                                                 │
│  Developer    GitHub/GitLab    CI Server     Build Agent        │
│     │              │               │              │            │
│     │──git push───►│               │              │            │
│     │              │──webhook/───► │              │            │
│     │              │   poll        │              │            │
│     │              │               │──dispatch──► │            │
│     │              │               │    job       │            │
│     │              │               │         pull source       │
│     │              │               │         compile/build     │
│     │              │               │         run tests         │
│     │              │               │◄─ result ────│            │
│     │◄─ feedback ──│◄──────────────│              │            │
│  (pass/fail)       │               │              │            │
└─────────────────────────────────────────────────────────────────┘
```

1. **Code Commit** — Developer commits and pushes changes to GitHub/GitLab.
2. **Webhook / Trigger** — The CI server detects the new commit or receives a webhook notification.
3. **Automated Build** — Agent pulls source code, prepares build container, and compiles dependencies.
4. **Automated Testing** — Automated test suites run in isolation.
5. **Feedback Loop** — Build logs and test reports are sent back to developers.

---

## Industry Survey: Leading CI/CD Tools

| Tool             | Deployment Model         | Key Highlights                                              | Best Used For                          |
|------------------|--------------------------|-------------------------------------------------------------|----------------------------------------|
| **Jenkins**      | Self-Hosted / Containerized | Open-source, 1800+ plugins, highly customizable          | Enterprise & custom workflows          |
| **GitHub Actions** | Cloud / Self-Hosted Runners | Native GitHub integration, YAML workflows, Marketplace  | GitHub-hosted repositories             |
| **GitLab CI/CD** | Cloud & Self-Hosted      | Built into GitLab, unified DevOps platform                  | End-to-end GitLab workflows            |
| **CircleCI**     | Cloud & On-Premises      | Native Docker execution, parallelism, caching               | Fast container-centric pipelines       |
| **Azure DevOps** | Cloud (Microsoft Azure)  | Deep Azure + Visual Studio integration, multi-OS agents     | Enterprise Microsoft environments      |
| **TeamCity**     | Self-Hosted & Cloud      | JetBrains enterprise CI with out-of-the-box build chains    | Complex heterogeneous pipelines        |
| **Travis CI**    | Cloud                    | Pioneer in open-source CI, clean YAML configuration         | Open-source public projects            |
| **Drone**        | Container-Native         | Lightweight, Docker containers for each pipeline step       | Minimalist container-first environments|

---

## Jenkins Architecture

```
┌──────────────────────────────────────────────────────────┐
│                  Jenkins Architecture                    │
│                                                          │
│  ┌─────────────────────────────────────────────┐        │
│  │           Jenkins Controller (Master)        │        │
│  │                                             │        │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  │        │
│  │  │  Web UI  │  │ Pipeline │  │ Plugin   │  │        │
│  │  │ :8080    │  │ Parser   │  │ Manager  │  │        │
│  │  └──────────┘  └──────────┘  └──────────┘  │        │
│  │                    │                         │        │
│  └────────────────────┼─────────────────────────┘        │
│                       │ dispatch jobs                     │
│           ┌───────────┼───────────┐                      │
│           ▼           ▼           ▼                      │
│      ┌─────────┐ ┌─────────┐ ┌─────────┐               │
│      │ Agent 1 │ │ Agent 2 │ │ Agent 3 │               │
│      │(Docker) │ │(Linux)  │ │(Windows)│               │
│      └─────────┘ └─────────┘ └─────────┘               │
└──────────────────────────────────────────────────────────┘
```

| Component      | Role                                                                          |
|----------------|-------------------------------------------------------------------------------|
| **Controller** | Serves Web UI, parses pipelines, manages configs, schedules builds            |
| **Agents**     | Machines or ephemeral Docker containers that execute build steps              |
| **Job/Project**| Configurable automated task (Freestyle, Pipeline, Multibranch)                |
| **Pipeline**   | Code-defined workflow (`Jenkinsfile`) for multi-stage CI/CD                   |
| **Plugins**    | Modular add-ons extending Jenkins with Git, Docker, Kubernetes capabilities   |

---

## Step-by-Step Installation via Docker

### Step 1: Launch Jenkins LTS Container

Run the official Jenkins Long Term Support (LTS) image:

```bash
docker run -d --name jenkins -p 8080:8080 -p 50000:50000 jenkins/jenkins:lts
```

**Port Mapping:**
| Port          | Purpose                                      |
|---------------|----------------------------------------------|
| `8080:8080`   | Jenkins HTTP Web GUI                         |
| `50000:50000` | Inbound JNLP agent communication port        |

**Verify the running container:**
```bash
docker ps --filter "name=jenkins"
```

**Output:**
```
CONTAINER ID   IMAGE                 STATUS         PORTS                                              NAMES
0f2a9ea1bd1c   jenkins/jenkins:lts   Up 2 minutes   0.0.0.0:8080->8080/tcp, 0.0.0.0:50000->50000/tcp   jenkins
```

**Verify HTTP connectivity:**
```bash
curl -I http://localhost:8080/login
```

**Output:**
```
HTTP/1.1 200 OK
Server: Jetty(12.1.13)
X-Jenkins: 2.580.1 (LTS)
```

> **Alternative:** Use `docker-compose.yml` in this folder → `docker compose up -d`

---

### Step 2: Retrieve Initial Admin Password

Jenkins generates a secure one-time secret during initialization. Extract it:

```bash
docker exec -it jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

**Secret Token:**
```
11c28f89595242dfae13de5cc331dcb8
```

> ⚠️ Your token will be different. Copy it exactly — it's required for Step 3.

---

### Step 3: Complete First-Time Web Setup

1. Navigate to **http://localhost:8080** in your browser.
2. Enter the administrator secret token to **Unlock Jenkins**.
3. Select **Install Suggested Plugins** to install Git, Pipeline, Timestamper, and Workspace plugins.
4. Create the primary **Administrator credentials**.
5. Access the main **Jenkins Dashboard** — ready for job creation!

---

## Quick Reference Commands

```bash
# Start Jenkins
docker run -d --name jenkins -p 8080:8080 -p 50000:50000 jenkins/jenkins:lts

# Get admin password
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword

# Stop Jenkins
docker stop jenkins

# Start Jenkins again (after stop)
docker start jenkins

# Remove Jenkins container
docker rm -f jenkins

# View Jenkins logs
docker logs -f jenkins

# Using docker-compose (persistent volume)
docker compose up -d
docker compose down
```

---

## Lab Q&A Summary

### Q1. What is Continuous Integration and why is it important?
**A:** CI is the practice of **frequently merging developer code** into a shared repository, with each merge automatically triggering a build and test pipeline. It is important because it catches integration bugs early, reduces merge conflicts, maintains code quality, and enables faster, more reliable releases.

### Q2. What are the two ports used by Jenkins and what is each for?
**A:**
- **Port 8080** — The Jenkins **HTTP Web GUI**. Administrators and developers access the dashboard, create jobs, and view build results here.
- **Port 50000** — The **JNLP agent communication port**. Remote build agents (workers) connect to the controller through this port to receive and execute build jobs.

### Q3. How do you retrieve the Jenkins initial administrator password?
**A:** By reading the auto-generated secret file inside the container:
```bash
docker exec -it jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```
This file is created during the first boot and contains a one-time token required to unlock the Jenkins web setup wizard.

### Q4. What is the difference between Jenkins Controller and Agents?
**A:**
- **Controller (Master):** The central orchestration node. It hosts the Web UI, manages job configurations, parses Jenkinsfiles, and schedules builds. It does **not** execute build steps directly.
- **Agents (Workers):** Machines (physical, VM, or Docker containers) that execute the actual build and test steps dispatched by the controller. Multiple agents allow parallel, distributed builds.

### Q5. Why choose Jenkins over cloud-native CI tools like GitHub Actions?
**A:** Jenkins is preferred when:
- **Full control** over infrastructure and security is required (on-premises, air-gapped environments).
- **Custom workflows** need deep plugin customization (1800+ plugins).
- **Legacy systems** require specific build toolchains or integration with non-cloud tooling.
- **Multi-cloud** pipelines need a vendor-neutral orchestrator.
Cloud tools like GitHub Actions are simpler for straightforward GitHub workflows but offer less flexibility for complex enterprise environments.
