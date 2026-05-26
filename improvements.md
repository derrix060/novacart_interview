- Proper gitignore/commits messages
- Get correct AMI id for the latest image
- Set correct way to install nginx
- Fix healthchecks



# Current

## HA
- Only a single region
- Using ec2 (takes a bit longer to spinup comparing to ECS for example)
- spike in traffic/AZ failure might put the 3 instances down (autoscaling limited to 3 only)

## Failover
- maybe configure the time for healthchecks in a non-linear matter

## DB
- single AZ at one time
- single instance


# Improvements

## HA
- multiple regions/clouds
- ECS/EKS

## Failover
- introduce a jitter for retrying healthchecks?

## DB
- Primary/standby replicas (across AZ? Regions?)
- multiple instances
- Create VPN to access in breaking-glass scenarios

## Monitoring
- metrics
- logs
- alerts
- runbooks

## CI/CD
- run formatting/tests

## Maybe?
- have the nginx talk to the DB (attach it to the private subnet as well)

