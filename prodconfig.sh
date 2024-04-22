#!/bin/bash

# Exit the script immediately if any command returns a non-zero status
set -e

# Fetch the account ID of the management account
root_arn=$(aws organizations list-roots --query "Roots[].Arn" --output text)
master_account_id=$(echo "$root_arn" | cut -d':' -f5)

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

# JSON array for storing account IDs
ACCOUNT_IDS_JSON="["
FIRST_ACCOUNT=true  # Flag to handle the first account ID in the list

# Enable AWS Config in all regions
echo "Enabling AWS Config for regions: $json_array"

# create admin and execution roles for self-managed stack set

echo -n "Name of admin role stack: "
read adminrolestack

aws cloudformation create-stack \
  --stack-name $adminrolestack \
  --template-url https://s3.amazonaws.com/cloudformation-stackset-sample-templates-us-east-1/AWSCloudFormationStackSetAdministrationRole.yml \
  --capabilities CAPABILITY_NAMED_IAM \
  --on-failure DELETE

# File containing AWS account IDs (one per line)
echo -n "Name of file containing account IDs(add the extension): "
read ACCOUNT_IDS_FILE

# ACCOUNT_IDS_FILE="account_ids.txt"
echo -n "Name of target role stack: "
read STACK_NAME

# Loop through each account ID in the file
while IFS= read -r ACCOUNT_ID; do


    echo "Assuming role OrganizationAccountAccessRole in account $ACCOUNT_ID..."


    # Add account ID to the JSON array
    if [ "$FIRST_ACCOUNT" = false ]; then
        ACCOUNT_IDS_JSON+=","
    fi
    ACCOUNT_IDS_JSON+="\"$ACCOUNT_ID\""
    FIRST_ACCOUNT=false

    # Assume the specified IAM role in the account
    TEMP_CREDENTIALS=$(aws sts assume-role --role-arn "arn:aws:iam::$ACCOUNT_ID:role/OrganizationAccountAccessRole" --role-session-name "AssumeRoleSession")

    # Extract temporary credentials from JSON response
    ACCESS_KEY=$(echo "$TEMP_CREDENTIALS" | jq -r '.Credentials.AccessKeyId')
    SECRET_KEY=$(echo "$TEMP_CREDENTIALS" | jq -r '.Credentials.SecretAccessKey')
    SESSION_TOKEN=$(echo "$TEMP_CREDENTIALS" | jq -r '.Credentials.SessionToken')

    # Set temporary credentials as environment variables for AWS CLI
    export AWS_ACCESS_KEY_ID="$ACCESS_KEY"
    export AWS_SECRET_ACCESS_KEY="$SECRET_KEY"
    export AWS_SESSION_TOKEN="$SESSION_TOKEN"

    # Deploy CloudFormation stack in the assumed role
    echo "Deploying CloudFormation stack $STACK_NAME in account $ACCOUNT_ID..."
    
    aws cloudformation create-stack \
        --stack-name $STACK_NAME \
        --template-url https://s3.amazonaws.com/cloudformation-stackset-sample-templates-us-east-1/AWSCloudFormationStackSetExecutionRole.yml \
        --parameters ParameterKey=AdministratorAccountId,ParameterValue=$master_account_id \
        --capabilities CAPABILITY_NAMED_IAM \
        --on-failure DELETE

    # Unset temporary credentials environment variables
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_SESSION_TOKEN

    echo "Deployment completed for account $ACCOUNT_ID."
    echo "----------------------------------------"
done < "$ACCOUNT_IDS_FILE"

# Complete the JSON array
ACCOUNT_IDS_JSON+="]"

# Output the final JSON array of account IDs
echo "JSON array of account IDs:"
echo "$ACCOUNT_IDS_JSON"

# Create a stackset for the target accounts
echo -n "Name of master profile: "
read profile

export AWS_PROFILE=$profile

# Check if AWS Config is enabled in the management account
CONFIG_ENABLED=$(aws configservice describe-configuration-recorder-status --query "ConfigurationRecordersStatus[0].recording" --output text)

if [ "$CONFIG_ENABLED" != "True" ]; then
    # AWS Config is not enabled, deploy AWS Config using CloudFormation
    echo "AWS Config is not enabled in master account. Deploying AWS Config using CloudFormation..."

    aws cloudformation create-stack \
        --stack-name $STACK_NAME \
        --template-url https://s3.amazonaws.com/cloudformation-stackset-sample-templates-us-east-1/AWSCloudFormationStackSetExecutionRole.yml \
        --parameters ParameterKey=AdministratorAccountId,ParameterValue=$master_account_id \
        --capabilities CAPABILITY_NAMED_IAM \
        --on-failure DELETE

    echo -n "Name of master stackset: "
    read masterstackset

    aws cloudformation create-stack-set \
        --stack-set-name $masterstackset \
        --template-url https://s3.amazonaws.com/cloudformation-stackset-sample-templates-us-east-1/EnableAWSConfig.yml \
        --capabilities CAPABILITY_IAM

    # Create stack instances in the all regions in the management account
    aws cloudformation create-stack-instances \
        --stack-set-name $masterstackset \
        --accounts "$master_account_id" \
        --regions $json_array \
        --operation-preferences FailureToleranceCount=7,MaxConcurrentCount=7,RegionConcurrencyType=PARALLEL

else
    # AWS Config is enabled, execute other commands or skip
    echo "AWS Config is already enabled in the management account."
    echo "Enabling in target accounts............."
fi

echo -n "Name of target stackset: "
read targetstackset

aws cloudformation create-stack-set \
  --stack-set-name $targetstackset \
  --template-url https://s3.amazonaws.com/cloudformation-stackset-sample-templates-us-east-1/EnableAWSConfig.yml \
  --capabilities CAPABILITY_IAM

# Create stack instances in the all regions in the target accounts
aws cloudformation create-stack-instances \
  --stack-set-name $targetstackset \
  --accounts "$ACCOUNT_IDS_JSON" \
  --regions $json_array \
  --operation-preferences FailureToleranceCount=7,MaxConcurrentCount=7,RegionConcurrencyType=PARALLEL