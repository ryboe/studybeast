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
