// SSH認証用ユーザ
data "google_iam_policy" "admin" {
  binding {
    role = "roles/iap.tunnelResourceAccessor"
    members = var.tunnel_auth_members
  }
}

// HTTPS認証用ユーザ
data "google_iam_policy" "https_admin" {
  binding {
    role = "roles/iap.httpsResourceAccessor"
    members = var.https_auth_members
  }
}

// SSH認証ポリシー
resource "google_iap_tunnel_instance_iam_policy" "auth_users" {
  project = google_compute_instance.instance.project
  zone = google_compute_instance.instance.zone
  instance = google_compute_instance.instance.name
  policy_data = data.google_iam_policy.admin.policy_data
}

// HTTPS認証ポリシー
resource "google_iap_web_backend_service_iam_policy" "auth_users" {
  project = google_compute_instance.instance.project
  web_backend_service = google_compute_backend_service.backend-service.name
  policy_data = data.google_iam_policy.https_admin.policy_data
}

