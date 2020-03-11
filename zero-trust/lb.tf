# バックエンドサービス用ヘルスチェック
resource "google_compute_health_check" "health-check" {
  name = "health-check"
  timeout_sec        = 1
  check_interval_sec = 1
  tcp_health_check {
    port = "80"
  }
}

# バックエンドサービス
resource "google_compute_backend_service" "backend-service" {
  name        = "backend-service"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 3000

  backend {
    group = google_compute_instance_group.instance-group.self_link
  }

  health_checks = [google_compute_health_check.health-check.self_link]
}

# URLマッピング
resource "google_compute_url_map" "url-map" {
  name        = "url-map"

  // 指定したルールに当てはまらない接続が流れるバックエンド
  // 今回は特にルールを指定していないので全てここに流れる
  default_service = google_compute_backend_service.backend-service.self_link
}

# 転送ルールの作成
resource "google_compute_global_forwarding_rule" "global-forwarding-rule-https" {
  name       = "global-forwarding-rule-https"
  target     = google_compute_target_https_proxy.target-https-proxy.self_link
  port_range = "443"
  ip_address = google_compute_global_address.lb-address.address
}

# HTTPS転送ターゲット
resource "google_compute_target_https_proxy" "target-https-proxy" {
  name             = "target-https-proxy"
  description      = "target-https-proxy"
  url_map          = google_compute_url_map.url-map.self_link
  ssl_certificates = [google_compute_managed_ssl_certificate.ssl.self_link]
}

# 証明書の作成（www.north-hill.site 用の証明書が作成されます。）
resource "google_compute_managed_ssl_certificate" "ssl" {
  provider = google-beta
  project = google_compute_instance.instance.project
  name = "ssl"
  managed {
    domains = var.domains
  }
}

# ロードバランサに紐づいたIPアドレスの出力
output "lb-ipaddress" {
  value = google_compute_global_address.lb-address.address
}