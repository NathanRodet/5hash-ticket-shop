# # Create ACM certificate (Public SSL/TLS certificate)
# resource "aws_acm_certificate" "ssl_certificate" {
#   domain_name               = "tailor-${local.NAMING_SUFFIX}.com"
#   subject_alternative_names = ["www.tailor-${local.NAMING_SUFFIX}.com"]
#   validation_method         = "DNS"
# }

# resource "aws_route53_zone" "domain_com" {
#   name = aws_acm_certificate.ssl_certificate.domain_name
# }

# resource "aws_route53_record" "domain_com_record" {
#   for_each = {
#     for dvo in aws_acm_certificate.ssl_certificate.domain_validation_options : dvo.domain_name => {
#       name    = dvo.resource_record_name
#       record  = dvo.resource_record_value
#       type    = dvo.resource_record_type
#       zone_id = aws_route53_zone.domain_com.zone_id
#     }
#   }

#   allow_overwrite = true
#   name            = each.value.name
#   records         = [each.value.record]
#   ttl             = 60
#   type            = each.value.type
#   zone_id         = each.value.zone_id
# }

# resource "aws_acm_certificate_validation" "domain_com_record_validation" {
#   certificate_arn         = aws_acm_certificate.ssl_certificate.arn
#   validation_record_fqdns = [for record in aws_route53_record.domain_com_record : record.fqdn]
# }