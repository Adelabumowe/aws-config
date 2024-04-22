#!/bin/bash

# Fetch org ID
root_arn=$(aws organizations list-roots --query "Roots[].Arn" --output text)
org_id=$(echo "$root_arn" | cut -d'/' -f2)

# Delete aggregator
echo -n "Input the name of the aggregator to delete(Leave blank if you didn't create any): "
read aggregator

echo -n "Input the region the aggregator was created in: "
read region

aws configservice delete-configuration-aggregator --configuration-aggregator-name $aggregator --region $region

# Conformance packs created
echo -n "Input the name for the CIS conformance pack to delete(Leave blank if you didn't create any): "
read cisconformancepackcheck

echo -n "Input the name for the PCI-DSS conformance pack to delete(Leave blank if you didn't create any): "
read pciconformancepackcheck

cisconformancepack=$(aws configservice describe-organization-conformance-packs --query "OrganizationConformancePacks[?contains(OrganizationConformancePackName, '$cisconformancepackcheck')].OrganizationConformancePackName" --region $region --output text)

pciconformancepack=$(aws configservice describe-organization-conformance-packs --query "OrganizationConformancePacks[?contains(OrganizationConformancePackName, '$pciconformancepackcheck')].OrganizationConformancePackName" --region $region --output text)

# Get list of AWS regions
regions=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text --region us-east-1)

# Convert the regions into a JSON array
json_array="["
for region in $regions; do
    json_array+="\"$region\","
done
json_array="${json_array%,}"  # Remove the trailing comma
json_array+="]"

# Loop through each region and run the AWS Config Service commands
for region in $regions; do
    echo "Deleting conformance packs in region: $region"

    # Delete the Organization Conformance Pack for CIS
    aws configservice delete-organization-conformance-pack --organization-conformance-pack-name="$cisconformancepack" --region $region

    # Delete the Organization Conformance Pack for PCI DSS
    aws configservice delete-organization-conformance-pack --organization-conformance-pack-name="$pciconformancepack" --region $region

    echo "Completed processing region: $region"
done

echo -n "Input the aggregator policy arn: "
read aggregatorpolicy

# Get policy arn
policyarn=$(aws iam list-policies --query 'Policies[?PolicyName=='$aggregatorpolicy'].Arn' --output text)

# Create a policy for your AWS Config Aggregator
aws iam delete-policy --policy-arn $policyarn

# Delete delivery bucket (Bucket must start with awsconfigconforms)
echo -n "Input the bucketname: "
read bucketname

aws s3api delete-bucket \
    --bucket $bucketname

# Delete an IAM role for your AWS Config aggregator

echo -n "Input the aggregator role: "
read aggregatorrole

aws iam delete-role --role-name $aggregatorrole












