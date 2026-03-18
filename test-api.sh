#!/bin/bash

# Test script for Grocery List API

BASE_URL="http://localhost:8080"

echo "=== Testing Grocery List API ==="
echo ""

# Test 1: Health Check
echo "1. Testing Health Endpoint..."
curl -s "$BASE_URL/health" | jq .
echo -e "\n"

# Test 2: Create grocery list for Alice
echo "2. Creating grocery list for Alice..."
curl -s -X POST "$BASE_URL/groceries" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "alice",
    "items": ["apples", "oranges", "bananas", "grapes"]
  }' | jq .
echo -e "\n"

# Test 3: Create grocery list for Bob
echo "3. Creating grocery list for Bob..."
curl -s -X POST "$BASE_URL/groceries" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "bob",
    "items": ["chicken", "rice", "vegetables", "soy sauce"]
  }' | jq .
echo -e "\n"

# Test 4: Create another list for Alice
echo "4. Adding more items for Alice..."
curl -s -X POST "$BASE_URL/groceries" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "alice",
    "items": ["milk", "bread", "eggs"]
  }' | jq .
echo -e "\n"

# Test 5: Get Alice's grocery list
echo "5. Getting Alice's grocery list..."
curl -s "$BASE_URL/groceries?username=alice" | jq .
echo -e "\n"

# Test 6: Get Bob's grocery list
echo "6. Getting Bob's grocery list..."
curl -s "$BASE_URL/groceries?username=bob" | jq .
echo -e "\n"

# Test 7: Get metrics
echo "7. Getting Prometheus metrics (first 30 lines)..."
curl -s "$BASE_URL/metrics" | head -n 30
echo -e "\n"

echo "=== Tests Complete ==="

