#!/bin/bash

# Exit the script immediately if any command returns a non-zero status
set -e

# Location of conformance pack
echo -n "Input the general stackset name: "
read stackset

# Create a stackset
aws cloudformation create-stack-set --stack-set-name $stackset --template-url https://cfntemplatesconfig.s3.amazonaws.com/EnableAWSConfigForOrganizations.yml --permission-model SERVICE_MANAGED --auto-deployment Enabled=true,RetainStacksOnAccountRemoval=true --call-as DELEGATED_ADMIN

# Get a list of all enabled regions in the organization
regions=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text --region us-east-1)

# Convert the regions into a JSON array
json_array="["
for region in $regions; do
    json_array+="\"$region\","
done
json_array="${json_array%,}"  # Remove the trailing comma
json_array+="]"

# Get the root org ID
orgrootid=$(aws organizations list-roots --query "Roots[].Id" --output text)

# Enable AWS Config in all regions
echo "Enabling AWS Config for regions: $json_array"

aws cloudformation create-stack-instances --stack-set-name $stackset --deployment-targets OrganizationalUnitIds="$orgrootid" --regions "$json_array" --operation-preferences FailureToleranceCount=7,MaxConcurrentCount=7,RegionConcurrencyType=PARALLEL --call-as DELEGATED_ADMIN

echo "AWS Config enabled across all regions in the organization."