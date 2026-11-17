#!/bin/bash
if quickshell ipc -c panel call panel toggle >/dev/null 2>&1; then
    exit 0
fi
quickshell -c panel >/dev/null 2>&1 &
sleep 0.8
quickshell ipc -c panel call panel open >/dev/null 2>&1 || true
