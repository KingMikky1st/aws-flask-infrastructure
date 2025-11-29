#!/usr/bin/env python3
"""
AWS Infrastructure Validation Script
Validates that all components are running correctly
Author: Michael Mowobi
"""

import boto3
import sys
import time
from datetime import datetime

class InfrastructureValidator:
    def __init__(self):
        self.ec2 = boto3.client('ec2', region_name='us-east-1')
        self.rds = boto3.client('rds', region_name='us-east-1')
        self.s3 = boto3.client('s3')
        self.elbv2 = boto3.client('elbv2', region_name='us-east-1')
        self.results = []
        
    def print_header(self):
        print("=" * 70)
        print("AWS INFRASTRUCTURE VALIDATION")
        print(f"Timestamp: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print("=" * 70)
        print()
    
    def check_vpc(self):
        """Validate VPC exists and is configured correctly"""
        print("[1/6] Checking VPC Configuration...")
        try:
            vpcs = self.ec2.describe_vpcs(
                Filters=[{'Name': 'tag:Name', 'Values': ['flask-app-vpc']}]
            )
            
            if vpcs['Vpcs']:
                vpc = vpcs['Vpcs'][0]
                vpc_id = vpc['VpcId']
                cidr = vpc['CidrBlock']
                
                print(f"  ✓ VPC Found: {vpc_id}")
                print(f"  ✓ CIDR Block: {cidr}")
                
                # Check subnets
                subnets = self.ec2.describe_subnets(
                    Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}]
                )
                public_subnets = [s for s in subnets['Subnets'] if 'public' in s.get('Tags', [{}])[0].get('Value', '').lower()]
                private_subnets = [s for s in subnets['Subnets'] if 'private' in s.get('Tags', [{}])[0].get('Value', '').lower()]
                
                print(f"  ✓ Public Subnets: {len(public_subnets)}")
                print(f"  ✓ Private Subnets: {len(private_subnets)}")
                
                self.results.append(('VPC', 'PASS'))
                return True
            else:
                print("  ✗ VPC not found")
                self.results.append(('VPC', 'FAIL'))
                return False
                
        except Exception as e:
            print(f"  ✗ Error: {str(e)}")
            self.results.append(('VPC', 'ERROR'))
            return False
    
    def check_ec2(self):
        """Validate EC2 instance is running"""
        print("\n[2/6] Checking EC2 Instance...")
        try:
            instances = self.ec2.describe_instances(
                Filters=[
                    {'Name': 'tag:Name', 'Values': ['flask-app-web-server']},
                    {'Name': 'instance-state-name', 'Values': ['running']}
                ]
            )
            
            if instances['Reservations']:
                instance = instances['Reservations'][0]['Instances'][0]
                instance_id = instance['InstanceId']
                instance_type = instance['InstanceType']
                public_ip = instance.get('PublicIpAddress', 'N/A')
                
                print(f"  ✓ Instance Running: {instance_id}")
                print(f"  ✓ Instance Type: {instance_type}")
                print(f"  ✓ Public IP: {public_ip}")
                
                self.results.append(('EC2', 'PASS'))
                return True
            else:
                print("  ✗ No running EC2 instance found")
                self.results.append(('EC2', 'FAIL'))
                return False
                
        except Exception as e:
            print(f"  ✗ Error: {str(e)}")
            self.results.append(('EC2', 'ERROR'))
            return False
    
    def check_rds(self):
        """Validate RDS database is available"""
        print("\n[3/6] Checking RDS Database...")
        try:
            databases = self.rds.describe_db_instances()
            
            flask_dbs = [db for db in databases['DBInstances'] 
                        if 'flask-app' in db['DBInstanceIdentifier']]
            
            if flask_dbs:
                db = flask_dbs[0]
                db_id = db['DBInstanceIdentifier']
                db_status = db['DBInstanceStatus']
                db_engine = db['Engine']
                db_size = db['AllocatedStorage']
                
                print(f"  ✓ Database Found: {db_id}")
                print(f"  ✓ Status: {db_status}")
                print(f"  ✓ Engine: {db_engine}")
                print(f"  ✓ Storage: {db_size} GB")
                
                if db_status == 'available':
                    self.results.append(('RDS', 'PASS'))
                    return True
                else:
                    print(f"  ⚠ Database not available yet (status: {db_status})")
                    self.results.append(('RDS', 'WARN'))
                    return False
            else:
                print("  ✗ No RDS database found")
                self.results.append(('RDS', 'FAIL'))
                return False
                
        except Exception as e:
            print(f"  ✗ Error: {str(e)}")
            self.results.append(('RDS', 'ERROR'))
            return False
    
    def check_s3(self):
        """Validate S3 bucket exists"""
        print("\n[4/6] Checking S3 Bucket...")
        try:
            buckets = self.s3.list_buckets()
            
            flask_buckets = [b for b in buckets['Buckets'] 
                           if 'flask-app' in b['Name']]
            
            if flask_buckets:
                bucket = flask_buckets[0]
                bucket_name = bucket['Name']
                
                print(f"  ✓ Bucket Found: {bucket_name}")
                
                # Check public access block
                try:
                    public_block = self.s3.get_public_access_block(Bucket=bucket_name)
                    if public_block['PublicAccessBlockConfiguration']['BlockPublicAcls']:
                        print(f"  ✓ Public access blocked (secure)")
                except:
                    print(f"  ⚠ Could not verify public access settings")
                
                self.results.append(('S3', 'PASS'))
                return True
            else:
                print("  ✗ No S3 bucket found")
                self.results.append(('S3', 'FAIL'))
                return False
                
        except Exception as e:
            print(f"  ✗ Error: {str(e)}")
            self.results.append(('S3', 'ERROR'))
            return False
    
    def check_load_balancer(self):
        """Validate Application Load Balancer"""
        print("\n[5/6] Checking Load Balancer...")
        try:
            lbs = self.elbv2.describe_load_balancers()
            
            flask_lbs = [lb for lb in lbs['LoadBalancers'] 
                        if 'flask-app' in lb['LoadBalancerName']]
            
            if flask_lbs:
                lb = flask_lbs[0]
                lb_name = lb['LoadBalancerName']
                lb_dns = lb['DNSName']
                lb_state = lb['State']['Code']
                
                print(f"  ✓ Load Balancer: {lb_name}")
                print(f"  ✓ DNS: {lb_dns}")
                print(f"  ✓ State: {lb_state}")
                
                # Check target health
                target_groups = self.elbv2.describe_target_groups(
                    LoadBalancerArn=lb['LoadBalancerArn']
                )
                
                if target_groups['TargetGroups']:
                    tg_arn = target_groups['TargetGroups'][0]['TargetGroupArn']
                    health = self.elbv2.describe_target_health(
                        TargetGroupArn=tg_arn
                    )
                    
                    healthy_targets = [t for t in health['TargetHealthDescriptions'] 
                                     if t['TargetHealth']['State'] == 'healthy']
                    
                    print(f"  ✓ Healthy Targets: {len(healthy_targets)}/{len(health['TargetHealthDescriptions'])}")
                
                if lb_state == 'active':
                    self.results.append(('ALB', 'PASS'))
                    return True
                else:
                    self.results.append(('ALB', 'WARN'))
                    return False
            else:
                print("  ✗ No load balancer found")
                self.results.append(('ALB', 'FAIL'))
                return False
                
        except Exception as e:
            print(f"  ✗ Error: {str(e)}")
            self.results.append(('ALB', 'ERROR'))
            return False
    
    def check_security_groups(self):
        """Validate security groups"""
        print("\n[6/6] Checking Security Groups...")
        try:
            sgs = self.ec2.describe_security_groups(
                Filters=[{'Name': 'group-name', 'Values': ['flask-app-*']}]
            )
            
            if sgs['SecurityGroups']:
                print(f"  ✓ Security Groups Found: {len(sgs['SecurityGroups'])}")
                
                for sg in sgs['SecurityGroups']:
                    print(f"    - {sg['GroupName']}: {len(sg['IpPermissions'])} ingress rules")
                
                self.results.append(('Security Groups', 'PASS'))
                return True
            else:
                print("  ✗ No security groups found")
                self.results.append(('Security Groups', 'FAIL'))
                return False
                
        except Exception as e:
            print(f"  ✗ Error: {str(e)}")
            self.results.append(('Security Groups', 'ERROR'))
            return False
    
    def print_summary(self):
        """Print validation summary"""
        print("\n" + "=" * 70)
        print("VALIDATION SUMMARY")
        print("=" * 70)
        
        passed = len([r for r in self.results if r[1] == 'PASS'])
        failed = len([r for r in self.results if r[1] == 'FAIL'])
        errors = len([r for r in self.results if r[1] == 'ERROR'])
        warnings = len([r for r in self.results if r[1] == 'WARN'])
        total = len(self.results)
        
        print(f"\nTotal Checks: {total}")
        print(f"Passed: {passed} ✓")
        print(f"Failed: {failed} ✗")
        print(f"Warnings: {warnings} ⚠")
        print(f"Errors: {errors}")
        
        success_rate = (passed / total) * 100 if total > 0 else 0
        print(f"\nSuccess Rate: {success_rate:.1f}%")
        
        if passed == total:
            print("\n✓ All infrastructure components validated successfully!")
            return 0
        else:
            print("\n⚠ Some components need attention.")
            return 1
    
    def run_all_checks(self):
        """Run all validation checks"""
        self.print_header()
        
        self.check_vpc()
        self.check_ec2()
        self.check_rds()
        self.check_s3()
        self.check_load_balancer()
        self.check_security_groups()
        
        return self.print_summary()

if __name__ == "__main__":
    try:
        validator = InfrastructureValidator()
        exit_code = validator.run_all_checks()
        sys.exit(exit_code)
    except Exception as e:
        print(f"\n✗ Fatal error: {str(e)}")
        sys.exit(1)