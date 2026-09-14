# telemetryd
lightweight system daemon for Proxmox VMs
--
This a personal project aimed at learning proxmox and implementing a production-grade infrastructure pipeline through setting up a simple telemetry daemon service in a debian 12 VM environment.

---
**Phase 1** Starting with the first phase of learning:
- Creating a debian 12 vm manually through the ISO installer.
- Manually setting up the SSH server and standard system utilities.
- Securing the VM and blocking password ssh logins and configuring key authentication.
- Manually transfer the telemetry daemon script and setting up a systemd service file and configuring a reverse proxy to expose the JSON output

**Goal**: Experiencing the time cost of manual server configuration and automating the process through the next phases.

**What I learned**: manually installing the vm through the ISO took alot of time, I didn't have all my dependencies available and had to hunt for dependencies.
On average this would take me ~15 mins.

---
**Phase 2** Writing a deployment script:
- Creating a clean debian 12 vm with dependencies ready and convert it into a Proxmox template using the GUI.
- Using the host shell, write a deployment script.
- Use the qm command to create 3 identical vms from the template.

**Goal**: Deploy the telemetry servers right away.

**What I learned**: creating 3 vms on the fly from a template and setting up the webserver right away took 2 mins at most.
Although writing the deployment script was a very manual process, and I had to edit the template to accomodate deploying through SSH and a bash script.

---
**Phase 3** Infrastructure as code using Terraform
- Install terraform, generate API token in Proxmox, and write declarative config files.
- Define the three VMs, CPU and RAM limits, networking in code.

**Goal**: Learn how to write declarative state files and manage states, rather than describe how to write the system describe what the end result should be like.

**What I learned**: a declarative approach definitely made things alot easier, it's alot faster than writing iterative shell scripts.
Next step would be to completely dump the `debtest-template` VM template and generate one using terraform and ansible too.

---
**Phase 4** Configuration Management + IaC (Ansible and Terraform)
- Dump `debtest-template` and create the template during deployment with Terraform and Ansible.
- Write an Ansible inventory file and yaml playbooks that connect via SSH to update packages and deploy the daemon script.

**Goal**: Employ provisioning and configuration management tools side by side.
