# pfSense XML Configuration Snippets

These XML files contain configuration snippets for pfSense HAProxy setup for OpenEMR.

## Files

| File | Purpose |
|------|---------|
| `dns-host-override.xml` | DNS resolver host override entry |
| `haproxy-backend.xml` | HAProxy backend pool configuration |
| `haproxy-frontend-acl.xml` | HAProxy frontend ACL and action rules |
| `complete-haproxy-config.xml` | Complete reference showing all elements |

## Configuration Summary

| Component | Value |
|-----------|-------|
| DNS Entry | openemr-dev.trancloud.work -> 192.168.10.1 |
| Backend Name | openemr-dev-be |
| Backend Server | 192.168.10.60:30090 |
| Frontend | trancloud-https (existing) |
| ACL Name | openemr-dev-acl |
| ACL Expression | Host matches: openemr-dev.trancloud.work |
| Action | Use Backend: openemr-dev-be |

## Usage Options

### Option 1: Use Automation Script (Recommended)

```bash
# SSH-based configuration (recommended)
./scripts/configure-pfsense-haproxy.sh ssh

# Or try all methods
./scripts/configure-pfsense-haproxy.sh all
```

### Option 2: Manual XML Import via SSH

1. SSH to pfSense:
   ```bash
   ssh dang@pfsense.trancloud.work
   ```

2. Backup current config:
   ```bash
   cp /cf/conf/config.xml /cf/conf/config.xml.backup
   ```

3. Edit the config file:
   ```bash
   vi /cf/conf/config.xml
   ```

4. Add the XML snippets to appropriate sections:
   - DNS override: Add to `<unbound><hosts>` section
   - HAProxy backend: Add to `<installedpackages><haproxy><ha_pools>` section
   - ACL/Action: Add to the `trancloud-https` frontend in `<ha_backends>`

5. Restart services:
   ```bash
   /etc/rc.reload_all
   ```

### Option 3: Manual Configuration via Web UI

Follow the step-by-step guide in `../pfsense-haproxy-config.md`

## Verification

After configuration, verify with:

```bash
# Test DNS resolution
nslookup openemr-dev.trancloud.work

# Test backend directly
curl http://192.168.10.60:30090

# Test via HAProxy
curl -k https://openemr-dev.trancloud.work

# Or use the script
./scripts/configure-pfsense-haproxy.sh verify
```

## Troubleshooting

### DNS Not Resolving

```bash
# Test against pfSense DNS directly
nslookup openemr-dev.trancloud.work 192.168.10.1

# Restart DNS resolver
ssh dang@pfsense.trancloud.work "unbound-control reload"
```

### HAProxy Backend Down

Check HAProxy stats page at:
- https://pfsense.trancloud.work/haproxy_stats.php

Or verify backend connectivity:
```bash
curl -v http://192.168.10.60:30090/
```

### 503 Service Unavailable

1. Check k8s deployment: `kubectl get pods -n openemr-dev`
2. Check pod logs: `kubectl logs -n openemr-dev -l app=openemr`
3. Verify NodePort is accessible
