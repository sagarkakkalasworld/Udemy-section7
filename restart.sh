#!/bin/bash
ssh ubuntu@17.12.34.14 "microk8s kubectl rollout restart deployment react-deployment -n react-microk8s" ##update the private IP

