# インスタンスに使用するイメージ
data "google_compute_image" "image" {
  family  = "centos-8"
  project = "centos-cloud"
}

# インスタンスに紐づけるIPアドレス
resource "google_compute_address" "instance-address" {
  name = "instance-address"
}

# ロードバランサに紐づけるIPアドレス
resource "google_compute_global_address" "lb-address" {
  name = "lb-address"
}

# インスタンス
resource "google_compute_instance" "instance" {
  name         = "instance"

  // マシンタイプは用途に応じて
  machine_type = "g1-small"

  // せっかくなら大阪使いたい
  zone         = "asia-northeast2-a"

  // このタグを後述のFWの指定に利用している
  tags = ["http-server"]

  // 起動ディスクの指定
  boot_disk {
    initialize_params {
      // 起動ディスクは最初に取得したイメージを利用
      image = data.google_compute_image.image.self_link
    }
  }

  // ネットワーク回りの設定
  network_interface {
    network = "default"
    access_config {
      // nat_ip を指定することでインスタンスのグローバルIPアドレスを固定
      nat_ip = google_compute_address.instance-address.address
    }
  }
}

# 非マネージドインスタンスグループ
# LBにインスタンスを紐づけることはできず、インスタンスグループにする必要がある
# なお、GCPにはマネージドインスタンスグループというのもあり、そっちの方がモダン
resource "google_compute_instance_group" "instance-group" {
  name        = "instance-group"

  // インスタンスグループに登録するインスタンスを指定
  instances = [
    google_compute_instance.instance.self_link,
  ]

  zone = "asia-northeast2-a"
}

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

# HTTP転送ターゲット
resource "google_compute_target_http_proxy" "target-http-proxy" {
  name             = "target-http-proxy"
  url_map          = google_compute_url_map.url-map.self_link
}

# 転送ルールの作成
resource "google_compute_global_forwarding_rule" "global-forwarding-rule-http" {
  name       = "global-forwarding-rule-http"
  target     = google_compute_target_http_proxy.target-http-proxy.self_link
  port_range = "80"
  ip_address = google_compute_global_address.lb-address.address
}

# ネットワーク設定の情報取得
data "google_compute_network" "default" {
  name = "default"
}

# ファイアウォール設定
resource "google_compute_firewall" "firewall" {
  name    = "http"
  network = data.google_compute_network.default.name

  // インスタンスに紐づけたタグを指定
  target_tags = ["http-server"]

  // LBからのヘルスチェックの接続を許可
  // これをしないとヘルスチェックがNGになり表示できない。
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
}

# ロードバランサに紐づいたIPアドレスの出力
output "lb-ipaddress" {
  value = google_compute_global_address.lb-address.address
}

# インスタンスに紐づいたIPアドレスの出力
output "instance-ipaddress" {
  value = google_compute_address.instance-address.address
}