# aws-shoppingmall-eks
MZC 최종 프로젝트에서 사용한 테라폼 파일과 매니페스트 파일을 제외한 전체 파일입니다.
## 사용방법.
몇 가지의 민감 정보가 변수로 대체되어 있습니다.

ex) slack-token: { { YOUR_SLACK_TOKEN } }

ex) api_url: { { YOUR_SLACK_WEBHOOK_URL } }

ex) channel: { { YOUR_SLACK_CHANNEL } }

ex) ljh-DB-key.pem

## ljhstart.sh 스크립트 파일 실행 이후 수행해야 할 명령어
kubectl get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml > sealed-secrets-key-backup.yaml
