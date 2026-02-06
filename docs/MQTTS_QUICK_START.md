# 🚀 MQTTS Quick Start Guide

Get started with secure MQTT connections in 5 minutes.

## Prerequisites

- IoTify Platform app installed
- MQTT broker with SSL/TLS support
- Certificate files (if required)

---

## Step 1: Open Broker Configuration

1. Launch IoTify Platform
2. Navigate to **Brokers** tab
3. Tap **+ Add Broker**

## Step 2: Basic Connection

Enter broker details:

```
Name: My Secure Broker
Host: mqtt.example.com
Port: 8883 (will auto-change when SSL enabled)
```

## Step 3: Enable SSL/TLS

Toggle the **SSL/TLS** switch:

```
SSL/TLS: ON
Port: 1883 → 8883 (automatic)
```

## Step 4: Choose Certificate Type

Select based on your broker's requirements:

### Option A: No Certificate (Quick Test)

```
Certificate Type: None
Security: Low
Use Case: Testing only
```

### Option B: CA Signed (Recommended)

```
Certificate Type: CA Signed
Security: High
Use Case: Production

Required:
└── Upload CA Certificate (.pem, .crt)
```

### Option C: Client Certificate (Mutual TLS)

```
Certificate Type: Client Cert
Security: Very High
Use Case: Enterprise/Financial

Required:
├── Upload CA Certificate
├── Upload Client Certificate
└── Upload Private Key
```

### Option D: Self-Signed (Development Only)

```
Certificate Type: Self-Signed
Security: Medium
Use Case: Internal networks

⚠️ Warning: Accepts all certificates
```

## Step 5: Upload Certificates

Tap certificate field and select file:

```
📁 Supported Formats:
├── .pem (Privacy-Enhanced Mail)
├── .crt (Certificate)
├── .ca-bundle (CA Chain)
└── .key (Private Key)
```

## Step 6: Test Connection

1. Tap **Test Connection** icon (📶)
2. Wait for connection result
3. Check logs if failed

**Success Indicators:**
- ✅ "Connection successful!" message
- Status shows "Connected"

## Step 7: Save Broker

Tap **Save Broker** to store configuration.

---

## Example: HiveMQ Cloud with TLS

### 1. Get Certificates from HiveMQ

1. Log in to [HiveMQ Cloud](https://cloud.hivemq.com)
2. Navigate to **Access Management** → **Credentials**
3. Download CA Certificate or create client certificates

### 2. Configure Broker

```
Name: HiveMQ Cloud
Host: YOUR_CLUSTER.s1.eu.hivemq.cloud
Port: 8883
SSL/TLS: ON
Certificate Type: CA Signed
```

### 3. Upload Certificate

1. Download `ca.crt` from HiveMQ
2. Upload in IoTify Platform
3. Test connection

---

## Example: Mosquitto with Self-Signed

### 1. Generate Self-Signed Certificate

```bash
# Generate CA
openssl req -new -x509 -days 365 -keyout ca.key -out ca.crt

# Generate server certificate
openssl genrsa -out server.key 2048
openssl req -new -key server.key -out server.csr
openssl x509 -req -days 365 -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt
```

### 2. Configure in IoTify

```
Name: Local Mosquitto
Host: localhost
Port: 8883
SSL/TLS: ON
Certificate Type: Self-Signed
```

### 3. Test Connection

Works without uploading certificates (accepts self-signed).

---

## Troubleshooting

### "Connection Failed"

**Check:**
- [ ] Host and port correct
- [ ] Broker is running
- [ ] Network connectivity
- [ ] Certificates valid

### "Certificate Verification Failed"

**Solutions:**
- Try "Self-Signed" mode for testing
- Check CA certificate is correct
- Verify certificate not expired

### "Timeout"

**Solutions:**
- Check firewall rules (port 8883)
- Verify broker SSL configuration
- Try without SSL first

---

## Levels

| Certificate Security Type | Security | Encryption | Authentication | Use Case |
|------------------|----------|------------|----------------|----------|
| **None** | Basic | TLS | Server only | Development |
| **CA Signed** | High | TLS | Server + CA | Production |
| **Client Cert** | Very High | TLS | Mutual (both) | Enterprise |
| **Self-Signed** | Medium | TLS | Server only | Internal |

---

## Next Steps

1. [Read full Security Documentation](SECURITY.md)
2. [Configure Rule Engine](RULE_ENGINE.md)
3. [Set up Notifications](ALARM_SYSTEM.md)

---

**Need Help?** Check the [main Security Documentation](SECURITY.md) for detailed information.
