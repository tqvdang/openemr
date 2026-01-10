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

# Infisical configuration (LAN-only access)
INFISICAL_URL="${INFISICAL_URL:-https://secrets.trancloud.work}"
INFISICAL_TOKEN="${INFISICAL_TOKEN:-st.525f6347-38e5-437f-a16e-6fde8ab6d17e.721cb998a2dbfa386303a04b96605450.5f81fdc60df4955df3492ebc29711acb}"

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

# Pull secrets from Infisical
echo "Pulling secrets from Infisical..."
SECRETS_JSON=$(curl -s "$INFISICAL_URL/api/v3/secrets/raw" \
  -H "Authorization: Bearer $INFISICAL_TOKEN" 2>/dev/null)

if echo "$SECRETS_JSON" | grep -q '"secrets"'; then
    # Extract secret values using Python (more reliable than grep/sed for JSON)
    DB_ROOT_PASSWORD=$(echo "$SECRETS_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(next((s['secretValue'] for s in d['secrets'] if s['secretKey']=='DB_ROOT_PASSWORD'), ''))")
    DB_USER=$(echo "$SECRETS_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(next((s['secretValue'] for s in d['secrets'] if s['secretKey']=='DB_USER'), ''))")
    DB_PASSWORD=$(echo "$SECRETS_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(next((s['secretValue'] for s in d['secrets'] if s['secretKey']=='DB_PASSWORD'), ''))")
    OE_ADMIN_USER=$(echo "$SECRETS_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(next((s['secretValue'] for s in d['secrets'] if s['secretKey']=='OE_ADMIN_USER'), ''))")
    OE_ADMIN_PASSWORD=$(echo "$SECRETS_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(next((s['secretValue'] for s in d['secrets'] if s['secretKey']=='OE_ADMIN_PASSWORD'), ''))")

    echo -e "${GREEN}✓ Retrieved 5 secrets from Infisical${NC}"
else
    echo -e "${RED}Error: Failed to retrieve secrets from Infisical${NC}"
    echo "Response: $SECRETS_JSON"
    exit 1
fi
echo ""

# Navigate to k8s directory
cd "$(dirname "$0")/../k8s"

# Generate secrets.yaml from Infisical values
echo "Generating secrets.yaml from Infisical..."
cat > overlays/dev/secrets.yaml << EOF
apiVersion: v1
kind: Secret
metadata:
  name: openemr-secrets
  namespace: openemr-dev
type: Opaque
stringData:
  db_root_password: "$DB_ROOT_PASSWORD"
  db_user: "$DB_USER"
  db_password: "$DB_PASSWORD"
  oe_admin_user: "$OE_ADMIN_USER"
  oe_admin_password: "$OE_ADMIN_PASSWORD"
EOF
echo -e "${GREEN}✓ secrets.yaml generated${NC}"
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

# Cleanup: Remove generated secrets.yaml
rm -f overlays/dev/secrets.yaml
echo -e "${YELLOW}Note: secrets.yaml removed after deployment (pulled from Infisical)${NC}"
echo ""
echo -e "${GREEN}Deployment completed successfully!${NC}"
