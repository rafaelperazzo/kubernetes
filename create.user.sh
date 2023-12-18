#!/bin/bash
#https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/#normal-user
openssl genrsa -out $1.key 2048
openssl req -new -key $1.key -out $1.csr -subj "/CN=$1"

cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: $1
spec:
  request: $(cat $1.csr | base64 | tr -d '\n')
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400  # one day
  usages:
  - client auth
EOF

kubectl get csr
kubectl certificate approve $1
kubectl get csr/$1 -o yaml
kubectl get csr $1 -o jsonpath='{.status.certificate}'| base64 -d > $1.crt
kubectl create role developer --verb=create --verb=get --verb=list --verb=update --verb=delete --resource=pods,deployments,services,ingress
kubectl create rolebinding developer-binding-$1 --role=developer --user=$1
kubectl --kubeconfig $1-kube-config config set-credentials $1 --client-key=$1.key --client-certificate=$1.crt --embed-certs=true
kubectl --kubeconfig $1-kube-config config set-context $1 --cluster=kubernetes --user=$1
#kubectl config use-context $1
