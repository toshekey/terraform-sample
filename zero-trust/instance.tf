# ブートさせるディスクイメージ
data "google_compute_image" "boot_image" {
  name = "centos-8-v20191210"
  project = "centos-cloud"
}

// インスタンス
resource "google_compute_instance" "instance" {
    name = "gw"
    machine_type = "f1-micro"
    zone = "us-central1-a"

  boot_disk {
    initialize_params {
      image = data.google_compute_image.boot_image.self_link
    }
  }

  network_interface {
    network = google_compute_network.private_network.self_link
  }
  tags = ["gw"]
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

  zone = "us-central1-a"
}