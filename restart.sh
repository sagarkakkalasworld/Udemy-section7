#!/bin/bash
ssh ubuntu@172.31.30.63 "microk8s kubectl rollout restart deployment react-deployment -n react-microk8s" ##update the private IP

