#!/bin/bash

# Fetch org ID
root_arn=$(aws organizations list-roots --query "Roots[].Arn" --output text)
org_id=$(echo "$root_arn" | cut -d'/' -f2)

# Delete aggregator
echo -n "Input the name of the aggregator to deleteLeave blank if you didn't create any: "
read aggregator

echo -n "Input the region the aggregator and conformance pack was created in: "
read region

# Location of conformance pack
echo -n "Input the name for the conformance pack to delete(Leave blank if you didn't create any): "
read conformancepack

packname=$(aws configservice describe-organization-conformance-packs --query "OrganizationConformancePacks[?contains(OrganizationConformancePackName, '$conformancepack')].OrganizationConformancePackName" --region $region --output text)

aws configservice delete-configuration-aggregator --configuration-aggregator-name $aggregator --region $region

# Deploy the conformance pack
aws configservice delete-organization-conformance-pack --organization-conformance-pack-name="$packname" --region $region

# Delete delivery bucket (Bucket must start with awsconfigconforms)
echo -n "Input the bucketname: "
read bucketname

aws s3api delete-bucket \
    --bucket $bucketname


echo -n "Input the aggregator policy arn: "
read aggregatorpolicy

# Get policy arn
policyarn=$(aws iam list-policies --query 'Policies[?PolicyName=='$aggregatorpolicy'].Arn' --output text)

# Create a policy for your AWS Config Aggregator
aws iam delete-policy --policy-arn $policyarn

# Delete an IAM role for your AWS Config aggregator

echo -n "Input the aggregator role: "
read aggregatorrole

aws iam delete-role --role-name $aggregatorrole












