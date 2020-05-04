// dns module

resource "google_dns_managed_zone" "public" {
  name        = "${replace(var.domain, ".", "-")}-public-zone" # e.g. ryanboehning-com-public
  dns_name    = "${var.domain}."
  description = "The main public DNS zone"
  visibility  = "public"
}

resource "google_dns_record_set" "domain_ownership_verification" {
  name         = google_dns_managed_zone.public.dns_name
  managed_zone = google_dns_managed_zone.public.name
  type         = "TXT"
  ttl          = 86400 # 24 hours
  rrdatas      = ["${var.domain_ownership_verification_token}"]
}

resource "google_dns_record_set" "soa" {
  name         = google_dns_managed_zone.public.dns_name
  managed_zone = google_dns_managed_zone.public.name
  type         = "SOA"
  ttl          = 21600 # 6 hours
  rrdatas      = ["ns-cloud-c1.googledomains.com. cloud-dns-hostmaster.google.com. 1 21600 3600 259200 300"]
}

resource "google_dns_record_set" "ns" {
  name         = google_dns_managed_zone.public.dns_name
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
