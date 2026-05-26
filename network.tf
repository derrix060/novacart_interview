
resource "aws_vpc" "example" {
  cidr_block = "192.168.0.0/16"
}

# Provision two public subnets and two private subnets across multiple Availability Zones
# - Configure Internet Gateway and routing rules
# - Ensure private subnets do not have direct internet exposure


module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.6.1"

  name = "nova-cart-vpc"
  cidr = "192.168.0.0/16"

  azs             = ["us-east-2a", "us-east-2b"]
  private_subnets = ["192.168.1.0/24", "192.168.2.0/24"]
  public_subnets  = ["192.168.101.0/24", "192.168.102.0/24"]

  # One NAT Gateway per Availability Zone for high availability
  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true

  enable_vpn_gateway = true

  default_network_acl_ingress = [
    {
      "action" : "deny",
      "cidr_block" : "0.0.0.0/0",
      "from_port" : 0,
      "protocol" : "-1",
      "rule_no" : 100,
      "to_port" : 0
    },
    {
      "action" : "deny",
      "from_port" : 0,
      "ipv6_cidr_block" : "::/0",
      "protocol" : "-1",
      "rule_no" : 101,
      "to_port" : 0
    }
  ]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
