# aws-shoppingmall-eks

## 프로젝트 명칭
레이디 헵번 쇼핑몰 클라우드 전환 프로젝트

## 프로젝트 목표
- 지속적으로 성장하는 사업 환경 변화에 대응 가능한 인프라를 구축한다.
- 자동화된 CI/CD 파이프라인을 구축하여 '핵심 비즈니스 집중'이라는 고객의 요구사항을 충족한다.
- 서비스의 안정적 품질 제공을 위해 컨테이너 오케스트레이션 도구를 도입하여 서비스의 가용성 및 내결함성을 제공한다.

## 개발환경 & 사용 기술
AWS, Terraform, EKS, Docker, git, github, Slack, Grafana, Prometheus, Loki, Github action, Argo CD...

## 구현과정
1. AWS EKS 기반의 복원력과 확장성을 가진 3-Tier 아키텍처 구축
2. Terraform 및 GitOps 전략을 통한 선언적 인프라 관리
3. EKS 및 데이터베이스를 포함한 인프라 모니터링 시스템 구축
4. 멀티 리전에 위치한 서비스 통합 대시보드 구축
5. 자동화된 클라우드 인프라 변경사항 추적 및 보고 시스템 구축

## 수행기간
2024. 04. 22 ~ 2024. 06. 25 (65 일간)

## 참여인원
4 명

## 담당업무
- 개인과제 구축 (3-Tier, CI/CD, 모니터링, 백업, 보안, ...)
- 아키텍처 설계 및 프로토타입 구현(PM 역할, PoC 수행)
- Cloud 인프라 변경이력 추적 및 보고(CloudTrail, Slack)
- 이중화 DB 성능지표 수집 및 상태검사(PLK 스택, Slack 알람)

## 프로젝트 결과
동시접속 사용자 약 50,000 명 이상을 수용할 수 있는 인프라적 소방을 완료하여 구축하였다.

---

본 프로젝트는 대규모 사용자를 지원할 수 있는 확장 가능하고 안정적인 클라우드 인프라를 구축하는 것을 목표로 합니다. AWS EKS를 기반으로 한 환경에서 Terraform과 GitOps 전략을 활용하여 인프라를 관리하며, 자동화된 CI/CD 파이프라인을 통해 효율적인 서비스 배포와 운영을 지원합니다.

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
