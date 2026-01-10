#!/bin/bash
# OpenEMR Dev Environment Deployment Script

set -e

echo "========================================="
echo "OpenEMR Dev Deployment to k3s"
echo "========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl is not installed${NC}"
    exit 1
fi

# Check if we can connect to k3s cluster
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Error: Cannot connect to k3s cluster${NC}"
    echo "Make sure your kubeconfig is set up correctly"
    exit 1
fi

echo -e "${GREEN}✓ kubectl is configured and cluster is accessible${NC}"
echo ""

# Check if MariaDB is accessible
echo "Checking MariaDB connectivity..."
if nc -zv -w 3 192.168.10.30 3306 2>&1 | grep -q succeeded; then
    echo -e "${GREEN}✓ MariaDB is accessible at 192.168.10.30:3306${NC}"
else
    echo -e "${YELLOW}⚠ Warning: Cannot connect to MariaDB at 192.168.10.30:3306${NC}"
    echo "Make sure the MariaDB LXC is created and running"
    echo "See: infrastructure/homelab/docs/mariadb-lxc-setup.md"
    echo ""
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi
echo ""

# Navigate to k8s directory
cd "$(dirname "$0")/../k8s"

echo "Step 1: Creating namespace..."
kubectl apply -f namespaces/openemr-dev.yaml
echo -e "${GREEN}✓ Namespace created${NC}"
echo ""

echo "Step 2: Deploying OpenEMR to dev environment..."
kubectl apply -k overlays/dev/
echo -e "${GREEN}✓ Deployment applied${NC}"
echo ""

echo "Step 3: Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/openemr -n openemr-dev || {
    echo -e "${RED}Deployment failed to become ready${NC}"
    echo "Check pod logs with: kubectl logs -n openemr-dev -l app=openemr"
    exit 1
}
echo -e "${GREEN}✓ Deployment is ready${NC}"
echo ""

echo "========================================="
echo "Deployment Status"
echo "========================================="
kubectl get all -n openemr-dev
echo ""

echo "========================================="
echo "Next Steps"
echo "========================================="
echo ""
echo "1. Test NodePort access:"
echo "   curl http://192.168.10.60:30090"
echo ""
echo "2. Configure pfSense HAProxy:"
echo "   - DNS Override: openemr-dev.trancloud.work → 192.168.10.1"
echo "   - Backend: openemr-dev-be → 192.168.10.60:30090"
echo "   - ACL: Host matches openemr-dev.trancloud.work"
echo "   - Action: Use backend openemr-dev-be"
echo ""
echo "3. Access OpenEMR:"
echo "   Internal: http://192.168.10.60:30090"
echo "   Public: https://openemr-dev.trancloud.work (after HAProxy setup)"
echo ""
echo "4. View logs:"
echo "   kubectl logs -n openemr-dev -l app=openemr -f"
echo ""
echo -e "${GREEN}Deployment completed successfully!${NC}"
