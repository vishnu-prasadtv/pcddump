# 🚀 pcddump

![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=for-the-badge&logo=kubernetes&logoColor=white) ![Shell Script](https://img.shields.io/badge/shell_script-%23121011.svg?style=for-the-badge&logo=gnu-bash&logoColor=white)

> 📊 **PCDDump** - A powerful utility script for collecting comprehensive PCD Management cluster information for offline troubleshooting.

## 📋 Description

This script gathers detailed cluster dump information from Platform9 managed Kubernetes clusters, providing administrators with comprehensive diagnostics and troubleshooting data for effective cluster management and issue resolution.

## ✨ Features

- 📈 **Comprehensive Data Collection** - Gathers detailed cluster diagnostics
- 🔧 **Platform9 Optimized** - Specifically designed for Platform9 managed clusters  
- 🚀 **Easy Deployment** - Simple one-line installation and execution
- 📊 **Admin-Friendly** - Provides actionable troubleshooting information

## 📋 Prerequisites

### 📝 Pre-execution Setup

Ensure your KUBECONFIG is properly configured:

```bash
# 🔑 Export your KUBECONFIG
export KUBECONFIG=/path/to/your/pcd-management-cluster.kubeconfig

# ✅ Verify connectivity
kubectl get nodes
```

## 🛠️ Installation

### 🚀 Option 1: Direct 'pcddump' Installation and Execution (Recommended)

Run this script to initiate the PCD cluster dump generation:

```bash
bash <(curl -Ls https://raw.githubusercontent.com/vishnu-prasadtv/pf9-gatherer/refs/heads/main/pcddump.sh)
```

### 📥 Option 2: Manual Execution

For users who prefer to download and inspect before execution:

```bash
# 📥 Download the script
curl -L https://raw.githubusercontent.com/vishnu-prasadtv/pf9-gatherer/refs/heads/main/pcddump.sh -o pcddump.sh

# 🔓 Make it executable
chmod +x pcddump.sh

# ▶️ Execute the script
./pcddump.sh
```

## 🚀 Usage

### Basic Execution

```bash
./pcddump.sh
```

## 🔧 Requirements

- 🐧 Linux/Unix environment
- 🌐 `curl` command available
- ⚙️ `kubectl` configured with cluster access
- 🔑 Sufficient permissions to read cluster resources
- 🔗 Internet connectivity for script download

## 📊 Output

The script generates comprehensive cluster dump containing:

- 📋 Resource configurations and manifests
- 📈 Cluster state and health information  
- 🔍 Diagnostic data and logs
- ⚙️ Platform9 specific configurations and settings
```
# bash  pcddump.sh
🚀 PCD Cluster Dump Generation is in Progress...
📁 Working with directory: /tmp/pcddump-2025-08-20_14-42-43/pcddump
⏱️ Estimated time: 5-12 minutes
=============================================
📊 [14:42:43] Step 1: Discovering namespaces...
...
...
...
=============================================
🎉 Your PCD Cluster Dump is ready!
=============================================
📁 PCD Dump directory: /tmp/pcddump-2025-08-20_14-42-43/pcddump
📁 Archived directory: /tmp/pcddump-2025-08-20_14-42-43.tar.gz
📊 Total size: 257M
📋 Summary: 29 namespaces processed

📂 Directory Structure:
  Root cluster resources: 16 describe files
  Root cluster resources: 15 YAML files
  Namespace folders: 29
  Total describe files: 567
  Total YAML files: 567

📝 Structure created:
  • /tmp/pcddump-2025-08-20_14-42-43/pcddump/namespaces-describe.txt
  • /tmp/pcddump-2025-08-20_14-42-43/pcddump/namespaces.yaml
  • /tmp/pcddump-2025-08-20_14-42-43/pcddump/get-namespaces.txt
  • /tmp/pcddump-2025-08-20_14-42-43/pcddump/get-owide-namespaces.txt
  • /tmp/pcddump-2025-08-20_14-42-43/pcddump/get-show-labels-namespaces.txt
  • /tmp/pcddump-2025-08-20_14-42-43/pcddump/get-all-events.txt
  • /tmp/pcddump-2025-08-20_14-42-43/pcddump/<cluster-resource>.yaml
  • /tmp/pcddump-2025-08-20_14-42-43/pcddump/<cluster-resource>-describe.txt
  • /tmp/pcddump-2025-08-20_14-42-43/pcddump/get-<cluster-resource>.txt
  • /tmp/pcddump-2025-08-20_14-42-43/pcddump/get-owide-<cluster-resource>.txt
  • /tmp/pcddump-2025-08-20_14-42-43/pcddump/get-show-labels-<cluster-resource>.txt
  • /tmp/pcddump-2025-08-20_14-42-43/pcddump/<namespace>/<resource>.yaml
  • /tmp/pcddump-2025-08-20_14-42-43/pcddump/<namespace>/<resource>-describe.txt
  • /tmp/pcddump-2025-08-20_14-42-43/pcddump/<namespace>/get-<resource>.txt
  • /tmp/pcddump-2025-08-20_14-42-43/pcddump/<namespace>/get-owide-<resource>.txt
  • /tmp/pcddump-2025-08-20_14-42-43/pcddump/<namespace>/get-show-labels-<resource>.txt
  • /tmp/pcddump-2025-08-20_14-42-43/pcddump/<namespace>/<pod-name>/logs.txt
  • /tmp/pcddump-2025-08-20_14-42-43/pcddump/metrics/
=============================================

```
