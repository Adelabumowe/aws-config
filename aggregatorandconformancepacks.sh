#!/bin/bash

# Exit the script immediately if any command returns a non-zero status
set -e

# Create an IAM role for your AWS Config aggregator
aws iam create-role --role-name OrgConfigRole --assume-role-policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"\",\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"config.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}" --description "Role for organizational AWS Config aggregator"

# Get role arn
rolearn=$(aws iam get-role --role-name OrgConfigRole --query "Role.Arn" --output text)

# Create a policy for your AWS Config Aggregator
aws iam create-policy --policy-name OrgConfigPolicy --policy-document '{"Version": "2012-10-17","Statement": [{"Effect":"Allow","Action": ["organizations:ListAccounts","organizations:DescribeOrganization","organizations:ListAWSServiceAccessForOrganization","organizations:ListDelegatedAdministrators"],"Resource": "*"}]}'

# Get policy arn
policyarn=$(aws iam list-policies --query 'Policies[?PolicyName==`OrgConfigPolicy`].Arn' --output text)

# Attach a policy to a role
aws iam attach-role-policy --role-name OrgConfigRole --policy-arn "$policyarn"

# Create delivery bucket (Bucket must start with awsconfigconforms)
echo -n "Input a unique name of the delivery bucket(It must start with awsconfigconforms): "
read bucketname

aws s3api create-bucket \
    --bucket $bucketname \
    --region us-east-1

# Fetch org ID
root_arn=$(aws organizations list-roots --query "Roots[].Arn" --output text)
org_id=$(echo "$root_arn" | cut -d'/' -f2)

# Add bucket policy (Edit bucket name here as well)
aws s3api put-bucket-policy \
    --bucket $bucketname \
    --policy "{\"Version\": \"2012-10-17\", \
               \"Statement\": [ \
                   { \
                       \"Sid\": \"AllowGetPutObject\", \
                       \"Effect\": \"Allow\", \
                       \"Principal\": \"*\", \
                       \"Action\": [\"s3:GetObject\", \"s3:PutObject\"], \
                       \"Resource\": \"arn:aws:s3:::$bucketname/*\", \
                       \"Condition\": { \
                           \"StringEquals\": { \
                               \"aws:PrincipalOrgID\": \"$org_id\" \
                           }, \
                           \"ArnLike\": { \
                               \"aws:PrincipalArn\": \"arn:aws:iam::*:role/aws-service-role/config-conforms.amazonaws.com/AWSServiceRoleForConfigConforms\" \
                           } \
                       } \
                   }, \
                   { \
                       \"Sid\": \"AllowGetBucketAcl\", \
                       \"Effect\": \"Allow\", \
                       \"Principal\": \"*\", \
                       \"Action\": \"s3:GetBucketAcl\", \
                       \"Resource\": \"arn:aws:s3:::$bucketname\", \
                       \"Condition\": { \
                           \"StringEquals\": { \
                               \"aws:PrincipalOrgID\": \"$org_id\" \
                           }, \
                           \"ArnLike\": { \
                               \"aws:PrincipalArn\": \"arn:aws:iam::*:role/aws-service-role/config-conforms.amazonaws.com/AWSServiceRoleForConfigConforms\" \
                           } \
                       } \
                   } \
               ] \
           }"


# Location of conformance pack
echo -n "Input the s3 uri for the conformance pack: "
read conformancepack

# Deploy the conformance pack
aws configservice put-organization-conformance-pack --organization-conformance-pack-name="OrgS3ConformancePack" --template-s3-uri="$conformancepack" --delivery-s3-bucket=$bucketname

sleep 300

# Create Aggregator
aws configservice put-configuration-aggregator --configuration-aggregator-name MyAggregator --organization-aggregation-source "{\"RoleArn\": \"$rolearn\",\"AllAwsRegions\": true}"