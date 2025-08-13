# pf9-gatherer

Platform9 Cluster dump gatherer - A utility script for collecting comprehensive Kubernetes cluster information from Platform9 managed clusters.

## Description

This script gathers detailed cluster dump information from Platform9 managed Kubernetes clusters, providing administrators with comprehensive diagnostics and troubleshooting data.

## Prerequisites

Before running this script, ensure you have:

- Access to a Platform9 managed Kubernetes cluster
- `kubectl` installed and configured
- **KUBECONFIG exported** for the PCD Management Cluster
- Appropriate cluster permissions to read resources

## Installation

### Quick Start

Download and execute the script directly:

```bash
bash <(curl -Ls https://raw.githubusercontent.com/vishnu-prasadtv/pf9-gatherer/refs/heads/main/pf9-gatherer.sh)
