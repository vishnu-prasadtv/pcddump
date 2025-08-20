#!/bin/bash

# Configuration

PARENT_DIR="/tmp/pcddump-$(date +%F_%H-%M-%S)"
PCD_DUMP_DIR="${PARENT_DIR}/pcddump"
mkdir -p "${PCD_DUMP_DIR}"

echo "🚀 PCD Cluster Dump Generation is in Progress..."
echo "📁 Working with directory: ${PCD_DUMP_DIR}"
echo "⏱️ Estimated time: 5-12 minutes"
echo "============================================="

# Verify cluster dump directory exists
if [ ! -d "${PCD_DUMP_DIR}" ]; then
    echo "❌ Cluster dump directory not found: ${PCD_DUMP_DIR}"
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
    # Treat namespaces as cluster-scoped
    namespaces
)

# Step 1: Get all namespaces
echo "📊 [$(date +%T)] Step 1: Discovering namespaces..."
NAMESPACES=$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)

if [ -z "$NAMESPACES" ]; then
    echo "⚠️  Warning: No namespaces found or kubectl access issue"
    exit 1
fi

# Always ensure default is processed, even if not listed
DEFAULT_INCLUDED=false
for ns in $NAMESPACES; do
    if [ "$ns" = "default" ]; then
        DEFAULT_INCLUDED=true
        break
    fi
done
if [ "$DEFAULT_INCLUDED" = "false" ]; then
    NAMESPACES="default $NAMESPACES"
fi

TOTAL_NS=$(echo $NAMESPACES | wc -w)
echo "📁 Found ${TOTAL_NS} namespaces to process (including 'default')"

# --- Collect ALL namespace describes and yaml in root as CLUSTER RESOURCES ---
echo "🔎 [$(date +%T)] Collecting all namespaces describe and yaml as cluster-scoped..."

# All namespace describe output in single file
if kubectl describe namespace > "${PCD_DUMP_DIR}/namespaces-describe.txt" 2>/dev/null; then
    echo "  ✅ All namespaces describe collected: ${PCD_DUMP_DIR}/namespaces-describe.txt"
else
    echo "No describe output for namespaces at $(date)" > "${PCD_DUMP_DIR}/namespaces-describe.txt"
    echo "  ❌ Failed to collect all namespaces describe"
fi

# All namespace yaml output in single file
if kubectl get namespace -o yaml > "${PCD_DUMP_DIR}/namespaces.yaml" 2>/dev/null; then
    echo "  ✅ All namespaces yaml collected: ${PCD_DUMP_DIR}/namespaces.yaml"
else
    echo "No yaml output for namespaces at $(date)" > "${PCD_DUMP_DIR}/namespaces.yaml"
    echo "  ❌ Failed to collect all namespaces yaml"
fi

# --- NEW: get ns in all common views ---
kubectl get ns > "${PCD_DUMP_DIR}/get-namespaces.txt" 2>/dev/null
kubectl get ns -o wide > "${PCD_DUMP_DIR}/get-owide-namespaces.txt" 2>/dev/null
kubectl get ns --show-labels > "${PCD_DUMP_DIR}/get-show-labels-namespaces.txt" 2>/dev/null

# Step 2: Process namespaced resources
echo "🔧 [$(date +%T)] Step 2: Processing namespaced resources..."

CURRENT_NS=0
for ns in $NAMESPACES; do
    ((CURRENT_NS++))
    echo "📂 [$(date +%T)] Processing namespace: ${ns} (${CURRENT_NS}/${TOTAL_NS})"

    NS_DIR="${PCD_DUMP_DIR}/${ns}"

    if [ ! -d "${NS_DIR}" ]; then
        echo "  📁 Creating namespace directory: ${NS_DIR}"
        mkdir -p "${NS_DIR}"
    fi

    echo "  📁 Using directory: ${NS_DIR}"

    # Process each namespaced resource type
    for resource in "${NAMESPACED_RESOURCES[@]}"; do
        echo "  ► Processing ${resource}..."

        RESOURCE_COUNT=$(kubectl get -n "${ns}" "${resource}" --no-headers 2>/dev/null | wc -l)

        if [ "$RESOURCE_COUNT" -gt 0 ]; then
            echo "    └─ Found ${RESOURCE_COUNT} ${resource}(s)"

            echo "    └─ Creating ${resource}.yaml..."
            kubectl get -n "${ns}" "${resource}" -o yaml > "${NS_DIR}/${resource}.yaml" 2>/dev/null

            echo "    └─ Creating ${resource}-describe.txt..."
            kubectl describe -n "${ns}" "${resource}" > "${NS_DIR}/${resource}-describe.txt" 2>/dev/null

            # NEW: Additional get commands
            kubectl get "${resource}" -n "${ns}" > "${NS_DIR}/get-${resource}.txt" 2>/dev/null
            kubectl get "${resource}" -n "${ns}" -o wide > "${NS_DIR}/get-owide-${resource}.txt" 2>/dev/null
            kubectl get "${resource}" -n "${ns}" --show-labels > "${NS_DIR}/get-show-labels-${resource}.txt" 2>/dev/null
        else
            echo "    └─ No ${resource} found in namespace ${ns}"
            touch "${NS_DIR}/${resource}.yaml"
            echo "No ${resource} resources found in namespace ${ns} at $(date)" > "${NS_DIR}/${resource}-describe.txt"
            # Also create empty files for new get outputs
            touch "${NS_DIR}/get-${resource}.txt"
            touch "${NS_DIR}/get-owide-${resource}.txt"
            touch "${NS_DIR}/get-show-labels-${resource}.txt"
        fi
    done

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

    echo "  ► Collecting logs for all pods in namespace ${ns}..."
    ALL_PODS=$(kubectl get pods -n "${ns}" -o custom-columns=":metadata.name" --no-headers 2>/dev/null | grep -v "^$")
    for pod in $ALL_PODS; do
        POD_LOG_DIR="${NS_DIR}/${pod}"
        mkdir -p "${POD_LOG_DIR}"
        echo "      └─ Saving logs for pod: ${pod} to ${POD_LOG_DIR}/logs.txt"
        kubectl logs -n "${ns}" "${pod}" > "${POD_LOG_DIR}/logs.txt" 2>/dev/null || echo "No logs available" > "${POD_LOG_DIR}/logs.txt"
    done

    echo "  ✅ Completed processing namespace: ${ns}"
done

echo "🌐 [$(date +%T)] Step 3: Processing cluster-wide resources..."

for resource in "${CLUSTER_RESOURCES[@]}"; do
    echo "  ► Processing cluster resource: ${resource}..."

    # Special handling for namespaces (already collected above)
    if [ "${resource}" == "namespaces" ]; then
        continue
    fi

    RESOURCE_COUNT=$(kubectl get "${resource}" --no-headers 2>/dev/null | wc -l)

    if [ "$RESOURCE_COUNT" -gt 0 ]; then
        echo "    └─ Found ${RESOURCE_COUNT} ${resource}(s)"

        echo "    └─ Creating ${resource}.yaml..."
        kubectl get "${resource}" -o yaml > "${PCD_DUMP_DIR}/${resource}.yaml" 2>/dev/null

        echo "    └─ Creating ${resource}-describe.txt..."
        kubectl describe "${resource}" > "${PCD_DUMP_DIR}/${resource}-describe.txt" 2>/dev/null

        # NEW: Additional get commands
        kubectl get "${resource}" > "${PCD_DUMP_DIR}/get-${resource}.txt" 2>/dev/null
        kubectl get "${resource}" -o wide > "${PCD_DUMP_DIR}/get-owide-${resource}.txt" 2>/dev/null
        kubectl get "${resource}" --show-labels > "${PCD_DUMP_DIR}/get-show-labels-${resource}.txt" 2>/dev/null
    else
        echo "    └─ No ${resource} found"
        touch "${PCD_DUMP_DIR}/${resource}.yaml"
        echo "No ${resource} resources found at $(date)" > "${PCD_DUMP_DIR}/${resource}-describe.txt"
        # Also create empty files for new get outputs
        touch "${PCD_DUMP_DIR}/get-${resource}.txt"
        touch "${PCD_DUMP_DIR}/get-owide-${resource}.txt"
        touch "${PCD_DUMP_DIR}/get-show-labels-${resource}.txt"
    fi
done

# --- NEW FUNCTIONALITY: Collect all events across all namespaces ---
echo "📑 [$(date +%T)] Collecting all events across all namespaces..."
kubectl get events -A > "${PCD_DUMP_DIR}/get-all-events.txt" 2>/dev/null
echo "  ✅ All events collected: ${PCD_DUMP_DIR}/get-all-events.txt"

echo "📈 [$(date +%T)] Step 4: Collecting essential metrics..."
mkdir -p "${PCD_DUMP_DIR}/metrics"

echo "  ► Collecting resource usage metrics..."
kubectl top nodes > "${PCD_DUMP_DIR}/metrics/nodes-usage.txt" 2>/dev/null || echo "Metrics server not available" > "${PCD_DUMP_DIR}/metrics/nodes-usage.txt"
kubectl top pods -A > "${PCD_DUMP_DIR}/metrics/pods-usage.txt" 2>/dev/null || echo "Metrics server not available" > "${PCD_DUMP_DIR}/metrics/pods-usage.txt"

echo "  ► Collecting version information..."
kubectl version > "${PCD_DUMP_DIR}/cluster-version.txt" 2>/dev/null

echo "🧹 [$(date +%T)] Step 5: Cleaning up duplicate and unwanted files..."

CLEANUP_FILES=(
    "${PCD_DUMP_DIR}/nodes-detailed-describe.txt"
    "${PCD_DUMP_DIR}/cluster/describe-outputs/nodes-describe.txt"
    "${PCD_DUMP_DIR}/enhancement-summary.txt"
    "${PCD_DUMP_DIR}/api-resources.txt"
    "${PCD_DUMP_DIR}/all-events.txt"
    "${PCD_DUMP_DIR}/component-status.txt"
    "${PCD_DUMP_DIR}/component-status-describe.txt"
    "${PCD_DUMP_DIR}/cluster-wide-yaml"
    "${PCD_DUMP_DIR}/cluster-wide-describe"
)

for file in "${CLEANUP_FILES[@]}"; do
    if [ -f "$file" ] || [ -d "$file" ]; then
        echo "  🗑️  Removing: $(basename "$file")"
        rm -rf "$file"
    fi
done

echo "🔐 [$(date +%T)] Step 6: Creating integrity checksums..."
find "${PCD_DUMP_DIR}" -type f -exec sha256sum {} \; > "${PCD_DUMP_DIR}/integrity.checksums"

echo "🔍 [$(date +%T)] Step 7: Verifying structure..."
MISSING_NS_COUNT=0
MISSING_CLUSTER_COUNT=0

echo "  ► Checking namespaced resources..."
for ns in $NAMESPACES; do
    NS_DIR="${PCD_DUMP_DIR}/${ns}"
    for resource in "${NAMESPACED_RESOURCES[@]}"; do
        if [ ! -f "${NS_DIR}/${resource}-describe.txt" ]; then
            echo "    ⚠️  Missing: ${ns}/${resource}-describe.txt"
            ((MISSING_NS_COUNT++))
        fi
        if [ ! -f "${NS_DIR}/${resource}.yaml" ]; then
            echo "    ⚠️  Missing: ${ns}/${resource}.yaml"
            ((MISSING_NS_COUNT++))
        fi
        if [ ! -f "${NS_DIR}/get-${resource}.txt" ]; then
            echo "    ⚠️  Missing: ${ns}/get-${resource}.txt"
            ((MISSING_NS_COUNT++))
        fi
        if [ ! -f "${NS_DIR}/get-owide-${resource}.txt" ]; then
            echo "    ⚠️  Missing: ${ns}/get-owide-${resource}.txt"
            ((MISSING_NS_COUNT++))
        fi
        if [ ! -f "${NS_DIR}/get-show-labels-${resource}.txt" ]; then
            echo "    ⚠️  Missing: ${ns}/get-show-labels-${resource}.txt"
            ((MISSING_NS_COUNT++))
        fi
    done
done

echo "  ► Checking cluster-wide resources..."
for resource in "${CLUSTER_RESOURCES[@]}"; do
    if [ "${resource}" == "namespaces" ]; then
        continue
    fi
    if [ ! -f "${PCD_DUMP_DIR}/${resource}.yaml" ]; then
        echo "    ⚠️  Missing: ${resource}.yaml"
        ((MISSING_CLUSTER_COUNT++))
    fi
    if [ ! -f "${PCD_DUMP_DIR}/${resource}-describe.txt" ]; then
        echo "    ⚠️  Missing: ${resource}-describe.txt"
        ((MISSING_CLUSTER_COUNT++))
    fi
    if [ ! -f "${PCD_DUMP_DIR}/get-${resource}.txt" ]; then
        echo "    ⚠️  Missing: get-${resource}.txt"
        ((MISSING_CLUSTER_COUNT++))
    fi
    if [ ! -f "${PCD_DUMP_DIR}/get-owide-${resource}.txt" ]; then
        echo "    ⚠️  Missing: get-owide-${resource}.txt"
        ((MISSING_CLUSTER_COUNT++))
    fi
    if [ ! -f "${PCD_DUMP_DIR}/get-show-labels-${resource}.txt" ]; then
        echo "    ⚠️  Missing: get-show-labels-${resource}.txt"
        ((MISSING_CLUSTER_COUNT++))
    fi
done

if [ ! -f "${PCD_DUMP_DIR}/namespaces-describe.txt" ]; then
    echo "    ⚠️  Missing: namespaces-describe.txt"
    ((MISSING_CLUSTER_COUNT++))
fi
if [ ! -f "${PCD_DUMP_DIR}/namespaces.yaml" ]; then
    echo "    ⚠️  Missing: namespaces.yaml"
    ((MISSING_CLUSTER_COUNT++))
fi
if [ ! -f "${PCD_DUMP_DIR}/get-all-events.txt" ]; then
    echo "    ⚠️  Missing: get-all-events.txt"
    ((MISSING_CLUSTER_COUNT++))
fi

if [ $MISSING_NS_COUNT -eq 0 ] && [ $MISSING_CLUSTER_COUNT -eq 0 ]; then
    echo "✅ All expected resource files created successfully"
else
    echo "⚠️  ${MISSING_NS_COUNT} namespaced resource files and ${MISSING_CLUSTER_COUNT} cluster-wide resource files were not created"
fi

cd /tmp
tar -czvf $(basename ${PARENT_DIR}).tar.gz ${PARENT_DIR}

echo
echo "============================================="
echo "🎉 Your PCD Cluster Dump is ready!"
echo "============================================="
echo "📁 PCD Dump directory: ${PCD_DUMP_DIR}"
echo "📁 Archived directory: ${PARENT_DIR}.tar.gz"
echo "📊 Total size: $(du -sh "${PCD_DUMP_DIR}" | cut -f1)"
echo "📋 Summary: ${TOTAL_NS} namespaces processed"
echo
echo "📂 Directory Structure:"
echo "  Root cluster resources: $(find "${PCD_DUMP_DIR}" -maxdepth 1 -name "*-describe.txt" | wc -l) describe files"
echo "  Root cluster resources: $(find "${PCD_DUMP_DIR}" -maxdepth 1 -name "*.yaml" -not -name "nodes.yaml" | wc -l) YAML files"
echo "  Namespace folders: ${TOTAL_NS}"
echo "  Total describe files: $(find "${PCD_DUMP_DIR}" -name "*-describe.txt" | wc -l)"
echo "  Total YAML files: $(find "${PCD_DUMP_DIR}" -name "*.yaml" | wc -l)"
echo
echo "📝 Structure created:"
echo "  • ${PCD_DUMP_DIR}/namespaces-describe.txt"
echo "  • ${PCD_DUMP_DIR}/namespaces.yaml"
echo "  • ${PCD_DUMP_DIR}/get-namespaces.txt"
echo "  • ${PCD_DUMP_DIR}/get-owide-namespaces.txt"
echo "  • ${PCD_DUMP_DIR}/get-show-labels-namespaces.txt"
echo "  • ${PCD_DUMP_DIR}/get-all-events.txt"
echo "  • ${PCD_DUMP_DIR}/<cluster-resource>.yaml"
echo "  • ${PCD_DUMP_DIR}/<cluster-resource>-describe.txt"
echo "  • ${PCD_DUMP_DIR}/get-<cluster-resource>.txt"
echo "  • ${PCD_DUMP_DIR}/get-owide-<cluster-resource>.txt"
echo "  • ${PCD_DUMP_DIR}/get-show-labels-<cluster-resource>.txt"
echo "  • ${PCD_DUMP_DIR}/<namespace>/<resource>.yaml"
echo "  • ${PCD_DUMP_DIR}/<namespace>/<resource>-describe.txt"
echo "  • ${PCD_DUMP_DIR}/<namespace>/get-<resource>.txt"
echo "  • ${PCD_DUMP_DIR}/<namespace>/get-owide-<resource>.txt"
echo "  • ${PCD_DUMP_DIR}/<namespace>/get-show-labels-<resource>.txt"
echo "  • ${PCD_DUMP_DIR}/<namespace>/<pod-name>/logs.txt"
echo "  • ${PCD_DUMP_DIR}/metrics/"
echo "============================================="
