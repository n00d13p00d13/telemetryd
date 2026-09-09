# telemetryd
This a personal project aimed at learning proxmox and implementing a production-grade infrastructure pipeline through setting up a simple telemetry daemon service in a debian 12 VM environment.

**Phase 1** Starting with the first phase of learning:
- Creating a debian 12 vm manually through the ISO installer.
- Manually setting up the SSH server and standard system utilities.
- Securing the VM and blocking password ssh logins and configuring key authentication.
- Manually transfer the telemetry daemon script and setting up a systemd service file and configuring a reverse proxy to expose the JSON output
**Goal**: Experiencing the time cost of manual server configuration and automating the process through the next phases.

**What I learned**: manually installing the vm through the ISO took alot of time, I didn't have all my dependencies available and had to hunt for dependencies.
On average this would take me ~15 mins.

**Phase 2** Writing a deployment script:
- Creating a clean debian 12 vm with dependencies ready and convert it into a Proxmox template using the GUI.
- Using the host shell, write a deployment script.
- Use the qm command to create 3 identical vms from the template.
**Goal**: Deploy the telemetry servers right away.
