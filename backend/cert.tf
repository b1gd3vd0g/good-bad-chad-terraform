# Create an SSL certificate using ACM. This certificate is going to be used by
# our CloudFront CDN.
resource "aws_acm_certificate" "cert" {
  domain_name       = var.api_domain_name
  validation_method = "DNS"

  subject_alternative_names = ["www.${var.api_domain_name}"]
}

# Validate the ACM certificate through Route 53.
# This will create CNAME records linking to the certificate.
resource "aws_route53_record" "cert_validation" {
  # The for_each here means that instead of creating ONE resource called
  # `aws_route53_record.cert_validation`, it is going to create MULTIPLE
  # `aws_route53_record` resources called `aws_route53_record.cert_validation[key].
  for_each = {
    # The `aws_acm_certificate` resource above will return multiple
    # `domain_validation_options`. These are objects with keys like:
    # { domain_name, resource_record_name, resource_record_type, resource_record_value }.
    # We want to convert these into a MAP instead of a list of objects,
    # Where the `domain_name` is the key. The map will be similar to:
    # domain_name => { name, type, record }.
    for dvo in aws_acm_certificate.cert.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }
  # So, at the end of this loop, we have created multiple resources called:
  # `aws_route53_record.cert_validation[<domain_name>]`. Inside each of those
  # blocks, the following fields will be added, with the `each` variable
  # referring to the current mapping.

  zone_id = var.route_53_hosted_zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}

# Make Terraform wait until the certificate is "Issued"
resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}
