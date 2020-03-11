# NAT用のIPアドレス 
resource "google_compute_address" "private-nat-ipaddress" {
  name = "private-nat-ipaddress"
  region = "us-central1"
}

# ロードバランサに紐づけるIPアドレス
resource "google_compute_global_address" "lb-address" {
  name = "lb-address"
}

# VPC（必須ではない。）
resource "google_compute_network" "private_network" {
  name = "private-network"
}

# サブネット（必須ではない。）
resource "google_compute_subnetwork" "private-subnetwork" {
  name          = "private-subnetwork"
  network       = google_compute_network.private_network.self_link
  ip_cidr_range = "10.0.0.0/16"
  region        = "us-central1"
}

// VPC用ルータ（必須ではない。）
resource "google_compute_router" "private-router" {
  name    = "private-router"
  region  = google_compute_subnetwork.private-subnetwork.region
  network = google_compute_network.private_network.self_link

  bgp {
    asn = 64514
  }
}

// Cloud NAT（必須ではない。）
resource "google_compute_router_nat" "private-nat" {
  name                               = "private-router-nat"
  router                             = google_compute_router.private-router.name
  region                             = google_compute_router.private-router.region
  nat_ip_allocate_option = "MANUAL_ONLY"
  nat_ips                = [google_compute_address.private-nat-ipaddress.self_link]

  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

// IAP用ファイアウォール
resource "google_compute_firewall" "private_network_firewall" {
  name    = "private-firewall"
  network = google_compute_network.private_network.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"

    // 本来、TCP全てを許可するようがLB経由でHTTPSを表示させる際に
    // LB以外からの80番へのアクセスを遮断するように言われるので必要なポートのみ開放する。
    ports = ["22"]
  }

  // IAP で必要な許可送信元アドレス
  source_ranges= ["35.235.240.0/20"]
  target_tags = ["gw"]
}

// ヘルスチェック用ファイアウォール
resource "google_compute_firewall" "healthcheck_firewall" {
  name    = "healthcheck-firewall"
  network = google_compute_network.private_network.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports = ["80"]
  }

  // LBの送信元IPアドレス
  source_ranges= ["35.191.0.0/16", "130.211.0.0/22"]
  target_tags = ["gw"]
}