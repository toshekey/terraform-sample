provider "google" {
  credentials = file(var.AUTH_FILE)
  project     = var.PROJECT_ID
  region      = var.REGION
}
