#!/usr/bin/env bash

curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"query": "{ systemStatus { memoryUsage diskSpace cpuLoad uptime } }"}' \
  http://localhost:8000/graphql
