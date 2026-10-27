resource "aws_security_group" "alb" {
  name        = "${var.name}-alb-sg"
  description = "Public HTTP to the load balancer"
  vpc_id      = var.vpc_id
}

resource "aws_security_group" "app" {
  name        = "${var.name}-app-sg"
  description = "App servers"
  vpc_id      = var.vpc_id
}

resource "aws_security_group" "monitoring" {
  name        = "${var.name}-monitoring-sg"
  description = "Prometheus, Grafana and ELK"
  vpc_id      = var.vpc_id
}

# ALB: HTTP from anywhere
resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

# App: traffic only from the ALB
resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = var.app_port
  to_port                      = var.app_port
  ip_protocol                  = "tcp"
}

# App: Prometheus scrapes app metrics and node_exporter
resource "aws_vpc_security_group_ingress_rule" "app_metrics" {
  for_each                     = toset(["${var.app_port}", "9100"])
  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = aws_security_group.monitoring.id
  from_port                    = tonumber(each.value)
  to_port                      = tonumber(each.value)
  ip_protocol                  = "tcp"
}

# Monitoring: Logstash receives logs from app servers (Filebeat)
resource "aws_vpc_security_group_ingress_rule" "monitoring_logstash" {
  security_group_id            = aws_security_group.monitoring.id
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = 5044
  to_port                      = 5044
  ip_protocol                  = "tcp"
}

# Monitoring: dashboards from your IP only (Prometheus, Grafana, Kibana)
resource "aws_vpc_security_group_ingress_rule" "monitoring_dashboards" {
  for_each          = toset(["9090", "9093", "3000", "5601"])
  security_group_id = aws_security_group.monitoring.id
  cidr_ipv4         = var.ssh_cidr
  from_port         = tonumber(each.value)
  to_port           = tonumber(each.value)
  ip_protocol       = "tcp"
}

# SSH from your IP to app and monitoring servers
resource "aws_vpc_security_group_ingress_rule" "ssh" {
  for_each = {
    app        = aws_security_group.app.id
    monitoring = aws_security_group.monitoring.id
  }
  security_group_id = each.value
  cidr_ipv4         = var.ssh_cidr
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

# All outbound traffic allowed
resource "aws_vpc_security_group_egress_rule" "all" {
  for_each = {
    alb        = aws_security_group.alb.id
    app        = aws_security_group.app.id
    monitoring = aws_security_group.monitoring.id
  }
  security_group_id = each.value
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
