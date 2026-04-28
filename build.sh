#!/bin/bash
set -e

echo "Building HumanSafety Server..."
cd server
npm install --production
echo "Build complete"
