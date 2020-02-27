# サンプルコード集
記事などで記載する terraform のサンプルコードの置き場

## 注意事項
作成時に簡単な確認はしていますが、動作保証はいたしません。  
ご自身の責任の下、ご利用ください。

## 各サンプル
現在は下記のサンプルがあります。

### GCPでのロードバランサ構築（HTTPのみ） [gcp-lb](https://github.com/toshekey/terraform-sample/tree/master/gcp-lb)
HTTPのみ解放したロードバランサを terraform で作成するコードです。  
なお、terraform では GCP のロードバランサを作るには複数のリソースを
組み合わせる必要があります。