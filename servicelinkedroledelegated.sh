#!/bin/bash

# Create a stackset
aws cloudformation create-stack-set --stack-set-name myconfigservicelinkedroleold --template-url https://cfntemplatesconfig.s3.amazonaws.com/configservicelinkedrole.yml --permission-model SERVICE_MANAGED --auto-deployment Enabled=true,RetainStacksOnAccountRemoval=true --region us-east-1 --call-as DELEGATED_ADMIN

# sleep for 30 seconds
sleep 30

# Get the root org ID
orgrootid=$(aws organizations list-roots --query "Roots[].Id" --output text)

# Enable AWS Config in all regions
aws cloudformation create-stack-instances --stack-set-name myconfigservicelinkedroleold --deployment-targets OrganizationalUnitIds="$orgrootid" --regions '["us-east-1"]' --call-as DELEGATED_ADMIN

echo "Config service role created in all accounts."
