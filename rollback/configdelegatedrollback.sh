#!/bin/bash

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

echo -n "Input the target stacksetname: "
read stacksetname

aws cloudformation delete-stack-instances --stack-set-name $stacksetname --deployment-targets OrganizationalUnitIds="$orgrootid" --regions "$json_array" --operation-preferences FailureToleranceCount=7,MaxConcurrentCount=7,RegionConcurrencyType=PARALLEL --no-retain-stacks \
 --call-as DELEGATED_ADMIN


### Delete the stackset when all the stacks instances have been deleted
# aws cloudformation delete-stack-set --stack-set-name $stacksetname --call-as DELEGATED_ADMIN
