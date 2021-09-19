locals {
  # Common tags to be assigned to all resources
  common_tags = {
    Service     = "Elite Technology Services"
    Owner       = "EliteInfra"
    Department  = "IT"
    Company     = "EliteSolutions LLC"
    ManagedWith = "Terraform"
    Casecode    = "es20"
  }

  network = {
    Service     = "Elite Technology Services"
    Owner       = "EliteInfra"
    Department  = "IT"
    Company     = "EliteSolutions LLC"
    ManagedWith = "Terraform"
    Casecode    = "es20"
  }

  application = {
    app_name = "publicapp"
    location = "useast2"
    alias    = "Dev"
    ec2      = "public"
  }
}