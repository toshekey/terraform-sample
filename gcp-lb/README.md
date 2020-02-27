# GCPでのロードバランサ構築（HTTPのみ）

## 概要
GCP でロードバランサを構築する際のサンプルコードです。  
terraform の GCP プロバイダではロードバランサというリソースがなく、
複数のリソースを組み合わせる必要があるので、それの参考になればと思います。

## Requirement
* terraform
* GCPのプロジェクト
* GCPのサービスアカウント
  * JSON形式の認証ファイルを取得してください。 

## ファイルの説明

| ファイル名 | 用途 |
| ---- | ---- |
| terraform.tfvars | 変数記載用ファイル（新規作成）|
| provider.tf | プロバイダ情報 |
| lb_instance.tf | 設定ファイル |

## How to
1. terraform.tfvars を作成
```terraform.tfvars
AUTH_FILE = "<サービスアカウントの認証用ファイル>"
PROJECT_ID = "<GCPのプロジェクトID>"
REGION = "<GCPのデフォルトリージョン>"
```
2. 初期化
```
terraform init
```

3. Dry-Run & 実行
```
terraform plan
terraform apply
```