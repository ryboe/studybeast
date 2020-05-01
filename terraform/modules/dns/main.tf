// dns module

resource "google_dns_managed_zone" "public" {
  name        = "${replace(var.domain, ".", "-")}-public" # e.g. ryanboehning-com-public
  dns_name    = "${var.domain}."
  description = "The main public DNS zone"
  visibility  = "public"
}

resource "google_dns_record_set" "domain_ownership_verification" {
  name         = "google-domain-ownership-verification"
  managed_zone = google_dns_managed_zone.public.name
  type         = "TXT"
  ttl          = 86400 # 24 hours
  rrdatas      = ["${var.domain_ownership_verification_token}"]
}

resource "google_dns_record_set" "nameservers" {
  name         = "google-nameservers"
  managed_zone = google_dns_managed_zone.public.name
  type         = "NS"
  ttl          = 21600 # 6 hours
  rrdatas = [
    "ns-cloud-c1.googledomains.com.",
    "ns-cloud-c2.googledomains.com.",
    "ns-cloud-c3.googledomains.com.",
    "ns-cloud-c4.googledomains.com.",
  ]
}
