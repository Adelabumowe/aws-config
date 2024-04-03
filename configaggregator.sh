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

# Create Aggregator
aws configservice put-configuration-aggregator --configuration-aggregator-name MyAggregator --organization-aggregation-source "{\"RoleArn\": \"$rolearn\",\"AllAwsRegions\": true}"


