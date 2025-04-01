Blog: https://medium.com/@tradingcontentdrive/deploying-awx-on-kubernetes-with-kind-and-awx-operator-in-10-steps-c757e9f78095

kind create cluster --name=multi-node-cluster --config=kind-config

apt update && apt install -y make
kubectl create namespace awx
git checkout tags/2.19.1
make deploy

- Deploy AWX Instance
cat <<EOF | kubectl apply -f -
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx
  namespace: awx
spec:
  service_type: NodePort
  ingress_type: none
  hostname: awx.local
  projects_persistence: false
EOF


kubectl get pods -n awx -w
kubectl get svc -n awx
kubectl patch svc awx-service -n awx -p '{"spec": {"type": "NodePort", "ports": [{"port": 80, "targetPort": 80, "protocol": "TCP", "nodePort": 30000}]}}'

- Get admin password
kubectl get secret awx-admin-password -n awx -o jsonpath="{.data.password}" | base64 --decode
