#!/bin/bash

echo "🧪 TESTS APPLICATION MICROSERVICES"
echo "==================================="

URL="http://192.168.56.10:30080"

echo ""
echo "Test 1: Users..."
curl -s $URL/api/users

echo ""
echo ""
echo "Test 2: Posts..."
curl -s $URL/api/posts

echo ""
echo ""
echo "Test 3: Créer un user..."
curl -s -X POST $URL/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","email":"test@test.com"}'

echo ""
echo ""
echo "Test 4: Créer un post (communication inter-microservices)..."
curl -s -X POST $URL/api/posts \
  -H "Content-Type: application/json" \
  -d '{"user_id":1,"title":"Test","content":"Communication entre microservices"}'

echo ""
echo ""
echo "==================================="
echo "✅ Tests terminés"
echo "Interface web: $URL"
