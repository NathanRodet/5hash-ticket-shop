# Autoscaling for the ECS service based on CPU utilization
resource "aws_appautoscaling_target" "prestashop_scaling_target" {
  max_capacity       = 5 # Maximum number of tasks
  min_capacity       = 2 # Minimum number of tasks
  resource_id        = "service/${aws_ecs_cluster.ecs_cluster.id}/${aws_ecs_service.prestashop_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "prestashop_scaling_policy" {
  name               = "ecs-autoscale-policy-${local.NAMING_SUFFIX}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.prestashop_scaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.prestashop_scaling_target.scalable_dimension
  service_namespace  = "ecs"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
    target_value       = 50.0
  }
}

resource "aws_cloudwatch_metric_alarm" "prestashop_scaling_alarm" {
  alarm_name          = "ecs-autoscale-alarm-${local.NAMING_SUFFIX}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 70
  alarm_actions       = [aws_appautoscaling_policy.prestashop_scaling_policy.arn]
  dimensions = {
    ClusterName = aws_ecs_cluster.ecs_cluster.name
    ServiceName = aws_ecs_service.prestashop_service.name
  }
}
