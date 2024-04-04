#!/bin/bash

# Exit the script immediately if any command returns a non-zero status
set -e

# Fetch the account ID of the management account
root_arn=$(aws organizations list-roots --query "Roots[].Arn" --output text)
account_id=$(echo "$root_arn" | cut -d':' -f5)

# Get the root org ID
orgrootid=$(aws organizations list-roots --query "Roots[].Id" --output text)

# Get a list of all enabled regions in the organization
regions=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text --region us-east-1)

# Convert the regions into a JSON array
json_array="["
for region in $regions; do
    json_array+="\"$region\","
done
json_array="${json_array%,}"  # Remove the trailing comma
json_array+="]"

# Enable AWS Config in all regions
echo "Enabling AWS Config for regions: $json_array"

# create roles for self-managed stack set

aws cloudformation create-stack \
  --stack-name adminrolestack \
  --template-url https://s3.amazonaws.com/cloudformation-stackset-sample-templates-us-east-1/AWSCloudFormationStackSetAdministrationRole.yml \
  --capabilities CAPABILITY_NAMED_IAM


aws cloudformation create-stack \
  --stack-name targetrolestack \
  --template-url https://s3.amazonaws.com/cloudformation-stackset-sample-templates-us-east-1/AWSCloudFormationStackSetExecutionRole.yml \
  --parameters ParameterKey=AdministratorAccountId,ParameterValue=$account_id \
  --capabilities CAPABILITY_NAMED_IAM

sleep 60

# Create a stackset in the management account
aws cloudformation create-stack-set \
  --stack-set-name my-final-final-awsconfig-stackset \
  --template-url https://s3.amazonaws.com/cloudformation-stackset-sample-templates-us-east-1/EnableAWSConfig.yml \
  --capabilities CAPABILITY_IAM


# Create stack instances in the all regions in the management account
aws cloudformation create-stack-instances \
  --stack-set-name my-final-final-awsconfig-stackset \
  --accounts "$account_id" \
  --regions "$json_array" \
  --operation-preferences FailureToleranceCount=7,MaxConcurrentCount=7,RegionConcurrencyType=PARALLEL

# Create a stackset for target accounts
aws cloudformation create-stack-set --stack-set-name myconfig --template-url https://cfntemplatesconfig.s3.amazonaws.com/EnableAWSConfigForOrganizations.yml --permission-model SERVICE_MANAGED --auto-deployment Enabled=true,RetainStacksOnAccountRemoval=true


aws cloudformation create-stack-instances --stack-set-name myconfig --deployment-targets OrganizationalUnitIds="$orgrootid" --regions "$json_array" --operation-preferences FailureToleranceCount=7,MaxConcurrentCount=7,RegionConcurrencyType=PARALLEL

echo "AWS Config enabled across all regions in the organization."