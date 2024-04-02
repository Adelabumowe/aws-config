#!/bin/bash

# Fetch the account ID of the management account
root_arn=$(aws organizations list-roots --query "Roots[].Arn" --output text)
account_id=$(echo "$root_arn" | cut -d':' -f5)

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

sleep 120

# Create a stackset in the management account
aws cloudformation create-stack-set \
  --stack-set-name my-final-awsconfig-stackset \
  --template-url https://s3.amazonaws.com/cloudformation-stackset-sample-templates-us-east-1/EnableAWSConfig.yml \
  --capabilities CAPABILITY_IAM


# Fetch all enabled regions in the management account
regions=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text --region us-east-1)

# Convert the regions into a JSON array
json_array="["
for region in $regions; do
    json_array+="\"$region\","
done
json_array="${json_array%,}"  # Remove the trailing comma
json_array+="]"


# Create stack instances in the all regions in the management account
aws cloudformation create-stack-instances \
  --stack-set-name my-final-awsconfig-stackset \
  --accounts "$account_id" \
  --regions "$json_array" \
  --operation-preferences FailureToleranceCount=0,MaxConcurrentCount=1