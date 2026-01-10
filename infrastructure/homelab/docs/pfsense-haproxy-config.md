# pfSense HAProxy Configuration for OpenEMR

This guide documents how to configure HAProxy in pfSense to make OpenEMR publicly accessible at `https://openemr-dev.trancloud.work`.

## Prerequisites

- OpenEMR deployed to k3s and accessible at NodePort 30090
- pfSense credentials: dang / <PASSWORD_FROM_INFISICAL>
- Access to https://pfsense.trancloud.work

## Step 1: Configure DNS Override

This makes `openemr-dev.trancloud.work` resolve to HAProxy internally.

1. Login to pfSense: https://pfsense.trancloud.work
   - Username: dang
   - Password: <PASSWORD_FROM_INFISICAL>

2. Navigate to: **Services → DNS Resolver → Host Overrides**

3. Click **Add** (+ icon at bottom)

4. Fill in:
   - **Host**: `openemr-dev`
   - **Domain**: `trancloud.work`
   - **IP Address**: `192.168.10.1` (HAProxy address)
   - **Description**: `OpenEMR Dev Environment`

5. Click **Save**

6. Click **Apply Changes** at the top

7. Verify DNS resolution from your workstation:
   ```bash
   nslookup openemr-dev.trancloud.work
   # Should return: 192.168.10.1
   ```

## Step 2: Create HAProxy Backend

The backend points to the k3s NodePort service.

1. Navigate to: **Services → HAProxy → Backend**

2. Click **Add** (+ icon)

3. Fill in **Backend** tab:
   - **Name**: `openemr-dev-be`
   - **Description**: `OpenEMR Dev Backend`
   - **Mode**: `HTTP`
   - **Balance**: `roundrobin`

4. In **Server list** section, click **Add** (+):
   - **Name**: `k3s-openemr`
   - **Forwardto**: `Address+Port`
   - **Address**: `192.168.10.60` (k3s-master)
   - **Port**: `30090` (NodePort)
   - **SSL**: `no` (unchecked)
   - **Verify SSL Certificate**: `no` (unchecked)

5. In **Health checking** section:
   - **Health check method**: `HTTP`
   - **Http check method**: `GET`
   - **Http check URI**: `/`
   - **Check interval**: `2000` (ms)
   - **Check down interval**: `2000` (ms)

6. Click **Save**

7. Click **Apply Changes**

## Step 3: Configure HAProxy Frontend ACL and Action

Add routing rules to the existing `trancloud-https` frontend.

1. Navigate to: **Services → HAProxy → Frontend**

2. Find and click **Edit** (pencil icon) on `trancloud-https` frontend

3. Scroll to **Access Control lists** section

4. Click **Add** (+) to add new ACL:
   - **Name**: `openemr-dev-acl`
   - **Expression**: `Host matches:` (from dropdown)
   - **CS**: `no` (case sensitive - unchecked)
   - **Not**: `no` (unchecked)
   - **Value**: `openemr-dev.trancloud.work`

5. Scroll to **Actions** section

6. Click **Add** (+) to add new action:
   - **Action**: `Use Backend` (from dropdown)
   - **Condition acl names**: `openemr-dev-acl`
   - **backend**: `openemr-dev-be`

7. **Important**: Use the up/down arrows to position this action:
   - Must be AFTER any path-based rules
   - Must be BEFORE the default backend (if any)
   - Typical order:
     1. Path-based rules (e.g., `/api`)
     2. Host-based rules (e.g., `openemr-dev-acl`)
     3. Default backend

8. Click **Save**

9. Click **Apply Changes**

## Step 4: Verify HAProxy Configuration

1. Navigate to: **Services → HAProxy → Stats**

2. Click **View HAProxy Stats**

3. Look for `openemr-dev-be` backend:
   - Status should be **GREEN** (UP)
   - If **RED**, check:
     - k3s pod is running: `kubectl get pods -n openemr-dev`
     - NodePort is accessible: `curl http://192.168.10.60:30090`
     - Backend health check settings

## Step 5: Test Access

### Internal Access Test

```bash
# From any machine on the network
curl -I https://openemr-dev.trancloud.work

# Should return HTTP 200 OK
```

### Browser Test

1. Open browser: https://openemr-dev.trancloud.work

2. You should see OpenEMR login page

3. Default credentials (if first time):
   - Username: admin
   - Password: <ADMIN_PASSWORD_FROM_INFISICAL>

### Check SSL Certificate

```bash
openssl s_client -connect openemr-dev.trancloud.work:443 -servername openemr-dev.trancloud.work < /dev/null 2>/dev/null | openssl x509 -noout -subject -dates

# Should show:
# subject=CN = *.trancloud.work
# notBefore and notAfter dates
```

## Step 6: Optional - Make Publicly Accessible

If you want OpenEMR accessible from the internet:

### Option A: Cloudflare DNS (Recommended)

1. Login to Cloudflare dashboard

2. Navigate to your domain's DNS settings

3. Add A record:
   - **Type**: A
   - **Name**: openemr-dev
   - **IPv4 address**: Your public IP (check at https://icanhazip.com)
   - **Proxy status**: Proxied (orange cloud) ✓
   - **TTL**: Auto

4. Navigate to **SSL/TLS → Overview**:
   - Set encryption mode to: **Full (strict)**

5. Test from external network:
   ```bash
   curl -I https://openemr-dev.trancloud.work
   ```

### Option B: Direct Port Forwarding

1. In pfSense: **Firewall → NAT → Port Forward**

2. Click **Add** (↑ icon)

3. Fill in:
   - **Interface**: WAN
   - **Protocol**: TCP
   - **Destination**: WAN address
   - **Destination port range**: 443 to 443
   - **Redirect target IP**: 192.168.10.1
   - **Redirect target port**: 443
   - **Description**: OpenEMR HTTPS

4. Click **Save** and **Apply Changes**

## Troubleshooting

### 503 Service Unavailable

**Cause**: Backend is down or unhealthy

**Solution**:
```bash
# Check k8s deployment
kubectl get pods -n openemr-dev

# Check pod logs
kubectl logs -n openemr-dev -l app=openemr

# Test NodePort directly
curl http://192.168.10.60:30090
```

### SSL Certificate Error

**Cause**: Wrong certificate or hostname mismatch

**Solution**:
- Verify `trancloud-wildcard` certificate covers `*.trancloud.work`
- Check certificate expiration in **System → Cert. Manager**
- Renew if needed using ACME client

### DNS Not Resolving

**Cause**: DNS override not working

**Solution**:
```bash
# Test DNS from client
nslookup openemr-dev.trancloud.work

# Test DNS directly against pfSense
nslookup openemr-dev.trancloud.work 192.168.10.1

# Restart DNS Resolver in pfSense
Services → DNS Resolver → click "Apply Changes"
```

### Backend Shows RED in Stats

**Cause**: Health check failing

**Solution**:
1. Check if OpenEMR is responding:
   ```bash
   curl -v http://192.168.10.60:30090/
   ```

2. Adjust health check in backend:
   - Change URI to `/interface/login/login.php`
   - Increase check interval
   - Add HTTP version: `HTTP/1.1`

## HAProxy Configuration Summary

| Component | Value |
|-----------|-------|
| **DNS Entry** | openemr-dev.trancloud.work → 192.168.10.1 |
| **Backend Name** | openemr-dev-be |
| **Backend Server** | 192.168.10.60:30090 |
| **Frontend** | trancloud-https (existing) |
| **ACL Name** | openemr-dev-acl |
| **ACL Expression** | Host matches: openemr-dev.trancloud.work |
| **Action** | Use Backend: openemr-dev-be |
| **NodePort** | 30090 |
| **Internal URL** | http://192.168.10.60:30090 |
| **Public URL** | https://openemr-dev.trancloud.work |

## Security Considerations

1. **Authentication**: Enable OpenEMR's built-in authentication
2. **Access Control**: Consider adding source IP restrictions in HAProxy ACL
3. **Rate Limiting**: Add rate limiting in HAProxy to prevent abuse
4. **Monitoring**: Monitor HAProxy logs for suspicious activity
5. **Updates**: Keep OpenEMR and pfSense updated

## Monitoring

View HAProxy logs:
```bash
# SSH to pfSense
ssh dang@pfsense.trancloud.work

# View real-time logs
tail -f /var/log/haproxy.log | grep openemr-dev
```

View OpenEMR application logs:
```bash
kubectl logs -n openemr-dev -l app=openemr -f
```
