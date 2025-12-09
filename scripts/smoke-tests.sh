#!/bin/bash

# Smoke tests for deployed services
# Usage: ./smoke-tests.sh <devops_api_url> <rag_api_url>

DEVOPS_API=$1
RAG_API=$2

if [ -z "$DEVOPS_API" ] || [ -z "$RAG_API" ]; then
  echo "Usage: $0 <devops_api_url> <rag_api_url>"
  exit 1
fi

echo "🧪 Running Smoke Tests..."

# Test 1: DevOps Assistant API
echo -e "\n📍 Testing DevOps Assistant API..."
RESPONSE=$(curl -s -X POST "$DEVOPS_API" \
  -H "Content-Type: application/json" \
  -d '{"log": "Error: connection timeout"}' \
  --max-time 10)

if echo "$RESPONSE" | grep -q "analysis\|error"; then
  echo "✅ DevOps Assistant API is responding"
else
  echo "⚠️  DevOps Assistant API response unexpected: $RESPONSE"
fi

# Test 2: RAG Service Upload API
echo -e "\n📍 Testing RAG Service Upload API..."
CONTENT=$(echo "Test document for RAG" | base64)
RESPONSE=$(curl -s -X POST "${RAG_API}upload" \
  -H "Content-Type: application/json" \
  -d "{\"filename\": \"test.txt\", \"content_base64\": \"$CONTENT\"}" \
  --max-time 10)

if echo "$RESPONSE" | grep -q "indexed\|error"; then
  echo "✅ RAG Service Upload API is responding"
else
  echo "⚠️  RAG Service Upload API response unexpected: $RESPONSE"
fi

# Test 3: RAG Service Query API
echo -e "\n📍 Testing RAG Service Query API..."
RESPONSE=$(curl -s -X POST "${RAG_API}query" \
  -H "Content-Type: application/json" \
  -d '{"question": "What is this document about?"}' \
  --max-time 10)

if echo "$RESPONSE" | grep -q "answer\|error"; then
  echo "✅ RAG Service Query API is responding"
else
  echo "⚠️  RAG Service Query API response unexpected: $RESPONSE"
fi

echo -e "\n✅ Smoke tests completed!"
