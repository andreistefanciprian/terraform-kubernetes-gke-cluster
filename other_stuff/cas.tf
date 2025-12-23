# Infrastructure used by cert-manager Google CAS Issuer: https://github.com/andreistefanciprian/flux-demo/tree/main/infra/cert-manager

# Enable Certificate Authority Service API
resource "google_project_service" "privateca" {
  service            = "privateca.googleapis.com"
  disable_on_destroy = true
}

resource "google_privateca_ca_pool" "default" {
  name     = "my-pool"
  location = var.gcp_region
  tier     = "ENTERPRISE"
  publishing_options {
    publish_ca_cert = true
    publish_crl     = true
  }
  labels = {
    foo = "bar"
  }
  depends_on = [google_project_service.privateca]
}

resource "google_privateca_certificate_authority" "main" {
  pool                                   = google_privateca_ca_pool.default.name
  certificate_authority_id               = "${var.domain_organization}-certificate-authority"
  location                               = var.gcp_region
  deletion_protection                    = false
  ignore_active_certificates_on_deletion = true
  config {
    subject_config {
      subject {
        organization = var.domain_organization
        common_name  = "my-ca"
      }
      subject_alt_name {
        dns_names = [var.domain_name]
      }
    }
    x509_config {
      ca_options {
        is_ca                  = true
        max_issuer_path_length = 10
      }
      key_usage {
        base_key_usage {
          digital_signature  = true
          content_commitment = true
          key_encipherment   = false
          data_encipherment  = true
          key_agreement      = true
          cert_sign          = true
          crl_sign           = true
          decipher_only      = true
        }
        extended_key_usage {
          server_auth      = true
          client_auth      = false
          email_protection = true
          code_signing     = true
          time_stamping    = true
        }
      }
    }
  }
  lifetime = "7776000s"
  key_spec {
    # algorithm = "RSA_PKCS1_4096_SHA256"
    algorithm = "EC_P384_SHA384"
  }
  depends_on = [google_privateca_ca_pool.default, google_project_service.privateca]
}

# Create a dedicated Google Service Account (SA) to be used by the CAS Issuer to access the Google Cloud CAS APIs
resource "google_service_account" "cas-issuer" {
  account_id   = "cas-issuer"
  display_name = "This SA will be impersonated by a CAS K8s SA to issue certifictes."
}

# Grant k8s SA permission to impersonate Google SA via workload identity
resource "google_service_account_iam_binding" "cas-service-account-iam" {
  service_account_id = google_service_account.cas-issuer.name
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "serviceAccount:${var.gcp_project}.svc.id.goog[cert-manager/cert-manager-google-cas-issuer]",
  ]
}
resource "google_privateca_ca_pool_iam_binding" "binding" {
  ca_pool = google_privateca_ca_pool.default.id
  role    = "roles/privateca.certificateRequester"
  members = [
    "serviceAccount:${google_service_account.cas-issuer.email}",
  ]
}