#!/bin/bash
ssh ubuntu@172.31.31.45 "microk8s kubectl rollout restart deployment react-deployment -n react-microk8s" ##update the AWS private IP

