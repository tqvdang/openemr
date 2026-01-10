#!/bin/bash
#
# OpenEMR Deployment Validation Script
# Tests all components of the OpenEMR homelab deployment
#
# Usage: ./validate-deployment.sh [OPTIONS]
#
# Options:
#   -h, --help      Show this help message
#   -v, --verbose   Enable verbose output
#   -q, --quick     Skip slow tests (SSL certificate details, extended timeouts)
#   --skip-db       Skip database tests
#   --skip-k8s      Skip Kubernetes tests
#   --skip-haproxy  Skip HAProxy/external access tests
#

set -o pipefail

# =============================================================================
# Configuration
# =============================================================================

# MariaDB LXC settings
DB_HOST="192.168.10.30"
DB_PORT="3306"
DB_USER="openemr_dev"
DB_NAME="openemr_dev"
DB_PASS="${DB_PASSWORD}"

# k3s cluster settings
K3S_MASTER="192.168.10.60"
K3S_NAMESPACE="openemr-dev"
K3S_NODEPORT="30090"

# HAProxy / Public access settings
DOMAIN="openemr-dev.trancloud.work"
HAPROXY_IP="192.168.10.1"

# Timeouts
TIMEOUT_SHORT=5
TIMEOUT_LONG=30

# =============================================================================
# Colors and formatting
# =============================================================================

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# =============================================================================
# Counters and state
# =============================================================================

TESTS_PASSED=0
TESTS_FAILED=0
TESTS_WARNED=0
TESTS_SKIPPED=0

VERBOSE=false
QUICK_MODE=false
SKIP_DB=false
SKIP_K8S=false
SKIP_HAPROXY=false

# Store results for summary
declare -a RESULTS
declare -a FAILURES
declare -a WARNINGS

# =============================================================================
# Helper functions
# =============================================================================

usage() {
    cat << EOF
OpenEMR Deployment Validation Script

Usage: $(basename "$0") [OPTIONS]

This script validates all components of the OpenEMR homelab deployment including:
  - MariaDB LXC connectivity and authentication
  - k3s cluster accessibility and pod status
  - NodePort accessibility
  - DNS resolution
  - HAProxy routing
  - SSL certificate validity

Options:
  -h, --help      Show this help message and exit
  -v, --verbose   Enable verbose output with additional details
  -q, --quick     Skip slow tests (SSL cert details, extended timeouts)
  --skip-db       Skip database connectivity tests
  --skip-k8s      Skip Kubernetes cluster tests
  --skip-haproxy  Skip HAProxy and external access tests

Environment:
  MariaDB:     ${DB_HOST}:${DB_PORT}
  k3s Master:  ${K3S_MASTER}
  Namespace:   ${K3S_NAMESPACE}
  NodePort:    ${K3S_NODEPORT}
  Domain:      ${DOMAIN}
  HAProxy IP:  ${HAPROXY_IP}

Examples:
  $(basename "$0")              # Run all tests
  $(basename "$0") --verbose    # Run all tests with verbose output
  $(basename "$0") --quick      # Run quick tests only
  $(basename "$0") --skip-db    # Skip database tests

Exit codes:
  0 - All tests passed
  1 - One or more tests failed
  2 - Invalid arguments

EOF
    exit 0
}

print_header() {
    echo ""
    echo -e "${BLUE}==========================================${NC}"
    echo -e "${WHITE}${BOLD}$1${NC}"
    echo -e "${BLUE}==========================================${NC}"
    echo ""
}

print_subheader() {
    echo ""
    echo -e "${CYAN}--- $1 ---${NC}"
    echo ""
}

print_pass() {
    local message="$1"
    echo -e "  ${GREEN}[PASS]${NC} $message"
    ((TESTS_PASSED++))
    RESULTS+=("PASS: $message")
}

print_fail() {
    local message="$1"
    local remediation="$2"
    echo -e "  ${RED}[FAIL]${NC} $message"
    if [[ -n "$remediation" ]]; then
        echo -e "         ${YELLOW}Remediation:${NC} $remediation"
    fi
    ((TESTS_FAILED++))
    RESULTS+=("FAIL: $message")
    FAILURES+=("$message|$remediation")
}

print_warn() {
    local message="$1"
    local note="$2"
    echo -e "  ${YELLOW}[WARN]${NC} $message"
    if [[ -n "$note" ]]; then
        echo -e "         ${YELLOW}Note:${NC} $note"
    fi
    ((TESTS_WARNED++))
    RESULTS+=("WARN: $message")
    WARNINGS+=("$message|$note")
}

print_skip() {
    local message="$1"
    echo -e "  ${CYAN}[SKIP]${NC} $message"
    ((TESTS_SKIPPED++))
    RESULTS+=("SKIP: $message")
}

print_info() {
    if [[ "$VERBOSE" == true ]]; then
        echo -e "  ${CYAN}[INFO]${NC} $1"
    fi
}

check_command() {
    local cmd="$1"
    local package="$2"
    if ! command -v "$cmd" &> /dev/null; then
        print_fail "$cmd command not found" "Install with: apt install $package (or equivalent)"
        return 1
    fi
    return 0
}

# =============================================================================
# Prerequisite checks
# =============================================================================

check_prerequisites() {
    print_header "Checking Prerequisites"

    local all_present=true

    # Check for required commands
    if check_command "nc" "netcat-openbsd"; then
        print_pass "netcat (nc) is installed"
    else
        all_present=false
    fi

    if check_command "curl" "curl"; then
        print_pass "curl is installed"
    else
        all_present=false
    fi

    if check_command "nslookup" "dnsutils"; then
        print_pass "nslookup is installed"
    else
        all_present=false
    fi

    if check_command "openssl" "openssl"; then
        print_pass "openssl is installed"
    else
        all_present=false
    fi

    if check_command "kubectl" "kubectl"; then
        print_pass "kubectl is installed"
    else
        all_present=false
    fi

    # MySQL client is optional but useful
    if command -v mysql &> /dev/null; then
        print_pass "mysql client is installed"
    else
        print_warn "mysql client not installed" "Install for enhanced database testing: apt install mariadb-client"
    fi

    if [[ "$all_present" == false ]]; then
        echo ""
        echo -e "${RED}Some required tools are missing. Please install them and try again.${NC}"
        exit 2
    fi
}

# =============================================================================
# Database Tests
# =============================================================================

test_database() {
    if [[ "$SKIP_DB" == true ]]; then
        print_header "Database Tests (Skipped)"
        print_skip "Database tests skipped by user request"
        return
    fi

    print_header "Database Tests (MariaDB LXC)"

    print_subheader "Network Connectivity"

    # Test TCP connectivity to MariaDB port
    print_info "Testing TCP connection to ${DB_HOST}:${DB_PORT}..."
    if nc -zv -w "$TIMEOUT_SHORT" "$DB_HOST" "$DB_PORT" &> /dev/null; then
        print_pass "MariaDB port ${DB_PORT} is accessible at ${DB_HOST}"
    else
        print_fail "Cannot connect to MariaDB at ${DB_HOST}:${DB_PORT}" \
            "Check if LXC container (CT 102) is running: pct status 102"
        return
    fi

    # Test if MariaDB is accepting connections (not just port open)
    print_info "Testing MariaDB protocol response..."
    local mysql_response
    mysql_response=$(echo "quit" | timeout "$TIMEOUT_SHORT" nc "$DB_HOST" "$DB_PORT" 2>/dev/null | head -c 100 || true)
    if [[ -n "$mysql_response" ]]; then
        print_pass "MariaDB is responding to connections"
    else
        print_warn "MariaDB port is open but no protocol response" \
            "MariaDB service may be starting up or have issues"
    fi

    print_subheader "Authentication"

    # Test database authentication with mysql client if available
    if command -v mysql &> /dev/null; then
        print_info "Testing database authentication..."
        if mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" -e "SELECT 1" "$DB_NAME" &> /dev/null; then
            print_pass "Database authentication successful (user: ${DB_USER})"

            # Check database exists
            print_info "Checking database exists..."
            if mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" -e "USE ${DB_NAME}; SELECT DATABASE();" &> /dev/null; then
                print_pass "Database '${DB_NAME}' exists and is accessible"
            else
                print_fail "Database '${DB_NAME}' does not exist or is not accessible" \
                    "Create database: CREATE DATABASE ${DB_NAME} CHARACTER SET utf8mb4;"
            fi

            # Check for OpenEMR tables (if database is initialized)
            print_info "Checking for OpenEMR tables..."
            local table_count
            table_count=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${DB_NAME}';" 2>/dev/null || echo "0")
            if [[ "$table_count" -gt 0 ]]; then
                print_pass "OpenEMR database initialized (${table_count} tables found)"
            else
                print_warn "OpenEMR database is empty" \
                    "Database will be initialized on first OpenEMR access"
            fi
        else
            print_fail "Database authentication failed (user: ${DB_USER})" \
                "Check user credentials or create user: GRANT ALL ON ${DB_NAME}.* TO '${DB_USER}'@'%' IDENTIFIED BY 'password';"
        fi
    else
        print_warn "Cannot test database authentication (mysql client not installed)" \
            "Install mariadb-client for full database testing"
    fi

    print_subheader "MariaDB Configuration"

    # Check if remote connections are enabled
    if command -v mysql &> /dev/null; then
        print_info "Checking bind-address configuration..."
        local bind_check
        bind_check=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" -N -e "SHOW VARIABLES LIKE 'bind_address';" 2>/dev/null | awk '{print $2}' || echo "unknown")
        if [[ "$bind_check" == "0.0.0.0" ]] || [[ "$bind_check" == "*" ]]; then
            print_pass "MariaDB accepting remote connections (bind_address: ${bind_check})"
        elif [[ "$bind_check" == "127.0.0.1" ]] || [[ "$bind_check" == "localhost" ]]; then
            print_fail "MariaDB only accepting local connections" \
                "Edit /etc/mysql/mariadb.conf.d/50-server.cnf and set bind-address = 0.0.0.0"
        else
            print_info "bind_address: ${bind_check}"
        fi
    fi
}

# =============================================================================
# Kubernetes Tests
# =============================================================================

test_kubernetes() {
    if [[ "$SKIP_K8S" == true ]]; then
        print_header "Kubernetes Tests (Skipped)"
        print_skip "Kubernetes tests skipped by user request"
        return
    fi

    print_header "Kubernetes Tests (k3s Cluster)"

    print_subheader "Cluster Connectivity"

    # Test kubectl connectivity
    print_info "Testing kubectl connectivity..."
    if kubectl cluster-info &> /dev/null; then
        print_pass "kubectl can connect to k3s cluster"

        # Get cluster info
        if [[ "$VERBOSE" == true ]]; then
            local cluster_info
            cluster_info=$(kubectl cluster-info 2>/dev/null | head -2)
            echo -e "         ${CYAN}${cluster_info}${NC}"
        fi
    else
        print_fail "Cannot connect to k3s cluster" \
            "Check kubeconfig: export KUBECONFIG=/path/to/kubeconfig or run on k3s master"
        return
    fi

    # Test k3s node status
    print_info "Checking node status..."
    local node_status
    node_status=$(kubectl get nodes --no-headers 2>/dev/null | awk '{print $1 ":" $2}')
    if [[ -n "$node_status" ]]; then
        local all_ready=true
        while IFS=':' read -r node status; do
            if [[ "$status" == "Ready" ]]; then
                print_pass "Node '${node}' is Ready"
            else
                print_fail "Node '${node}' is ${status}" \
                    "Check node with: kubectl describe node ${node}"
                all_ready=false
            fi
        done <<< "$node_status"
    else
        print_fail "No nodes found in cluster" \
            "k3s cluster may not be properly initialized"
    fi

    print_subheader "Namespace and Deployment"

    # Check namespace exists
    print_info "Checking namespace ${K3S_NAMESPACE}..."
    if kubectl get namespace "$K3S_NAMESPACE" &> /dev/null; then
        print_pass "Namespace '${K3S_NAMESPACE}' exists"
    else
        print_fail "Namespace '${K3S_NAMESPACE}' does not exist" \
            "Create with: kubectl apply -f infrastructure/homelab/k8s/namespaces/openemr-dev.yaml"
        return
    fi

    # Check deployment status
    print_info "Checking OpenEMR deployment..."
    local deployment_status
    deployment_status=$(kubectl get deployment openemr -n "$K3S_NAMESPACE" --no-headers 2>/dev/null | awk '{print $2}')
    if [[ -n "$deployment_status" ]]; then
        local ready=$(echo "$deployment_status" | cut -d'/' -f1)
        local desired=$(echo "$deployment_status" | cut -d'/' -f2)
        if [[ "$ready" == "$desired" ]] && [[ "$ready" -gt 0 ]]; then
            print_pass "OpenEMR deployment is ready (${ready}/${desired} replicas)"
        else
            print_fail "OpenEMR deployment not fully ready (${ready}/${desired} replicas)" \
                "Check deployment: kubectl describe deployment openemr -n ${K3S_NAMESPACE}"
        fi
    else
        print_fail "OpenEMR deployment not found" \
            "Deploy with: kubectl apply -k infrastructure/homelab/k8s/overlays/dev/"
        return
    fi

    print_subheader "Pod Status"

    # Check pod status
    print_info "Checking pod status..."
    local pod_info
    pod_info=$(kubectl get pods -n "$K3S_NAMESPACE" -l app=openemr --no-headers 2>/dev/null)
    if [[ -n "$pod_info" ]]; then
        while read -r pod_line; do
            local pod_name=$(echo "$pod_line" | awk '{print $1}')
            local pod_ready=$(echo "$pod_line" | awk '{print $2}')
            local pod_status=$(echo "$pod_line" | awk '{print $3}')
            local pod_restarts=$(echo "$pod_line" | awk '{print $4}')

            if [[ "$pod_status" == "Running" ]]; then
                print_pass "Pod '${pod_name}' is Running (ready: ${pod_ready}, restarts: ${pod_restarts})"

                if [[ "$pod_restarts" -gt 5 ]]; then
                    print_warn "Pod has high restart count (${pod_restarts})" \
                        "Check logs: kubectl logs -n ${K3S_NAMESPACE} ${pod_name}"
                fi
            elif [[ "$pod_status" == "Pending" ]]; then
                print_fail "Pod '${pod_name}' is Pending" \
                    "Check events: kubectl describe pod -n ${K3S_NAMESPACE} ${pod_name}"
            elif [[ "$pod_status" == "CrashLoopBackOff" ]]; then
                print_fail "Pod '${pod_name}' is in CrashLoopBackOff" \
                    "Check logs: kubectl logs -n ${K3S_NAMESPACE} ${pod_name} --previous"
            elif [[ "$pod_status" == "ImagePullBackOff" ]] || [[ "$pod_status" == "ErrImagePull" ]]; then
                print_fail "Pod '${pod_name}' cannot pull image (${pod_status})" \
                    "Check image name and registry access"
            else
                print_warn "Pod '${pod_name}' is in unexpected state: ${pod_status}" \
                    "Investigate with: kubectl describe pod -n ${K3S_NAMESPACE} ${pod_name}"
            fi
        done <<< "$pod_info"
    else
        print_fail "No OpenEMR pods found" \
            "Check deployment status and events"
    fi

    print_subheader "Service and NodePort"

    # Check service exists
    print_info "Checking NodePort service..."
    local service_info
    service_info=$(kubectl get service openemr-nodeport -n "$K3S_NAMESPACE" --no-headers 2>/dev/null)
    if [[ -n "$service_info" ]]; then
        local svc_type=$(echo "$service_info" | awk '{print $2}')
        local svc_ports=$(echo "$service_info" | awk '{print $5}')
        if [[ "$svc_type" == "NodePort" ]]; then
            print_pass "NodePort service exists (ports: ${svc_ports})"
        else
            print_warn "Service type is ${svc_type}, expected NodePort" \
                "Check service configuration"
        fi
    else
        print_fail "NodePort service 'openemr-nodeport' not found" \
            "Apply with: kubectl apply -f infrastructure/homelab/k8s/overlays/dev/nodeport-service.yaml"
    fi

    # Test NodePort accessibility
    print_info "Testing NodePort accessibility..."
    local nodeport_url="http://${K3S_MASTER}:${K3S_NODEPORT}"
    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout "$TIMEOUT_SHORT" "$nodeport_url" 2>/dev/null || echo "000")

    if [[ "$http_code" == "200" ]] || [[ "$http_code" == "302" ]] || [[ "$http_code" == "301" ]]; then
        print_pass "NodePort is accessible at ${nodeport_url} (HTTP ${http_code})"
    elif [[ "$http_code" == "000" ]]; then
        print_fail "Cannot connect to NodePort at ${nodeport_url}" \
            "Check if pod is running and service is configured correctly"
    else
        print_warn "NodePort returned HTTP ${http_code} at ${nodeport_url}" \
            "This may be expected during initial setup"
    fi
}

# =============================================================================
# HAProxy and External Access Tests
# =============================================================================

test_haproxy() {
    if [[ "$SKIP_HAPROXY" == true ]]; then
        print_header "HAProxy / External Access Tests (Skipped)"
        print_skip "HAProxy tests skipped by user request"
        return
    fi

    print_header "HAProxy / External Access Tests"

    print_subheader "DNS Resolution"

    # Test DNS resolution
    print_info "Testing DNS resolution for ${DOMAIN}..."
    local dns_result
    dns_result=$(nslookup "$DOMAIN" 2>/dev/null | grep -A1 "Name:" | tail -1 | awk '{print $2}' || echo "")

    if [[ -z "$dns_result" ]]; then
        # Try alternative parsing
        dns_result=$(nslookup "$DOMAIN" 2>/dev/null | grep "Address:" | tail -1 | awk '{print $2}' || echo "")
    fi

    if [[ -n "$dns_result" ]]; then
        if [[ "$dns_result" == "$HAPROXY_IP" ]]; then
            print_pass "DNS resolves ${DOMAIN} to ${dns_result} (correct)"
        else
            print_warn "DNS resolves ${DOMAIN} to ${dns_result} (expected ${HAPROXY_IP})" \
                "This may still work if using Cloudflare proxy"
        fi
    else
        print_fail "DNS resolution failed for ${DOMAIN}" \
            "Add DNS override in pfSense: Services -> DNS Resolver -> Host Overrides"
    fi

    # Test DNS against specific resolver
    print_info "Testing DNS against pfSense (${HAPROXY_IP})..."
    local pfsense_dns
    pfsense_dns=$(nslookup "$DOMAIN" "$HAPROXY_IP" 2>/dev/null | grep "Address:" | tail -1 | awk '{print $2}' || echo "")

    if [[ -n "$pfsense_dns" ]] && [[ "$pfsense_dns" != "$HAPROXY_IP" ]] && [[ "$pfsense_dns" != "#53" ]]; then
        print_pass "pfSense DNS resolves ${DOMAIN} to ${pfsense_dns}"
    elif [[ "$pfsense_dns" == "$HAPROXY_IP" ]]; then
        print_pass "pfSense DNS resolves ${DOMAIN} to ${pfsense_dns}"
    else
        print_warn "Could not verify pfSense DNS resolution" \
            "Verify DNS override is configured in pfSense"
    fi

    print_subheader "HAProxy Routing"

    # Test HTTPS connectivity
    print_info "Testing HTTPS connectivity to ${DOMAIN}..."
    local https_url="https://${DOMAIN}"
    local https_code
    https_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout "$TIMEOUT_LONG" -k "$https_url" 2>/dev/null || echo "000")

    if [[ "$https_code" == "200" ]]; then
        print_pass "HTTPS is accessible at ${https_url} (HTTP 200)"
    elif [[ "$https_code" == "302" ]] || [[ "$https_code" == "301" ]]; then
        print_pass "HTTPS is accessible at ${https_url} (HTTP ${https_code} redirect)"
    elif [[ "$https_code" == "503" ]]; then
        print_fail "HAProxy returned 503 Service Unavailable" \
            "Check HAProxy backend status and pod health in pfSense: Services -> HAProxy -> Stats"
    elif [[ "$https_code" == "000" ]]; then
        print_fail "Cannot connect to ${https_url}" \
            "Check HAProxy frontend configuration and ACL in pfSense"
    else
        print_warn "HTTPS returned HTTP ${https_code} at ${https_url}" \
            "This may indicate configuration issues"
    fi

    # Test HTTP redirect (optional)
    print_info "Testing HTTP redirect..."
    local http_url="http://${DOMAIN}"
    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout "$TIMEOUT_SHORT" "$http_url" 2>/dev/null || echo "000")

    if [[ "$http_code" == "301" ]] || [[ "$http_code" == "302" ]]; then
        print_pass "HTTP redirects to HTTPS (HTTP ${http_code})"
    elif [[ "$http_code" == "000" ]]; then
        print_info "HTTP port 80 not accessible (may be expected if no redirect configured)"
    else
        print_info "HTTP returned ${http_code} (may be expected based on configuration)"
    fi

    print_subheader "SSL Certificate"

    # Test SSL certificate
    print_info "Checking SSL certificate..."
    local cert_info
    cert_info=$(echo | timeout "$TIMEOUT_SHORT" openssl s_client -connect "${DOMAIN}:443" -servername "$DOMAIN" 2>/dev/null)

    if [[ -n "$cert_info" ]]; then
        # Check if certificate is valid
        local verify_result
        verify_result=$(echo "$cert_info" | grep "Verify return code" | awk -F': ' '{print $2}')

        if [[ "$verify_result" == "0 (ok)" ]]; then
            print_pass "SSL certificate is valid"
        elif [[ -n "$verify_result" ]]; then
            print_warn "SSL certificate verification: ${verify_result}" \
                "Certificate may be self-signed or have chain issues"
        fi

        # Get certificate details
        local cert_subject
        cert_subject=$(echo "$cert_info" | openssl x509 -noout -subject 2>/dev/null | sed 's/subject=//')
        if [[ -n "$cert_subject" ]]; then
            print_info "Certificate subject: ${cert_subject}"
        fi

        # Check certificate expiry
        if [[ "$QUICK_MODE" == false ]]; then
            local cert_dates
            cert_dates=$(echo "$cert_info" | openssl x509 -noout -dates 2>/dev/null)

            if [[ -n "$cert_dates" ]]; then
                local not_after
                not_after=$(echo "$cert_dates" | grep "notAfter" | cut -d'=' -f2)

                if [[ -n "$not_after" ]]; then
                    local expiry_epoch
                    local now_epoch
                    expiry_epoch=$(date -d "$not_after" +%s 2>/dev/null || echo "0")
                    now_epoch=$(date +%s)

                    if [[ "$expiry_epoch" -gt 0 ]]; then
                        local days_left=$(( (expiry_epoch - now_epoch) / 86400 ))

                        if [[ "$days_left" -lt 0 ]]; then
                            print_fail "SSL certificate has expired" \
                                "Renew the SSL certificate immediately"
                        elif [[ "$days_left" -lt 7 ]]; then
                            print_fail "SSL certificate expires in ${days_left} days" \
                                "Renew the SSL certificate soon"
                        elif [[ "$days_left" -lt 30 ]]; then
                            print_warn "SSL certificate expires in ${days_left} days" \
                                "Plan to renew the SSL certificate"
                        else
                            print_pass "SSL certificate valid for ${days_left} more days"
                        fi
                    fi
                fi
            fi
        fi

        # Check if certificate covers the domain
        local cert_san
        cert_san=$(echo "$cert_info" | openssl x509 -noout -text 2>/dev/null | grep -A1 "Subject Alternative Name" | tail -1)
        if [[ "$cert_san" == *"$DOMAIN"* ]] || [[ "$cert_san" == *"*.trancloud.work"* ]]; then
            print_pass "SSL certificate covers ${DOMAIN}"
        elif [[ -n "$cert_san" ]]; then
            print_info "Certificate SANs: ${cert_san}"
        fi
    else
        print_fail "Cannot retrieve SSL certificate from ${DOMAIN}:443" \
            "Check if HAProxy is configured with SSL termination"
    fi
}

# =============================================================================
# Application Tests
# =============================================================================

test_application() {
    print_header "Application Tests"

    print_subheader "OpenEMR Application"

    # Test OpenEMR setup page or login page
    local https_url="https://${DOMAIN}"
    print_info "Checking OpenEMR application response..."

    local response
    response=$(curl -s --connect-timeout "$TIMEOUT_LONG" -k "$https_url" 2>/dev/null | head -100)

    if [[ -z "$response" ]]; then
        print_warn "No response from OpenEMR application" \
            "Application may be starting up or not responding"
    elif [[ "$response" == *"OpenEMR"* ]]; then
        print_pass "OpenEMR application is responding"

        if [[ "$response" == *"login"* ]] || [[ "$response" == *"Login"* ]]; then
            print_pass "OpenEMR login page detected"
        elif [[ "$response" == *"setup"* ]] || [[ "$response" == *"Setup"* ]] || [[ "$response" == *"installation"* ]]; then
            print_warn "OpenEMR setup/installation page detected" \
                "Complete initial setup at ${https_url}"
        fi
    else
        print_info "Received response but could not identify OpenEMR page"
    fi

    # Test health endpoint if available
    print_info "Checking health endpoints..."
    local health_code
    health_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout "$TIMEOUT_SHORT" -k "${https_url}/apis/default/fhir/metadata" 2>/dev/null || echo "000")

    if [[ "$health_code" == "200" ]]; then
        print_pass "FHIR metadata endpoint is accessible"
    elif [[ "$health_code" == "401" ]]; then
        print_pass "FHIR endpoint requires authentication (expected)"
    elif [[ "$health_code" != "000" ]]; then
        print_info "FHIR metadata returned HTTP ${health_code}"
    fi
}

# =============================================================================
# Summary Report
# =============================================================================

print_summary() {
    print_header "Validation Summary"

    local total_tests=$((TESTS_PASSED + TESTS_FAILED + TESTS_WARNED + TESTS_SKIPPED))

    echo -e "  ${GREEN}Passed:${NC}  ${TESTS_PASSED}"
    echo -e "  ${RED}Failed:${NC}  ${TESTS_FAILED}"
    echo -e "  ${YELLOW}Warned:${NC}  ${TESTS_WARNED}"
    echo -e "  ${CYAN}Skipped:${NC} ${TESTS_SKIPPED}"
    echo -e "  --------------------------------"
    echo -e "  ${WHITE}Total:${NC}   ${total_tests}"
    echo ""

    if [[ ${#FAILURES[@]} -gt 0 ]]; then
        echo -e "${RED}${BOLD}Failed Tests:${NC}"
        echo ""
        for failure in "${FAILURES[@]}"; do
            local msg=$(echo "$failure" | cut -d'|' -f1)
            local remediation=$(echo "$failure" | cut -d'|' -f2)
            echo -e "  ${RED}*${NC} $msg"
            if [[ -n "$remediation" ]]; then
                echo -e "    ${YELLOW}->$remediation${NC}"
            fi
        done
        echo ""
    fi

    if [[ ${#WARNINGS[@]} -gt 0 ]]; then
        echo -e "${YELLOW}${BOLD}Warnings:${NC}"
        echo ""
        for warning in "${WARNINGS[@]}"; do
            local msg=$(echo "$warning" | cut -d'|' -f1)
            local note=$(echo "$warning" | cut -d'|' -f2)
            echo -e "  ${YELLOW}*${NC} $msg"
            if [[ -n "$note" ]]; then
                echo -e "    ${CYAN}->$note${NC}"
            fi
        done
        echo ""
    fi

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}${BOLD}All critical tests passed!${NC}"
        if [[ $TESTS_WARNED -gt 0 ]]; then
            echo -e "${YELLOW}Review warnings above for potential improvements.${NC}"
        fi
        echo ""
        echo "OpenEMR should be accessible at:"
        echo "  Internal: http://${K3S_MASTER}:${K3S_NODEPORT}"
        echo "  Public:   https://${DOMAIN}"
        return 0
    else
        echo -e "${RED}${BOLD}Some tests failed. Please review the failures above.${NC}"
        echo ""
        echo "For detailed troubleshooting, see:"
        echo "  infrastructure/homelab/DEPLOYMENT_GUIDE.md"
        echo "  infrastructure/homelab/DEPLOYMENT_CHECKLIST.md"
        return 1
    fi
}

# =============================================================================
# Main
# =============================================================================

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -q|--quick)
                QUICK_MODE=true
                shift
                ;;
            --skip-db)
                SKIP_DB=true
                shift
                ;;
            --skip-k8s)
                SKIP_K8S=true
                shift
                ;;
            --skip-haproxy)
                SKIP_HAPROXY=true
                shift
                ;;
            *)
                echo -e "${RED}Unknown option: $1${NC}"
                echo "Use --help for usage information"
                exit 2
                ;;
        esac
    done

    echo ""
    echo -e "${WHITE}${BOLD}============================================${NC}"
    echo -e "${WHITE}${BOLD}   OpenEMR Deployment Validation Script    ${NC}"
    echo -e "${WHITE}${BOLD}============================================${NC}"
    echo ""
    echo "Started at: $(date)"
    echo "Host: $(hostname)"
    if [[ "$VERBOSE" == true ]]; then
        echo "Mode: Verbose"
    fi
    if [[ "$QUICK_MODE" == true ]]; then
        echo "Mode: Quick (skipping slow tests)"
    fi
    echo ""

    # Run all test suites
    check_prerequisites
    test_database
    test_kubernetes
    test_haproxy
    test_application

    # Print summary and exit with appropriate code
    print_summary
    exit $?
}

# Run main function
main "$@"
