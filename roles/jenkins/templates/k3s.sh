#!/bin/bash
set -e

IMAGE_NAME="$1"
REPLICAS="$2"
PORTS="$3"
LIMIT_MEM="$4"
REQ_MEM="$5"

if [[ -z "$IMAGE_NAME" || -z "$REPLICAS" || -z "$PORTS" || -z "$LIMIT_MEM" || -z "$REQ_MEM" ]]; then
    echo "Usage: $0 <IMAGE_NAME> <REPLICAS> <PORTS> <LIMIT_MEM> <REQ_MEM>"
    exit 1
fi

DEPLOY_NAME="whanos-deployment"
SERVICE_NAME="whanos-service"

TMP_DEPLOY_FILE="/tmp/whanos-deployment-$$.yaml"

cat <<EOF > "$TMP_DEPLOY_FILE"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $DEPLOY_NAME
  labels:
    app: $DEPLOY_NAME
spec:
  replicas: $REPLICAS
  selector:
    matchLabels:
      app: $DEPLOY_NAME
  template:
    metadata:
      labels:
        app: $DEPLOY_NAME
    spec:
      containers:
      - name: $DEPLOY_NAME
        image: $IMAGE_NAME
        ports:
$(for port in $PORTS; do echo "        - containerPort: $port"; done)
        resources:
          limits:
            memory: "$LIMIT_MEM"
          requests:
            memory: "$REQ_MEM"
EOF

TMP_SERVICE_FILE="/tmp/whanos-service-$$.yaml"

cat <<EOF > "$TMP_SERVICE_FILE"
apiVersion: v1
kind: Service
metadata:
  name: $SERVICE_NAME
spec:
  selector:
    app: $DEPLOY_NAME
  ports:
$(for port in $PORTS; do echo "  - protocol: TCP"; echo "    port: $port"; echo "    targetPort: $port"; done)
  type: ClusterIP
EOF


echo "Deploying $DEPLOY_NAME with replicas: $REPLICAS, ports: $PORTS..."
kubectl apply -f "$TMP_DEPLOY_FILE"

echo "Creating service '$SERVICE_NAME'..."
kubectl apply -f "$TMP_SERVICE_FILE"

echo "Waiting for deployment '$DEPLOY_NAME' to become ready..."
if ! kubectl rollout status deployment/"$DEPLOY_NAME"; then
    echo "Error: Deployment rollout failed!"
    exit 1
fi

echo "Deployment '$DEPLOY_NAME' and Service '$SERVICE_NAME' successfully applied and verified!"
rm -f "$TMP_DEPLOY_FILE" "$TMP_SERVICE_FILE"
