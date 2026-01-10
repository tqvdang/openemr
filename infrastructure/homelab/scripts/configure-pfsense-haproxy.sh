#!/bin/bash
# =============================================================================
# pfSense HAProxy Configuration Script for OpenEMR
# =============================================================================
# This script automates the configuration of:
# - DNS Host Override: openemr-dev.trancloud.work -> 192.168.10.1
# - HAProxy Backend: openemr-dev-be -> 192.168.10.60:30090
# - HAProxy Frontend ACL and Action in trancloud-https frontend
#
# Author: OpenEMR Infrastructure Team
# Date: 2026-01-01
# =============================================================================

set -e

# =============================================================================
# Configuration Variables
# =============================================================================
PFSENSE_HOST="${PFSENSE_HOST:-pfsense.trancloud.work}"
PFSENSE_USER="${PFSENSE_USER:-dang}"
PFSENSE_PASS="${PFSENSE_PASS:-${INFRA_PASSWORD}}"

# OpenEMR Configuration
OPENEMR_HOSTNAME="openemr-dev"
OPENEMR_DOMAIN="trancloud.work"
OPENEMR_FQDN="${OPENEMR_HOSTNAME}.${OPENEMR_DOMAIN}"
HAPROXY_VIP="192.168.10.1"
K3S_BACKEND_IP="192.168.10.60"
K3S_NODEPORT="30090"

# HAProxy Names
BACKEND_NAME="openemr-dev-be"
BACKEND_DESC="OpenEMR Dev Backend"
SERVER_NAME="k3s-openemr"
ACL_NAME="openemr-dev-acl"
FRONTEND_NAME="trancloud-https"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# =============================================================================
# Helper Functions
# =============================================================================

print_header() {
    echo ""
    echo -e "${BLUE}=============================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}=============================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}[OK] $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

print_error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

print_info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

check_dependencies() {
    local missing=()

    for cmd in curl jq sshpass ssh; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        print_error "Missing dependencies: ${missing[*]}"
        echo ""
        echo "Install with:"
        echo "  Ubuntu/Debian: sudo apt-get install curl jq sshpass openssh-client"
        echo "  RHEL/CentOS:   sudo yum install curl jq sshpass openssh-clients"
        echo "  macOS:         brew install curl jq hudochenkov/sshpass/sshpass"
        exit 1
    fi

    print_success "All dependencies available"
}

# =============================================================================
# Method 1: pfSense API (if pfsense-api package is installed)
# =============================================================================

configure_via_api() {
    print_header "Method 1: pfSense API Configuration"

    local API_BASE="https://${PFSENSE_HOST}/api/v1"
    local AUTH_HEADER="Authorization: ${PFSENSE_USER} ${PFSENSE_PASS}"

    print_info "Testing API availability..."

    # Test API endpoint
    local api_test=$(curl -s -k -w "%{http_code}" -o /dev/null \
        -X GET "${API_BASE}/system/version" \
        -H "Content-Type: application/json" \
        -H "${AUTH_HEADER}" 2>/dev/null || echo "000")

    if [ "$api_test" == "200" ]; then
        print_success "pfSense API is available"
    else
        print_warning "pfSense API not available (HTTP $api_test)"
        print_info "The pfsense-api package may not be installed"
        print_info "Install from: https://github.com/jaredhendrickson13/pfsense-api"
        return 1
    fi

    # Step 1: Create DNS Host Override
    print_info "Creating DNS Host Override..."
    local dns_result=$(curl -s -k \
        -X POST "${API_BASE}/services/unbound/host_override" \
        -H "Content-Type: application/json" \
        -H "${AUTH_HEADER}" \
        -d "{
            \"host\": \"${OPENEMR_HOSTNAME}\",
            \"domain\": \"${OPENEMR_DOMAIN}\",
            \"ip\": \"${HAPROXY_VIP}\",
            \"descr\": \"OpenEMR Dev Environment\",
            \"apply\": true
        }" 2>/dev/null)

    if echo "$dns_result" | jq -e '.code == 200' > /dev/null 2>&1; then
        print_success "DNS Host Override created"
    else
        print_warning "DNS Host Override may already exist or failed"
        echo "$dns_result" | jq '.' 2>/dev/null || echo "$dns_result"
    fi

    # Step 2: Create HAProxy Backend
    print_info "Creating HAProxy Backend..."
    local backend_result=$(curl -s -k \
        -X POST "${API_BASE}/services/haproxy/backend" \
        -H "Content-Type: application/json" \
        -H "${AUTH_HEADER}" \
        -d "{
            \"name\": \"${BACKEND_NAME}\",
            \"descr\": \"${BACKEND_DESC}\",
            \"mode\": \"http\",
            \"balance\": \"roundrobin\",
            \"check_type\": \"HTTP\",
            \"checkinter\": \"2000\",
            \"httpcheck_method\": \"GET\",
            \"monitor_uri\": \"/\",
            \"servers\": [
                {
                    \"name\": \"${SERVER_NAME}\",
                    \"address\": \"${K3S_BACKEND_IP}\",
                    \"port\": \"${K3S_NODEPORT}\",
                    \"ssl\": false,
                    \"sslverify\": false
                }
            ],
            \"apply\": true
        }" 2>/dev/null)

    if echo "$backend_result" | jq -e '.code == 200' > /dev/null 2>&1; then
        print_success "HAProxy Backend created"
    else
        print_warning "HAProxy Backend may already exist or failed"
        echo "$backend_result" | jq '.' 2>/dev/null || echo "$backend_result"
    fi

    # Step 3: Update Frontend with ACL and Action
    print_info "Note: Frontend ACL/Action update via API requires manual configuration"
    print_info "Please add ACL and Action to '${FRONTEND_NAME}' frontend manually"
    print_info "See 'Method 3: Manual Configuration' section below"

    return 0
}

# =============================================================================
# Method 2: SSH-based Configuration
# =============================================================================

configure_via_ssh() {
    print_header "Method 2: SSH Configuration"

    print_info "Testing SSH connectivity to ${PFSENSE_HOST}..."

    # Test SSH connection
    if ! sshpass -p "${PFSENSE_PASS}" ssh -o StrictHostKeyChecking=no \
        -o ConnectTimeout=10 "${PFSENSE_USER}@${PFSENSE_HOST}" \
        "echo 'SSH connection successful'" 2>/dev/null; then
        print_error "Cannot connect via SSH"
        return 1
    fi

    print_success "SSH connection established"

    # Create temporary PHP script to configure pfSense
    local PHP_SCRIPT=$(cat << 'EOFPHP'
<?php
// pfSense Configuration Script for OpenEMR HAProxy Setup
// This script modifies the pfSense config.xml

require_once("config.inc");
require_once("util.inc");
require_once("interfaces.inc");

// Configuration parameters (will be replaced by shell variables)
$openemr_hostname = "__OPENEMR_HOSTNAME__";
$openemr_domain = "__OPENEMR_DOMAIN__";
$haproxy_vip = "__HAPROXY_VIP__";
$k3s_backend_ip = "__K3S_BACKEND_IP__";
$k3s_nodeport = "__K3S_NODEPORT__";
$backend_name = "__BACKEND_NAME__";
$backend_desc = "__BACKEND_DESC__";
$server_name = "__SERVER_NAME__";
$acl_name = "__ACL_NAME__";
$frontend_name = "__FRONTEND_NAME__";

// Initialize config
global $config;
$config_changed = false;

echo "=== pfSense OpenEMR HAProxy Configuration ===\n\n";

// =============================================================================
// Step 1: Add DNS Host Override
// =============================================================================
echo "Step 1: Configuring DNS Host Override...\n";

if (!isset($config['unbound']['hosts'])) {
    $config['unbound']['hosts'] = array();
}

// Check if override already exists
$dns_exists = false;
foreach ($config['unbound']['hosts'] as $host) {
    if ($host['host'] == $openemr_hostname && $host['domain'] == $openemr_domain) {
        $dns_exists = true;
        echo "  - DNS override already exists\n";
        break;
    }
}

if (!$dns_exists) {
    $config['unbound']['hosts'][] = array(
        'host' => $openemr_hostname,
        'domain' => $openemr_domain,
        'ip' => $haproxy_vip,
        'descr' => 'OpenEMR Dev Environment'
    );
    $config_changed = true;
    echo "  - DNS override added: {$openemr_hostname}.{$openemr_domain} -> {$haproxy_vip}\n";
}

// =============================================================================
// Step 2: Add HAProxy Backend
// =============================================================================
echo "\nStep 2: Configuring HAProxy Backend...\n";

if (!isset($config['installedpackages']['haproxy']['ha_pools']['item'])) {
    if (!isset($config['installedpackages'])) {
        $config['installedpackages'] = array();
    }
    if (!isset($config['installedpackages']['haproxy'])) {
        $config['installedpackages']['haproxy'] = array();
    }
    if (!isset($config['installedpackages']['haproxy']['ha_pools'])) {
        $config['installedpackages']['haproxy']['ha_pools'] = array();
    }
    $config['installedpackages']['haproxy']['ha_pools']['item'] = array();
}

// Check if backend already exists
$backend_exists = false;
$backends = &$config['installedpackages']['haproxy']['ha_pools']['item'];
foreach ($backends as $backend) {
    if ($backend['name'] == $backend_name) {
        $backend_exists = true;
        echo "  - Backend '{$backend_name}' already exists\n";
        break;
    }
}

if (!$backend_exists) {
    $new_backend = array(
        'name' => $backend_name,
        'descr' => $backend_desc,
        'mode' => 'http',
        'balance' => 'roundrobin',
        'check_type' => 'HTTP',
        'checkinter' => '2000',
        'httpcheck_method' => 'GET',
        'monitor_uri' => '/',
        'ha_servers' => array(
            'item' => array(
                array(
                    'name' => $server_name,
                    'address' => $k3s_backend_ip,
                    'port' => $k3s_nodeport,
                    'ssl' => '',
                    'sslverify' => ''
                )
            )
        )
    );
    $backends[] = $new_backend;
    $config_changed = true;
    echo "  - Backend '{$backend_name}' added with server {$k3s_backend_ip}:{$k3s_nodeport}\n";
}

// =============================================================================
// Step 3: Add ACL and Action to Frontend
// =============================================================================
echo "\nStep 3: Configuring HAProxy Frontend ACL and Action...\n";

if (isset($config['installedpackages']['haproxy']['ha_backends']['item'])) {
    $frontends = &$config['installedpackages']['haproxy']['ha_backends']['item'];
    $frontend_found = false;

    foreach ($frontends as &$frontend) {
        if ($frontend['name'] == $frontend_name) {
            $frontend_found = true;

            // Add ACL if not exists
            if (!isset($frontend['ha_acls']['item'])) {
                $frontend['ha_acls']['item'] = array();
            }

            $acl_exists = false;
            foreach ($frontend['ha_acls']['item'] as $acl) {
                if ($acl['name'] == $acl_name) {
                    $acl_exists = true;
                    echo "  - ACL '{$acl_name}' already exists\n";
                    break;
                }
            }

            if (!$acl_exists) {
                $frontend['ha_acls']['item'][] = array(
                    'name' => $acl_name,
                    'expression' => 'host_matches',
                    'value' => "{$openemr_hostname}.{$openemr_domain}",
                    'casesensitive' => '',
                    'not' => ''
                );
                $config_changed = true;
                echo "  - ACL '{$acl_name}' added for host: {$openemr_hostname}.{$openemr_domain}\n";
            }

            // Add Action if not exists
            if (!isset($frontend['a_actionitems']['item'])) {
                $frontend['a_actionitems']['item'] = array();
            }

            $action_exists = false;
            foreach ($frontend['a_actionitems']['item'] as $action) {
                if (isset($action['acl']) && $action['acl'] == $acl_name) {
                    $action_exists = true;
                    echo "  - Action for ACL '{$acl_name}' already exists\n";
                    break;
                }
            }

            if (!$action_exists) {
                $frontend['a_actionitems']['item'][] = array(
                    'action' => 'use_backend',
                    'acl' => $acl_name,
                    'backend' => $backend_name
                );
                $config_changed = true;
                echo "  - Action added: Use backend '{$backend_name}' when ACL '{$acl_name}' matches\n";
            }

            break;
        }
    }
    unset($frontend);

    if (!$frontend_found) {
        echo "  - WARNING: Frontend '{$frontend_name}' not found!\n";
        echo "  - Please create the frontend first or check the name\n";
    }
} else {
    echo "  - WARNING: No HAProxy frontends configured!\n";
}

// =============================================================================
// Save Configuration
// =============================================================================
echo "\nSaving configuration...\n";

if ($config_changed) {
    write_config("OpenEMR HAProxy configuration added via automation script");
    echo "Configuration saved successfully.\n";

    // Restart services
    echo "\nRestarting services...\n";

    // Restart Unbound DNS
    echo "  - Restarting DNS Resolver...\n";
    exec("/usr/local/sbin/unbound-control reload 2>&1", $output, $retval);
    if ($retval == 0) {
        echo "    DNS Resolver restarted\n";
    } else {
        echo "    WARNING: DNS restart may have failed\n";
    }

    // Restart HAProxy
    echo "  - Restarting HAProxy...\n";
    exec("/usr/local/etc/rc.d/haproxy.sh restart 2>&1", $output, $retval);
    if ($retval == 0) {
        echo "    HAProxy restarted\n";
    } else {
        exec("service haproxy restart 2>&1", $output2, $retval2);
        if ($retval2 == 0) {
            echo "    HAProxy restarted\n";
        } else {
            echo "    WARNING: HAProxy restart may have failed\n";
        }
    }

    echo "\n=== Configuration Complete ===\n";
} else {
    echo "No changes needed - configuration already exists.\n";
}

echo "\nVerification URLs:\n";
echo "  - DNS: nslookup {$openemr_hostname}.{$openemr_domain}\n";
echo "  - HAProxy Stats: https://{$_SERVER['SERVER_ADDR']}/haproxy_stats.php\n";
echo "  - OpenEMR: https://{$openemr_hostname}.{$openemr_domain}\n";

?>
EOFPHP
)

    # Replace placeholders with actual values
    PHP_SCRIPT=$(echo "$PHP_SCRIPT" | sed "s|__OPENEMR_HOSTNAME__|${OPENEMR_HOSTNAME}|g")
    PHP_SCRIPT=$(echo "$PHP_SCRIPT" | sed "s|__OPENEMR_DOMAIN__|${OPENEMR_DOMAIN}|g")
    PHP_SCRIPT=$(echo "$PHP_SCRIPT" | sed "s|__HAPROXY_VIP__|${HAPROXY_VIP}|g")
    PHP_SCRIPT=$(echo "$PHP_SCRIPT" | sed "s|__K3S_BACKEND_IP__|${K3S_BACKEND_IP}|g")
    PHP_SCRIPT=$(echo "$PHP_SCRIPT" | sed "s|__K3S_NODEPORT__|${K3S_NODEPORT}|g")
    PHP_SCRIPT=$(echo "$PHP_SCRIPT" | sed "s|__BACKEND_NAME__|${BACKEND_NAME}|g")
    PHP_SCRIPT=$(echo "$PHP_SCRIPT" | sed "s|__BACKEND_DESC__|${BACKEND_DESC}|g")
    PHP_SCRIPT=$(echo "$PHP_SCRIPT" | sed "s|__SERVER_NAME__|${SERVER_NAME}|g")
    PHP_SCRIPT=$(echo "$PHP_SCRIPT" | sed "s|__ACL_NAME__|${ACL_NAME}|g")
    PHP_SCRIPT=$(echo "$PHP_SCRIPT" | sed "s|__FRONTEND_NAME__|${FRONTEND_NAME}|g")

    # Execute PHP script on pfSense
    print_info "Executing configuration script on pfSense..."
    echo ""

    echo "$PHP_SCRIPT" | sshpass -p "${PFSENSE_PASS}" ssh -o StrictHostKeyChecking=no \
        "${PFSENSE_USER}@${PFSENSE_HOST}" \
        "cat > /tmp/configure_openemr.php && php /tmp/configure_openemr.php && rm /tmp/configure_openemr.php"

    echo ""
    print_success "SSH configuration completed"

    return 0
}

# =============================================================================
# Method 3: Generate XML Config Snippets for Manual Import
# =============================================================================

generate_xml_snippets() {
    print_header "Method 3: XML Configuration Snippets"

    local OUTPUT_DIR="$(dirname "$0")/../docs/pfsense-xml"
    mkdir -p "$OUTPUT_DIR"

    # DNS Host Override XML
    cat > "${OUTPUT_DIR}/dns-host-override.xml" << EOFXML
<?xml version="1.0"?>
<!-- DNS Host Override for OpenEMR -->
<!-- Import via: Diagnostics > Backup & Restore > Restore Configuration Area: Unbound DNS Resolver -->
<unbound>
    <hosts>
        <host>${OPENEMR_HOSTNAME}</host>
        <domain>${OPENEMR_DOMAIN}</domain>
        <ip>${HAPROXY_VIP}</ip>
        <descr>OpenEMR Dev Environment</descr>
    </hosts>
</unbound>
EOFXML
    print_success "Created: ${OUTPUT_DIR}/dns-host-override.xml"

    # HAProxy Backend XML
    cat > "${OUTPUT_DIR}/haproxy-backend.xml" << EOFXML
<?xml version="1.0"?>
<!-- HAProxy Backend for OpenEMR -->
<!-- Add this to the <ha_pools> section in config.xml -->
<item>
    <name>${BACKEND_NAME}</name>
    <descr><![CDATA[${BACKEND_DESC}]]></descr>
    <mode>http</mode>
    <balance>roundrobin</balance>
    <check_type>HTTP</check_type>
    <checkinter>2000</checkinter>
    <httpcheck_method>GET</httpcheck_method>
    <monitor_uri>/</monitor_uri>
    <ha_servers>
        <item>
            <name>${SERVER_NAME}</name>
            <address>${K3S_BACKEND_IP}</address>
            <port>${K3S_NODEPORT}</port>
            <ssl></ssl>
            <sslverify></sslverify>
        </item>
    </ha_servers>
</item>
EOFXML
    print_success "Created: ${OUTPUT_DIR}/haproxy-backend.xml"

    # HAProxy Frontend ACL and Action XML
    cat > "${OUTPUT_DIR}/haproxy-frontend-acl.xml" << EOFXML
<?xml version="1.0"?>
<!-- HAProxy Frontend ACL and Action for OpenEMR -->
<!-- Add these to the ${FRONTEND_NAME} frontend in config.xml -->

<!-- ACL Entry (add to <ha_acls> section) -->
<ha_acls>
    <item>
        <name>${ACL_NAME}</name>
        <expression>host_matches</expression>
        <value>${OPENEMR_FQDN}</value>
        <casesensitive></casesensitive>
        <not></not>
    </item>
</ha_acls>

<!-- Action Entry (add to <a_actionitems> section) -->
<a_actionitems>
    <item>
        <action>use_backend</action>
        <acl>${ACL_NAME}</acl>
        <backend>${BACKEND_NAME}</backend>
    </item>
</a_actionitems>
EOFXML
    print_success "Created: ${OUTPUT_DIR}/haproxy-frontend-acl.xml"

    # Complete configuration snippet
    cat > "${OUTPUT_DIR}/complete-haproxy-config.xml" << EOFXML
<?xml version="1.0"?>
<!-- Complete HAProxy Configuration for OpenEMR -->
<!--
  This file shows the complete structure needed in pfSense config.xml
  Use as reference for manual configuration
-->
<pfsense>
    <!-- DNS Resolver Host Override -->
    <unbound>
        <hosts>
            <host>${OPENEMR_HOSTNAME}</host>
            <domain>${OPENEMR_DOMAIN}</domain>
            <ip>${HAPROXY_VIP}</ip>
            <descr>OpenEMR Dev Environment</descr>
        </hosts>
    </unbound>

    <!-- HAProxy Configuration -->
    <installedpackages>
        <haproxy>
            <!-- Backend Pool -->
            <ha_pools>
                <item>
                    <name>${BACKEND_NAME}</name>
                    <descr><![CDATA[${BACKEND_DESC}]]></descr>
                    <mode>http</mode>
                    <balance>roundrobin</balance>
                    <check_type>HTTP</check_type>
                    <checkinter>2000</checkinter>
                    <httpcheck_method>GET</httpcheck_method>
                    <monitor_uri>/</monitor_uri>
                    <ha_servers>
                        <item>
                            <name>${SERVER_NAME}</name>
                            <address>${K3S_BACKEND_IP}</address>
                            <port>${K3S_NODEPORT}</port>
                            <ssl></ssl>
                            <sslverify></sslverify>
                        </item>
                    </ha_servers>
                </item>
            </ha_pools>

            <!-- Frontend (existing ${FRONTEND_NAME} - add ACL and Action) -->
            <ha_backends>
                <item>
                    <name>${FRONTEND_NAME}</name>
                    <!-- ... existing frontend config ... -->

                    <!-- Add this ACL -->
                    <ha_acls>
                        <item>
                            <name>${ACL_NAME}</name>
                            <expression>host_matches</expression>
                            <value>${OPENEMR_FQDN}</value>
                            <casesensitive></casesensitive>
                            <not></not>
                        </item>
                    </ha_acls>

                    <!-- Add this Action -->
                    <a_actionitems>
                        <item>
                            <action>use_backend</action>
                            <acl>${ACL_NAME}</acl>
                            <backend>${BACKEND_NAME}</backend>
                        </item>
                    </a_actionitems>
                </item>
            </ha_backends>
        </haproxy>
    </installedpackages>
</pfsense>
EOFXML
    print_success "Created: ${OUTPUT_DIR}/complete-haproxy-config.xml"

    echo ""
    print_info "XML files created in: ${OUTPUT_DIR}"
    echo ""
    echo "To use these files:"
    echo "1. SSH to pfSense: ssh ${PFSENSE_USER}@${PFSENSE_HOST}"
    echo "2. Backup current config: cp /cf/conf/config.xml /cf/conf/config.xml.backup"
    echo "3. Edit config: vi /cf/conf/config.xml"
    echo "4. Add the XML snippets to appropriate sections"
    echo "5. Restart services: /etc/rc.reload_all"
    echo ""
    echo "Or use pfSense Web UI:"
    echo "1. Login to https://${PFSENSE_HOST}"
    echo "2. Navigate to Diagnostics > Backup & Restore"
    echo "3. Download current config as backup"
    echo "4. Manually add configurations via respective menus"

    return 0
}

# =============================================================================
# Verification Function
# =============================================================================

verify_configuration() {
    print_header "Verifying Configuration"

    local errors=0

    # Test DNS resolution
    print_info "Testing DNS resolution..."
    local dns_result=$(nslookup "${OPENEMR_FQDN}" 2>/dev/null | grep -A1 "Name:" | grep "Address" | awk '{print $2}')

    if [ "$dns_result" == "$HAPROXY_VIP" ]; then
        print_success "DNS resolves correctly: ${OPENEMR_FQDN} -> ${dns_result}"
    else
        print_warning "DNS resolution: Expected ${HAPROXY_VIP}, got '${dns_result}'"
        print_info "Try: nslookup ${OPENEMR_FQDN} ${HAPROXY_VIP}"
        ((errors++))
    fi

    # Test backend connectivity
    print_info "Testing backend connectivity..."
    if curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 \
        "http://${K3S_BACKEND_IP}:${K3S_NODEPORT}/" 2>/dev/null | grep -q "200\|302\|301"; then
        print_success "Backend is accessible: http://${K3S_BACKEND_IP}:${K3S_NODEPORT}"
    else
        print_warning "Backend may not be accessible at http://${K3S_BACKEND_IP}:${K3S_NODEPORT}"
        print_info "Check: kubectl get pods -n openemr-dev"
        ((errors++))
    fi

    # Test HTTPS endpoint
    print_info "Testing HTTPS endpoint..."
    local https_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 \
        -k "https://${OPENEMR_FQDN}/" 2>/dev/null)

    if [ "$https_code" == "200" ] || [ "$https_code" == "302" ] || [ "$https_code" == "301" ]; then
        print_success "HTTPS endpoint accessible: https://${OPENEMR_FQDN} (HTTP $https_code)"
    else
        print_warning "HTTPS endpoint returned: HTTP $https_code"
        print_info "HAProxy may not be configured yet"
        ((errors++))
    fi

    echo ""
    if [ $errors -eq 0 ]; then
        print_success "All verification checks passed!"
    else
        print_warning "$errors verification check(s) need attention"
    fi

    return $errors
}

# =============================================================================
# Usage Information
# =============================================================================

show_usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] [COMMAND]

Configure pfSense HAProxy for OpenEMR access.

COMMANDS:
    api         Configure via pfSense API (requires pfsense-api package)
    ssh         Configure via SSH (recommended)
    xml         Generate XML config snippets for manual import
    verify      Verify current configuration
    all         Try all methods (API -> SSH -> XML)
    help        Show this help message

OPTIONS:
    --host HOST         pfSense hostname (default: ${PFSENSE_HOST})
    --user USER         pfSense username (default: ${PFSENSE_USER})
    --pass PASS         pfSense password
    --backend-ip IP     k3s backend IP (default: ${K3S_BACKEND_IP})
    --nodeport PORT     k3s NodePort (default: ${K3S_NODEPORT})
    --dry-run           Show what would be done without making changes

ENVIRONMENT VARIABLES:
    PFSENSE_HOST        pfSense hostname
    PFSENSE_USER        pfSense username
    PFSENSE_PASS        pfSense password

EXAMPLES:
    # Configure via SSH (recommended)
    $(basename "$0") ssh

    # Generate XML snippets only
    $(basename "$0") xml

    # Verify configuration
    $(basename "$0") verify

    # Use custom credentials
    PFSENSE_PASS='mypassword' $(basename "$0") ssh

    # Full automation
    $(basename "$0") all

CONFIGURATION SUMMARY:
    DNS Override:    ${OPENEMR_FQDN} -> ${HAPROXY_VIP}
    HAProxy Backend: ${BACKEND_NAME} -> ${K3S_BACKEND_IP}:${K3S_NODEPORT}
    HAProxy ACL:     ${ACL_NAME} (Host matches ${OPENEMR_FQDN})
    HAProxy Action:  Use backend ${BACKEND_NAME}
    Frontend:        ${FRONTEND_NAME}

For manual configuration, see:
    infrastructure/homelab/docs/pfsense-haproxy-config.md

EOF
}

# =============================================================================
# Main Script
# =============================================================================

main() {
    print_header "pfSense HAProxy Configuration for OpenEMR"

    echo "Target: ${PFSENSE_HOST}"
    echo "OpenEMR FQDN: ${OPENEMR_FQDN}"
    echo "Backend: ${K3S_BACKEND_IP}:${K3S_NODEPORT}"
    echo ""

    # Parse arguments
    local COMMAND="${1:-help}"
    shift || true

    while [[ $# -gt 0 ]]; do
        case $1 in
            --host) PFSENSE_HOST="$2"; shift 2 ;;
            --user) PFSENSE_USER="$2"; shift 2 ;;
            --pass) PFSENSE_PASS="$2"; shift 2 ;;
            --backend-ip) K3S_BACKEND_IP="$2"; shift 2 ;;
            --nodeport) K3S_NODEPORT="$2"; shift 2 ;;
            --dry-run) DRY_RUN=true; shift ;;
            *) shift ;;
        esac
    done

    case "$COMMAND" in
        api)
            check_dependencies
            configure_via_api
            ;;
        ssh)
            check_dependencies
            configure_via_ssh
            verify_configuration
            ;;
        xml)
            generate_xml_snippets
            ;;
        verify)
            verify_configuration
            ;;
        all)
            check_dependencies
            if configure_via_api; then
                print_success "API configuration completed"
            elif configure_via_ssh; then
                print_success "SSH configuration completed"
            else
                print_warning "Automated methods failed, generating XML snippets"
                generate_xml_snippets
            fi
            verify_configuration
            ;;
        help|--help|-h)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown command: $COMMAND"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
