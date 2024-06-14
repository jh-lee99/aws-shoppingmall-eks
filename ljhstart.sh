#!/bin/bash

set -eu

maindir="$HOME/aws-shoppingmall-eks"

cd $maindir/tf-eks

export AWS_ACCOUNT=654654416925

export AWS_REGION=ap-northeast-1

export EKS_MANAGED_NODE_GROUPS=$(terraform output -json eks_managed_node_groups | jq -r '.base.iam_role_name')

export EKS_INSTANCE_PROFILE=$(aws iam list-instance-profiles | jq -r --arg eks_managed_node_groups "$EKS_MANAGED_NODE_GROUPS" '.InstanceProfiles[] | select(.Roles[].RoleName | startswith($eks_managed_node_groups)) | .InstanceProfileName')

export EKS_CLUSTER_NAME=$(terraform output cluster_name)

export EKS_CLUSTER_ENDPOINT=$(terraform output cluster_endpoint)

export EKS_KARPENTER_QUEUE_NAME=$(terraform output karpenter_queue_name)

aws eks --region $AWS_REGION update-kubeconfig --name $(terraform output -raw cluster_name)

echo "export AWS_ACCOUNT=$AWS_ACCOUNT"

echo "export EKS_MANAGED_NODE_GROUPS=$EKS_MANAGED_NODE_GROUPS"

echo "export EKS_INSTANCE_PROFILE=$EKS_INSTANCE_PROFILE"

echo "export EKS_CLUSTER_NAME=$EKS_CLUSTER_NAME"

echo "export EKS_CLUSTER_ENDPOINT=$EKS_CLUSTER_ENDPOINT"

echo "export EKS_KARPENTER_QUEUE_NAME=$EKS_KARPENTER_QUEUE_NAME"

KARPENTER_VALUES="$HOME/aws-shoppingmall-eks/karpenter/karpenter-v0.27.0/my-values.yaml"

sed -i "s|clusterEndpoint: .*|clusterEndpoint: $EKS_CLUSTER_ENDPOINT|g" $KARPENTER_VALUES
sed -i "s|clusterName: .*|clusterName: $EKS_CLUSTER_NAME|g" $KARPENTER_VALUES
sed -i "s|defaultInstanceProfile: .*|defaultInstanceProfile: $EKS_INSTANCE_PROFILE|g" $KARPENTER_VALUES
sed -i "s|interruptionQueueName: .*|interruptionQueueName: $EKS_KARPENTER_QUEUE_NAME|g" $KARPENTER_VALUES
sed -i "s|interruptionQueue: .*|interruptionQueue: $EKS_KARPENTER_QUEUE_NAME|g" $KARPENTER_VALUES

# 해당 명령어를 실행하기 위해서 sealed-secrets-key-backup.yaml 파일의 생성이 필요하다.
# kubectl apply -f $maindir/sealed-secrets/sealed-secrets-key-backup.yaml
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.26.3/controller.yaml

echo 'helm install aws-load-balancer-controller -n kube-system -f $HOME/aws-shoppingmall-eks/aws-load-balancer-controller/ci/my-values.yaml $HOME/aws-shoppingmall-eks/aws-load-balancer-controller/.'
helm install aws-load-balancer-controller -n kube-system -f $HOME/aws-shoppingmall-eks/aws-load-balancer-controller/ci/my-values.yaml $HOME/aws-shoppingmall-eks/aws-load-balancer-controller/.
sleep 60

echo 'helm install external-dns -n kube-system -f $HOME/aws-shoppingmall-eks/external-dns/ci/my-values.yaml $HOME/aws-shoppingmall-eks/external-dns/.'
helm install external-dns -n kube-system -f $HOME/aws-shoppingmall-eks/external-dns/ci/my-values.yaml $HOME/aws-shoppingmall-eks/external-dns/.
sleep 5

echo 'helm install metrics-server -n kube-system -f $HOME/aws-shoppingmall-eks/metrics-server-3.12.1/ci/values.yaml $HOME/aws-shoppingmall-eks/metrics-server-3.12.1/.'
helm install metrics-server -n kube-system -f $HOME/aws-shoppingmall-eks/metrics-server-3.12.1/ci/values.yaml $HOME/aws-shoppingmall-eks/metrics-server-3.12.1/.
sleep 5

echo 'helm install karpenter -n karpenter --create-namespace -f $HOME/aws-shoppingmall-eks/karpenter/karpenter-v0.27.0/my-values.yaml $HOME/aws-shoppingmall-eks/karpenter/karpenter-v0.27.0/.'
helm install karpenter -n karpenter --create-namespace -f $HOME/aws-shoppingmall-eks/karpenter/karpenter-v0.27.0/my-values.yaml $HOME/aws-shoppingmall-eks/karpenter/karpenter-v0.27.0/.
sleep 30

#sed -i "s|instanceProfile: .*|instanceProfile: $EKS_INSTANCE_PROFILE|g" $HOME/aws-shoppingmall-eks/karpenter/awsNodeTemplate.yaml
echo 'kubectl apply -f $HOME/aws-shoppingmall-eks/karpenter/provisioner.yaml -f $HOME/aws-shoppingmall-eks/karpenter/awsNodeTemplate.yaml'
sleep 15
kubectl apply -f $HOME/aws-shoppingmall-eks/karpenter/provisioner.yaml -f $HOME/aws-shoppingmall-eks/karpenter/awsNodeTemplate.yaml
sleep 10

echo 'helm install argocd -n argocd --create-namespace -f $HOME/aws-shoppingmall-eks/argo-cd-v5.14.1/argo-cd/ci/jh-test-values.yaml $HOME/aws-shoppingmall-eks/argo-cd-v5.14.1/argo-cd/.'
helm install argocd -n argocd --create-namespace -f $HOME/aws-shoppingmall-eks/argo-cd-v5.14.1/argo-cd/ci/jh-test-values.yaml $HOME/aws-shoppingmall-eks/argo-cd-v5.14.1/argo-cd/.
kubectl create namespace argo-rollouts
kubectl apply -f $maindir/argo-cd-v5.14.1/ljh-backend-shop-login-dev.yaml -f $maindir/argo-cd-v5.14.1/ljh-backend-shop-login-prod.yaml
kubectl apply -f $maindir/argo-cd-v5.14.1/ljh-front-shop-main-dev.yaml -f $maindir/argo-cd-v5.14.1/ljh-front-shop-main-prod.yaml
#kubectl apply -f $maindir/argo-cd-v5.14.1/ljh-was-login.yaml
sleep 10
kubectl apply -n argo-rollouts -f https://raw.githubusercontent.com/argoproj/argo-rollouts/stable/manifests/install.yaml

echo 'helm install prometheus -n monitoring --create-namespace -f $HOME/aws-shoppingmall-eks/prometheus/kube-prometheus-stack-58.6.0/ci/my-values.yaml $HOME/aws-shoppingmall-eks/prometheus/kube-prometheus-stack-58.6.0/.'
#helm install prometheus -n monitoring --create-namespace -f $HOME/aws-shoppingmall-eks/prometheus/kube-prometheus-stack-58.6.0/ci/my-values.yaml $HOME/aws-shoppingmall-eks/prometheus/kube-prometheus-stack-58.6.0/.
#sleep 5

echo 'helm install loki-stack -n monitoring --create-namespace $HOME/helm-charts/charts/loki-stack/.'


