# aws-shoppingmall-eks

MZC 최종 프로젝트에서 사용한 테라폼 파일과 매니페스트 파일을 제외한 전체 파일입니다.

## 3-Tier 구성도 / 백업 / 리소스 최적화

![3-Tier 백업 비소스 최적화](https://github.com/user-attachments/assets/fb3926d9-1dbf-45a1-a149-e943dc3288b1)

## 모니터링

![모니터링](https://github.com/user-attachments/assets/7b31f347-5191-4537-b18d-8b1728f4e25f)


## CI/CD 파이프라인

![CICD 파이프라인](https://github.com/user-attachments/assets/7e0702c9-9810-42a9-9d26-7cb9ffa12495)


## 사용방법.

몇 가지의 민감 정보가 변수로 대체되어 있습니다.

ex) slack-token: { { YOUR_SLACK_TOKEN } }

ex) api_url: { { YOUR_SLACK_WEBHOOK_URL } }

ex) channel: { { YOUR_SLACK_CHANNEL } }

ex) ljh-DB-key.pem

## ljhstart.sh 스크립트 파일 실행 이후 수행해야 할 명령어
kubectl get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml > sealed-secrets-key-backup.yaml
