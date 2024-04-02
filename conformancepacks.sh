#!/bin/bash

# Create delivery bucket (Bucket must start with awsconfigconforms)
aws s3api create-bucket \
    --bucket awsconfigconforms \
    --region us-east-1

# Fetch org ID
root_arn=$(aws organizations list-roots --query "Roots[].Arn" --output text)
org_id=$(echo "$root_arn" | cut -d'/' -f2)

# Add bucket policy (Edit bucket name here as well)
aws s3api put-bucket-policy \
    --bucket awsconfigconforms \
    --policy "{\"Version\": \"2012-10-17\", \
               \"Statement\": [ \
                   { \
                       \"Sid\": \"AllowGetPutObject\", \
                       \"Effect\": \"Allow\", \
                       \"Principal\": \"*\", \
                       \"Action\": [\"s3:GetObject\", \"s3:PutObject\"], \
                       \"Resource\": \"arn:aws:s3:::awsconfigconforms<suffix in bucket name>/*\", \
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
                       \"Resource\": \"arn:aws:s3:::awsconfigconforms<suffix in bucket name>\", \
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


# Deploy the conformance pack
aws configservice put-organization-conformance-pack --organization-conformance-pack-name="OrgS3ConformancePack" --template-s3-uri="file://<PATH TO YOUR TEMPLATE>/<TEMPLATE FILENAME>" --delivery-s3-bucket=<YOUR BUCKET>