# Register a delegated adminfor cloudformation(Edit memberaccountId)
aws organizations register-delegated-administrator \
  --service-principal=member.org.stacksets.cloudformation.amazonaws.com \
  --account-id="memberAccountId"

# Enable delegated admin to deploy and manage aws config rules

aws organizations enable-aws-service-access --service-principal=config-multiaccountsetup.amazonaws.com

aws organizations enable-aws-service-access --service-principal=config.amazonaws.com

# Register a delegated admin for aws config(Edit memberaccountId)
aws organizations register-delegated-administrator --service-principal=config-multiaccountsetup.amazonaws.com --account-id MemberAccountID

aws organizations register-delegated-administrator --service-principal=config.amazonaws.com --account-id MemberAccountID