# 🚀 pf9-gatherer

![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=for-the-badge&logo=kubernetes&logoColor=white) ![Shell Script](https://img.shields.io/badge/shell_script-%23121011.svg?style=for-the-badge&logo=gnu-bash&logoColor=white)

> 📊 **Platform9 Cluster Dump Gatherer** - A powerful utility script for collecting comprehensive Kubernetes cluster information from Platform9 managed clusters.

## 📋 Description

This script gathers detailed cluster dump information from Platform9 managed Kubernetes clusters, providing administrators with comprehensive diagnostics and troubleshooting data for effective cluster management and issue resolution.

## ✨ Features

- 📈 **Comprehensive Data Collection** - Gathers detailed cluster diagnostics
- 🔧 **Platform9 Optimized** - Specifically designed for Platform9 managed clusters  
- 🚀 **Easy Deployment** - Simple one-line installation and execution
- 📊 **Admin-Friendly** - Provides actionable troubleshooting information

## 📋 Prerequisites

Before running this script, ensure you have:

- 🔐 Access to a Platform9 managed Kubernetes cluster
- ⚙️ `kubectl` installed and configured
- 🔑 **KUBECONFIG exported** for the PCD Management Cluster
- 🛡️ Appropriate cluster permissions to read resources

## 🛠️ Installation

### 🚀 Option 1: Direct Installation (Recommended)

Execute the script directly with a single command:

```bash
bash <(curl -Ls https://raw.githubusercontent.com/vishnu-prasadtv/pf9-gatherer/refs/heads/main/pf9-gatherer.sh)
```

### 📥 Option 2: Manual Installation

For users who prefer to download and inspect before execution:

```bash
# 📥 Download the script
curl -L https://raw.githubusercontent.com/vishnu-prasadtv/pf9-gatherer/refs/heads/main/pf9-gatherer.sh -o pf9-gatherer.sh

# 🔓 Make it executable
chmod +x pf9-gatherer.sh

# ▶️ Execute the script
./pf9-gatherer.sh
```

## 🚀 Usage

### Basic Execution

```bash
./pf9-gatherer.sh
```

### 📝 Pre-execution Setup

Ensure your KUBECONFIG is properly configured:

```bash
# 🔑 Export your KUBECONFIG
export KUBECONFIG=/path/to/your/pcd-management-cluster.kubeconfig

# ✅ Verify connectivity
kubectl get nodes
```

## ⚠️ Important Notes

> 🚨 **CRITICAL**: Ensure the PCD Management Cluster KUBECONFIG is properly exported before running the script.

```bash
export KUBECONFIG=/path/to/your/kubeconfig
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

## 🆘 Support

For issues or questions:

- 🐛 [Create an issue](../../issues) in this repository
- 📧 Contact Platform9 support for cluster-specific problems
- 💬 Check existing issues for common solutions

## 🤝 Contributing

Contributions are welcome! Please feel free to:

- 🍴 Fork the repository
- 🔧 Create a feature branch
- 📝 Submit a Pull Request
- 📋 Report bugs and issues

## 📄 License

This project is licensed under the [MIT License](LICENSE) - see the LICENSE file for details.

## 🏷️ Tags

`kubernetes` `platform9` `cluster-diagnostics` `devops` `shell-script` `troubleshooting`

---

⭐ **Found this useful?** Give it a star to show your support!
