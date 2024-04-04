#!/bin/bash

# Fetch all enabled regions in the management account
regions=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text --region us-east-1)

# Convert the regions into a JSON array
json_array="["
for region in $regions; do
    json_array+="\"$region\","
done
json_array="${json_array%,}"  # Remove the trailing comma
json_array+="]"

# Fetch the account ID of the management account
root_arn=$(aws organizations list-roots --query "Roots[].Arn" --output text)
account_id=$(echo "$root_arn" | cut -d':' -f5)

# Register a delegated admin for cloudformation
echo -n "Input the 12 digit delegated admin account ID: "
read memberAccountId

echo -n "Input the master stacksetname: "
read stacksetname

# Delete stack instances in the all regions in the management account
aws cloudformation delete-stack-instances \
  --stack-set-name $stacksetname \
  --accounts "$account_id" \
  --regions "$json_array" \
  --operation-preferences FailureToleranceCount=7,MaxConcurrentCount=7,RegionConcurrencyType=PARALLEL \
  --no-retain-stacks

sleep 120

# Delete a stackset in the management account
aws cloudformation delete-stack-set \
  --stack-set-name $stacksetname 

aws cloudformation delete-stack \
  --stack-name targetrolestack

aws cloudformation delete-stack \
  --stack-name adminrolestack

aws organizations deregister-delegated-administrator \
  --service-principal=member.org.stacksets.cloudformation.amazonaws.com \
  --account-id="$memberAccountId"

# Deregister a delegated admin for aws config(Edit memberaccountId)
aws organizations deregister-delegated-administrator --service-principal=config-multiaccountsetup.amazonaws.com --account-id $memberAccountId

aws organizations deregister-delegated-administrator --service-principal=config.amazonaws.com --account-id $memberAccountId













