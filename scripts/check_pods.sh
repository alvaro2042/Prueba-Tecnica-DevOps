#!/bin/bash
NAMESPACE="default"

crash_pods=$(kubectl get pods -n $NAMESPACE --field-selector=status.phase!=Running -o jsonpath='{.items[*].metadata.name}')

if [[ -n "$crash_pods" ]]; then
    echo "Pods with issues:"
    echo "$crash_pods"
    exit 1
else
    echo "All pods are running correctly."
fi
