#!/bin/bash
# WhatsApp Webhook Test Script
# Simulasi berbagai format payload OpenWA

API_URL="https://api.glicoo.my.id/api/v1/bot/webhook/whatsapp"

echo ""
echo "=========================================="
echo "  WhatsApp Webhook Test Script"
echo "=========================================="
echo ""

# Format 1: Standard format (sudah di-support)
echo "━━━ TEST 1: Format 1 (standard message) ━━━"
curl -s -w "\nHTTP %{http_code}" -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -H "User-Agent: OpenWA-Webhook/1.0.0" \
  -d '{
    "message": {
      "from": "6289672585765@c.us",
      "body": "Halo, ini test dari Format 1",
      "timestamp": 1719678000
    }
  }'
echo -e "\n"

# Format 2: OpenWA baileys format (key.remoteJid + message.conversation)
echo "━━━ TEST 2: Format 2 (baileys key/conversation) ━━━"
curl -s -w "\nHTTP %{http_code}" -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -H "User-Agent: OpenWA-Webhook/1.0.0" \
  -d '{
    "data": {
      "key": {
        "remoteJid": "6289672585765@c.us",
        "fromMe": false,
        "id": "ABC123"
      },
      "message": {
        "conversation": "Halo, ini test dari Format 2"
      }
    }
  }'
echo -e "\n"

# Format 3: data.from + data.body
echo "━━━ TEST 3: Format 3 (data.from/data.body) ━━━"
curl -s -w "\nHTTP %{http_code}" -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -H "User-Agent: OpenWA-Webhook/1.0.0" \
  -d '{
    "data": {
      "from": "6289672585765@c.us",
      "body": "Halo, ini test dari Format 3"
    }
  }'
echo -e "\n"

# Format 4: array messages
echo "━━━ TEST 4: Format 4 (messages array) ━━━"
curl -s -w "\nHTTP %{http_code}" -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -H "User-Agent: OpenWA-Webhook/1.0.0" \
  -d '{
    "messages": [
      {
        "from": "6289672585765@c.us",
        "body": "Halo, ini test dari Format 4",
        "timestamp": 1719678000
      }
    ]
  }'
echo -e "\n"

# OTP Test dengan Format 1
echo "━━━ TEST 5: OTP Verification (Format 1) ━━━"
curl -s -w "\nHTTP %{http_code}" -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -H "User-Agent: OpenWA-Webhook/1.0.0" \
  -d '{
    "message": {
      "from": "6289672585765@c.us",
      "body": "OTP 123456",
      "timestamp": 1719678000
    }
  }'
echo -e "\n"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Cek Vercel logs
echo "Cek Vercel logs untuk lihat raw payload:"
echo "https://vercel.com/dashboard"
echo ""
