# Troubleshooting Cgroups Issues with Podman

This guide addresses common cgroups-related issues when building or running containers with Podman for the RHEL STIG RAG system.

## Common Cgroups Errors

### Symptoms

You may encounter errors like:

```
Error: unable to set cgroups limit: container process not found for $container_id
```

Or:

```
Error: OCI runtime error: crun: the requested cgroup controller `memory` is not available
```

Or:

```
Error: cannot setup namespace using "cgroup": invalid argument
```

## Diagnosis

First, let's diagnose the specific issue:

### 1. Check Cgroup Version

```bash
# Check which cgroup version your system is running
ls -l /sys/fs/cgroup/

# For cgroup v2 (unified hierarchy), you'll see files directly in this directory
# For cgroup v1 (legacy), you'll see subdirectories like "memory", "cpu", etc.
```

### 2. Check Podman Configuration

```bash
# Check podman info for cgroup configuration
podman info | grep -A 10 "cgroup"
```

### 3. Check if Running Inside a Container

```bash
# If you're trying to run Podman inside another container
grep 'docker\|lxc' /proc/1/cgroup
```

## Solutions for Common Issues

### Issue 1: Cgroups v2 Not Properly Configured

On RHEL 9 and newer systems (which use cgroups v2 by default):

```bash
# Make sure the cgroup2 filesystem is mounted
mount | grep cgroup

# If not mounted, you can mount it:
sudo mount -t cgroup2 none /sys/fs/cgroup
```

### Issue 2: Permission Issues with Rootless Podman

```bash
# Edit the deleate for user session
loginctl enable-linger $USER

# Check if user namespace remapping is working
podman unshare cat /proc/self/uid_map
```

### Issue 3: Missing Cgroup Controllers

On RHEL 8 or systems using cgroups v1:

```bash
# Check available cgroup controllers
cat /proc/cgroups

# Make sure memory controller is available
ls -l /sys/fs/cgroup/memory
```

### Issue 4: Conflicts Between Host and Container Cgroups

Add these parameters to your deployment:

```bash
# For deploy-podman.sh script, add:
podman run --cgroup-manager=cgroupfs ...

# Or in Containerfile:
ENV _CONTAINERS_USERNS_CONFIGURED=1
```

### Issue 5: SELinux Conflicts

```bash
# Temporarily disable SELinux (not recommended for production)
sudo setenforce 0

# Better approach: Use the correct context
podman run --security-opt label=disable ...
```

## Environment-Specific Solutions

### RHEL 9 Solutions

RHEL 9 uses cgroups v2 by default:

```bash
# Make sure the cgroups2 delegation is properly configured
cat /etc/systemd/system.conf | grep Delegate
# Should have: DefaultDelegation=yes

# If missing, add:
sudo echo "DefaultDelegation=yes" >> /etc/systemd/system.conf
sudo systemctl daemon-reload
```

### RHEL 8 Solutions

RHEL 8 can use either cgroups v1 or v2:

```bash
# Check current version
mount | grep cgroup

# For RHEL 8, ensure all required controllers are mounted:
for controller in cpu cpuset memory pids; do
  if [ ! -d "/sys/fs/cgroup/$controller" ]; then
    echo "Missing $controller controller"
  fi
done
```

### Virtualized Environments (VMs, Cloud)

For virtualized environments:

```bash
# Use systemd driver for cgroups
podman --cgroup-manager=systemd run ...

# In containerfile or compose:
environment:
  - CGROUP_MANAGER=systemd
```

## Configuration Fixes

### 1. Update Podman Configuration

Edit `/etc/containers/containers.conf` (global) or `~/.config/containers/containers.conf` (user):

```toml
[cgroup_manager]
cgroup_manager = "systemd"

[engine]
cgroup_manager = "systemd"
```

### 2. Modify Kernel Parameters

For persistent changes to kernel parameters:

```bash
# Create a sysctl file
sudo cat > /etc/sysctl.d/99-container.conf << EOF
kernel.unprivileged_userns_clone=1
EOF

# Apply changes
sudo sysctl --system
```

### 3. Container Runtime Update

Make sure you have the latest crun/runc version:

```bash
# For RHEL/CentOS:
sudo dnf update podman crun

# For Ubuntu:
sudo apt update
sudo apt upgrade podman crun
```

## Specific Modifications for RHEL STIG RAG

For our RHEL STIG RAG Podman deployment, modify the following files:

### 1. Update deploy-podman.sh

```bash
# Add these options to the podman run command in deploy-podman.sh
podman run -d \
  --name "$CONTAINER_NAME" \
  --pod "$POD_NAME" \
  --cgroup-manager=systemd \
  --security-opt seccomp=unconfined \
  ...
```

### 2. Update Containerfile

```dockerfile
# Add this near the top of the Containerfile
ENV _CONTAINERS_USERNS_CONFIGURED=1
```

### 3. Update Ansible Podman Tasks

```yaml
# In ansible/tasks/podman_deploy.yml
containers.podman.podman_container:
  name: "{{ stig_rag_podman_container_name }}"
  image: "{{ stig_rag_podman_image_name }}"
  cgroup_manager: systemd
  security_opt:
    - seccomp=unconfined
  ...
```

## Workarounds for Persistent Issues

If issues persist despite the above fixes:

### Workaround 1: Use Docker Instead

If Podman cgroups issues can't be resolved, consider using Docker:

```bash
# Install Docker
sudo dnf install docker-ce docker-ce-cli containerd.io

# Use the Docker deployment method
docker-compose up -d
```

### Workaround 2: Native Installation

Bypass containers entirely by using the native installation:

```bash
# Follow the quick start method
./setup.sh
python3 app/rhel_stig_rag.py
```

### Workaround 3: Minimal Cgroups Mode

Run Podman with minimal cgroups requirements:

```bash
podman run --cgroup-manager=cgroupfs \
  --security-opt seccomp=unconfined \
  --security-opt label=disable \
  --cap-add=SYS_ADMIN \
  --tmpfs /tmp \
  --tmpfs /run \
  ...
```

## Debugging Resources

For further debugging:

```bash
# Check system journal for cgroups errors
journalctl -u podman -f

# Increase Podman logging
podman --log-level=debug ...

# Check kernel parameters
sysctl -a | grep cgroup
```

## References

- [Podman Troubleshooting Guide](https://github.com/containers/podman/blob/main/troubleshooting.md)
- [RHEL 9 Cgroups Documentation](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html/managing_monitoring_and_updating_the_kernel/working-with-control-groups-version-2_managing-monitoring-and-updating-the-kernel)
- [Cgroups v2 Documentation](https://www.kernel.org/doc/html/latest/admin-guide/cgroup-v2.html)
- [Linux Container Security](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/securing_containers/index)