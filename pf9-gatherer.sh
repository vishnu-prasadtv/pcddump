#!/bin/bash

# Configuration
PARENT_DIR="/tmp/cluster-dump-$(date +%F_%H-%M-%S)"
CLUSTER_DUMP_DIR="${PARENT_DIR}/cluster-dump"
mkdir -p "${CLUSTER_DUMP_DIR}"

echo "🚀 Kubernetes Cluster Enhancement Script Started..."
echo "📁 Working with directory: ${CLUSTER_DUMP_DIR}"
echo "⏱️  Estimated time: 5-10 minutes"
echo "============================================="

# Verify cluster dump directory exists
if [ ! -d "${CLUSTER_DUMP_DIR}" ]; then
    echo "❌ Cluster dump directory not found: ${CLUSTER_DUMP_DIR}"
    echo "Please ensure the cluster dump exists before running this script."
    exit 1
fi

# Namespaced resources to process
NAMESPACED_RESOURCES=(
    secrets
    configmaps
    endpoints
    persistentvolumeclaims
    statefulsets
    cronjobs
    jobs
    resourcequotas
    networkpolicies
    poddisruptionbudgets
    rolebindings
    roles
    ingresses
    pods
    deployments
    services
    events
    daemonsets
    replicasets
)

# Non-namespaced (cluster-wide) resources - directly in root folder
CLUSTER_RESOURCES=(
    persistentvolumes
    storageclasses
    ingressclasses
    clusterrolebindings
    clusterroles
    nodes
    csidrivers
    csinodes
    csistoragecapacities
    customresourcedefinitions
    priorityclasses
    runtimeclasses
    volumeattachments
    mutatingwebhookconfigurations
    validatingwebhookconfigurations
)

# Step 1: Get all namespaces
echo "📊 [$(date +%T)] Step 1: Discovering namespaces..."
NAMESPACES=$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)

if [ -z "$NAMESPACES" ]; then
    echo "⚠️  Warning: No namespaces found or kubectl access issue"
    exit 1
fi

TOTAL_NS=$(echo $NAMESPACES | wc -w)
echo "📁 Found ${TOTAL_NS} namespaces to process"

# Step 2: Process namespaced resources
echo "🔧 [$(date +%T)] Step 2: Processing namespaced resources..."

CURRENT_NS=0
for ns in $NAMESPACES; do
    ((CURRENT_NS++))
    echo "📂 [$(date +%T)] Processing namespace: ${ns} (${CURRENT_NS}/${TOTAL_NS})"

    # Determine namespace directory - directly under cluster-dump
    NS_DIR="${CLUSTER_DUMP_DIR}/${ns}"

    # Create namespace directory if it doesn't exist
    if [ ! -d "${NS_DIR}" ]; then
        echo "  📁 Creating namespace directory: ${NS_DIR}"
        mkdir -p "${NS_DIR}"
    fi

    echo "  📁 Using directory: ${NS_DIR}"

    # Process each namespaced resource type
    for resource in "${NAMESPACED_RESOURCES[@]}"; do
        echo "  ► Processing ${resource}..."

        # Check if resources exist in this namespace
        RESOURCE_COUNT=$(kubectl get -n "${ns}" "${resource}" --no-headers 2>/dev/null | wc -l)

        if [ "$RESOURCE_COUNT" -gt 0 ]; then
            echo "    └─ Found ${RESOURCE_COUNT} ${resource}(s)"

            # Create YAML output directly in namespace folder
            echo "    └─ Creating ${resource}.yaml..."
            if kubectl get -n "${ns}" "${resource}" -o yaml > "${NS_DIR}/${resource}.yaml" 2>/dev/null; then
                echo "    └─ ✅ ${resource}.yaml created"
            else
                echo "    └─ ❌ Failed to create ${resource}.yaml"
            fi

            # Create describe output directly in namespace folder
            echo "    └─ Creating ${resource}-describe.txt..."
            if kubectl describe -n "${ns}" "${resource}" > "${NS_DIR}/${resource}-describe.txt" 2>/dev/null; then
                echo "    └─ ✅ ${resource}-describe.txt created"
            else
                echo "    └─ ❌ Failed to create ${resource}-describe.txt"
            fi
        else
            echo "    └─ No ${resource} found in namespace ${ns}"
            # Create empty files to indicate no resources exist
            touch "${NS_DIR}/${resource}.yaml"
            echo "No ${resource} resources found in namespace ${ns} at $(date)" > "${NS_DIR}/${resource}-describe.txt"
        fi
    done

    # Special handling for pods - get logs for failed/problematic pods
    echo "  ► Collecting pod logs for troubleshooting..."
    FAILED_PODS=$(kubectl get pods -n "${ns}" --field-selector=status.phase!=Running,status.phase!=Succeeded --no-headers -o custom-columns=":metadata.name" 2>/dev/null | grep -v "^$")

    if [ ! -z "$FAILED_PODS" ]; then
        mkdir -p "${NS_DIR}/pod-logs"
        echo "    └─ Found problematic pods, collecting logs..."
        for pod in $FAILED_PODS; do
            echo "      └─ Collecting logs for pod: ${pod}"
            kubectl logs -n "${ns}" "$pod" --previous > "${NS_DIR}/pod-logs/${pod}-previous.log" 2>/dev/null || echo "No previous logs available" > "${NS_DIR}/pod-logs/${pod}-previous.log"
            kubectl logs -n "${ns}" "$pod" > "${NS_DIR}/pod-logs/${pod}-current.log" 2>/dev/null || echo "No current logs available" > "${NS_DIR}/pod-logs/${pod}-current.log"
        done
    else
        echo "    └─ No problematic pods found"
    fi

    echo "  ✅ Completed processing namespace: ${ns}"
done

# Step 3: Process cluster-wide (non-namespaced) resources - directly in root folder
echo "🌐 [$(date +%T)] Step 3: Processing cluster-wide resources..."

for resource in "${CLUSTER_RESOURCES[@]}"; do
    echo "  ► Processing cluster resource: ${resource}..."

    # Check if resources exist
    RESOURCE_COUNT=$(kubectl get "${resource}" --no-headers 2>/dev/null | wc -l)

    if [ "$RESOURCE_COUNT" -gt 0 ]; then
        echo "    └─ Found ${RESOURCE_COUNT} ${resource}(s)"

        # Create YAML output directly in cluster-dump root
        echo "    └─ Creating ${resource}.yaml..."
        if kubectl get "${resource}" -o yaml > "${CLUSTER_DUMP_DIR}/${resource}.yaml" 2>/dev/null; then
            echo "    └─ ✅ ${resource}.yaml created"
        else
            echo "    └─ ❌ Failed to create ${resource}.yaml"
        fi

        # Create describe output directly in cluster-dump root
        echo "    └─ Creating ${resource}-describe.txt..."
        if kubectl describe "${resource}" > "${CLUSTER_DUMP_DIR}/${resource}-describe.txt" 2>/dev/null; then
            echo "    └─ ✅ ${resource}-describe.txt created"
        else
            echo "    └─ ❌ Failed to create ${resource}-describe.txt"
        fi
    else
        echo "    └─ No ${resource} found"
        # Create empty files to indicate no resources exist
        touch "${CLUSTER_DUMP_DIR}/${resource}.yaml"
        echo "No ${resource} resources found at $(date)" > "${CLUSTER_DUMP_DIR}/${resource}-describe.txt"
    fi
done

# Step 4: Collect essential metrics and troubleshooting data
echo "📈 [$(date +%T)] Step 4: Collecting essential metrics..."

# Create metrics directory if it doesn't exist
mkdir -p "${CLUSTER_DUMP_DIR}/metrics"

# Resource usage metrics
echo "  ► Collecting resource usage metrics..."
kubectl top nodes > "${CLUSTER_DUMP_DIR}/metrics/nodes-usage.txt" 2>/dev/null || echo "Metrics server not available" > "${CLUSTER_DUMP_DIR}/metrics/nodes-usage.txt"
kubectl top pods -A > "${CLUSTER_DUMP_DIR}/metrics/pods-usage.txt" 2>/dev/null || echo "Metrics server not available" > "${CLUSTER_DUMP_DIR}/metrics/pods-usage.txt"

# Cluster version info
echo "  ► Collecting version information..."
kubectl version > "${CLUSTER_DUMP_DIR}/cluster-version.txt" 2>/dev/null

# Step 5: Clean up any duplicate or unwanted files
echo "🧹 [$(date +%T)] Step 5: Cleaning up duplicate and unwanted files..."

# Remove duplicate files if they exist
CLEANUP_FILES=(
    "${CLUSTER_DUMP_DIR}/nodes-detailed-describe.txt"
    "${CLUSTER_DUMP_DIR}/cluster/describe-outputs/nodes-describe.txt"
    "${CLUSTER_DUMP_DIR}/enhancement-summary.txt"
    "${CLUSTER_DUMP_DIR}/api-resources.txt"
    "${CLUSTER_DUMP_DIR}/all-events.txt"
    "${CLUSTER_DUMP_DIR}/component-status.txt"
    "${CLUSTER_DUMP_DIR}/component-status-describe.txt"
    "${CLUSTER_DUMP_DIR}/cluster-wide-yaml"
    "${CLUSTER_DUMP_DIR}/cluster-wide-describe"
)

for file in "${CLEANUP_FILES[@]}"; do
    if [ -f "$file" ] || [ -d "$file" ]; then
        echo "  🗑️  Removing: $(basename "$file")"
        rm -rf "$file"
    fi
done

# Step 6: Create/Update integrity checksums
echo "🔐 [$(date +%T)] Step 6: Creating integrity checksums..."
find "${CLUSTER_DUMP_DIR}" -type f -exec sha256sum {} \; > "${CLUSTER_DUMP_DIR}/integrity.checksums"

# Step 7: Final verification
echo "🔍 [$(date +%T)] Step 7: Verifying structure..."
MISSING_NS_COUNT=0
MISSING_CLUSTER_COUNT=0

# Check namespaced resources - directly in namespace folders
echo "  ► Checking namespaced resources..."
for ns in $NAMESPACES; do
    NS_DIR="${CLUSTER_DUMP_DIR}/${ns}"
    for resource in "${NAMESPACED_RESOURCES[@]}"; do
        if [ ! -f "${NS_DIR}/${resource}-describe.txt" ]; then
            echo "    ⚠️  Missing: ${ns}/${resource}-describe.txt"
            ((MISSING_NS_COUNT++))
        fi
        if [ ! -f "${NS_DIR}/${resource}.yaml" ]; then
            echo "    ⚠️  Missing: ${ns}/${resource}.yaml"
            ((MISSING_NS_COUNT++))
        fi
    done
done

# Check cluster-wide resources - directly in root
echo "  ► Checking cluster-wide resources..."
for resource in "${CLUSTER_RESOURCES[@]}"; do
    if [ ! -f "${CLUSTER_DUMP_DIR}/${resource}.yaml" ]; then
        echo "    ⚠️  Missing: ${resource}.yaml"
        ((MISSING_CLUSTER_COUNT++))
    fi
    if [ ! -f "${CLUSTER_DUMP_DIR}/${resource}-describe.txt" ]; then
        echo "    ⚠️  Missing: ${resource}-describe.txt"
        ((MISSING_CLUSTER_COUNT++))
    fi
done

if [ $MISSING_NS_COUNT -eq 0 ] && [ $MISSING_CLUSTER_COUNT -eq 0 ]; then
    echo "✅ All expected resource files created successfully"
else
    echo "⚠️  ${MISSING_NS_COUNT} namespaced resource files and ${MISSING_CLUSTER_COUNT} cluster-wide resource files were not created"
fi

# Final summary
echo
echo "============================================="
echo "🎉 Cluster Dump Enhancement Completed!"
echo "============================================="
echo "📁 Enhanced directory: ${CLUSTER_DUMP_DIR}"
echo "📊 Total size: $(du -sh "${CLUSTER_DUMP_DIR}" | cut -f1)"
echo "📋 Summary: ${TOTAL_NS} namespaces processed"
echo
echo "📂 Directory Structure:"
echo "  Root cluster resources: $(find "${CLUSTER_DUMP_DIR}" -maxdepth 1 -name "*-describe.txt" | wc -l) describe files"
echo "  Root cluster resources: $(find "${CLUSTER_DUMP_DIR}" -maxdepth 1 -name "*.yaml" -not -name "nodes.yaml" | wc -l) YAML files"
echo "  Namespace folders: ${TOTAL_NS}"
echo "  Total describe files: $(find "${CLUSTER_DUMP_DIR}" -name "*-describe.txt" | wc -l)"
echo "  Total YAML files: $(find "${CLUSTER_DUMP_DIR}" -name "*.yaml" | wc -l)"
echo
echo "📝 Structure created:"
echo "  • ${CLUSTER_DUMP_DIR}/<cluster-resource>.yaml"
echo "  • ${CLUSTER_DUMP_DIR}/<cluster-resource>-describe.txt"
echo "  • ${CLUSTER_DUMP_DIR}/<namespace>/<resource>.yaml"
echo "  • ${CLUSTER_DUMP_DIR}/<namespace>/<resource>-describe.txt"
echo "  • ${CLUSTER_DUMP_DIR}/metrics/"
echo "============================================="
