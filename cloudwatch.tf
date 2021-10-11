# ########-------- Server CloudWatch dashboard -----#####
# resource "aws_cloudwatch_dashboard" "main" {
#   dashboard_name = "registrationwebapp-dashboard"

#   dashboard_body = <<EOF
# {
#   "widgets": [
#     {
#       "type": "metric",
#       "x": 0,
#       "y": 0,
#       "width": 12,
#       "height": 6,
#       "properties": {
#         "metrics": [
#           [
#             "AWS/EC2",
#             "CPUUtilization",
#             "InstanceId",
#             "i-0ff4ac3523184588b"
#           ]
#         ],
#         "period": 300,
#         "stat": "Average",
#         "region": "ap-southeast-1",
#         "title": "EC2 Instance CPU"
#       }
#     },
#     {
#       "type": "text",
#       "x": 0,
#       "y": 7,
#       "width": 3,
#       "height": 3,
#       "properties": {
#         "markdown": "Registration web app"
#       }
#     }
#   ]
# }
# EOF
# }

# ####----- Log group destination -------####
# resource "aws_cloudwatch_log_group" "registrationwebapp" {
#   name = "registrationwebapp"

#   tags = {
#     Environment = "development"
#     Application = "registrationwebapp"
#   }
# }
# ######---- Alarm ------#####
# resource "aws_cloudwatch_metric_alarm" "registrationwebapp_alarm" {
#   alarm_name                = "registrationwebapp_alarm"
#   comparison_operator       = "GreaterThanOrEqualToThreshold"
#   evaluation_periods        = "2"
#   metric_name               = "CPUUtilization"
#   namespace                 = "AWS/EC2"
#   period                    = "120"
#   statistic                 = "Average"
#   threshold                 = "80"
#   alarm_description         = "This metric monitors ec2 cpu utilization"
#   insufficient_data_actions = []
# }