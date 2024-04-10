# Setting up Config in AWS Organization

<ins>___Summary___</ins>

This document outlines the importance of AWS Config, the step by step guide to enabling AWS Config in Loyalty's AWS Organization. The primary aim of enabling aws config is to gain visibility and control over the configuration of resources within Loyalty's AWS environment

<ins>___Goal___</ins>

The primary goal is to ensure that all resources are continuously monitored and tracked and if in an event a resource becomes uncompliant, automated remediation strategies are kicked into operation.

<ins>Solution</ins>

The strategy involves the implentation of a script that automatically creates cloudformation stacks which in turn enables AWS Config across Loyalty AWS Organization. This proposed method ensures that when a new aws account is added to the organization, AWS config is automatically enabled in all regions in that account.

<ins>Plan of execution</ins>

Note: These commands must be run by an administrator i.e 

- Using the credentials from the management account or
- By registering a delegated administrator(can only be created from the organization's management account) - Recommended


_Using a delegated admin account_

<ins>Step 1</ins>: Create a delegated admin and enable aws config in the master account

_Note_ Use the master account profile to run this script as it creates a delegated admin(for deploying cloudformation stacks and aws config rules) and deploys a self-managed stackset in the master account which enables aws config in all enabled regions in the master account. See below images

```sh
./configmasteraccount.sh
```

Cli output
![Script-result](https://configtestpictures.s3.us-west-1.amazonaws.com/configmasteraccount.png)

Console output
![Console-result](https://configtestpictures.s3.us-west-1.amazonaws.com/stacksetinmasteraccount.png)

<ins>Step 2</ins>: Using the delegated admin creds, enable aws config across all accounts and all enabled regions in the organization. 

This script creates a stackset in the master account using the delegated admin credentials. The stackset in turn creates cloudformation stacks that enables aws config in every enabled region in every account asides the master account(This was created in the first step). See below images

```sh
./configdelegated.sh
```

Cli output
![Script-result](https://configtestpictures.s3.us-west-1.amazonaws.com/orgwidestacksetscript.png)

Console output - stackset
![Console-result](https://configtestpictures.s3.us-west-1.amazonaws.com/stack-set-for-org-wide-in-master-account.png)

Console output - sample cloudformation stack in a target region in a target account
![Console-result](https://configtestpictures.s3.us-west-1.amazonaws.com/stacks-in-each-region-in-each-account.png)

Ensure that all accounts and regions have aws config enabled before proceeding to the next step

<ins>Step 3</ins>: Deploy AWS Config Conformance Packs across Loyalty's AWS Organization to help manage compliance of all AWS resources at scale using common frameworks and set up an aggregator which collects AWS Config configuration and Compliance data from multiple regions in multiple accounts.

```sh
./aggregatorandconformancepacks.sh
```

Cli output
![Script-result](https://configtestpictures.s3.us-west-1.amazonaws.com/aggregator-conformance-script.png)

Console output - conformance packs
![Console-result](https://configtestpictures.s3.us-west-1.amazonaws.com/conformancepacks.png)

Console output - aggregator
![Console-result](https://configtestpictures.s3.us-west-1.amazonaws.com/EndGoal.png)


_Using the management account_

<ins>Step 1</ins>: Create a cloudformation stackset which deploys a stack that enables aws config across all accounts in the organization

Using the management profile, run 
```sh
./enableconfigwithmaster.sh
```

Ensure that all accounts and regions have aws config enabled before proceeding to the next step

<ins>Step 2</ins>: Deploy AWS Config Conformance Packs across Loyalty's AWS Organization to help manage compliance of all AWS resources at scale using common frameworks and set up an aggregator which collects AWS Config configuration and Compliance data from multiple regions in multiple accounts.

Using the management profile/delegated admin, run 
```sh
./aggregatorandconformancepacks.sh
```

[List of Conformance Packs](https://github.com/awslabs/aws-config-rules/tree/master/aws-config-conformance-packs)


<ins>___Pricing model___</ins>

Loyalty pays per configuration item delivered per AWS account per AWS Region and a configuration item is created whenever a resource undergoes a configuration change for example, when a security group is changed. Configuration items can be delivered periodically or continuously

Periodic Recording(Every 24hrs, only if a change occurs) per configuration item per account per region is `$0.0012`

Continuous Recording(Immediately a change occurs) per configuration item per account per region is `$0.003`

Loyalty is also charged based on the number of AWS Config rule evaluations recorded and a rule evaluation is recorded every time a resource is evaluated.

First `100,000` rule evaluations costs `$0.001` per rule evaluation per region.

Next `400,000` rule evaluations `(100,001-500,000)` costs `$0.0008` per rule evaluation per region.

`500,001` and more rule evaluations costs `$0.0005` per rule evaluation per region

Lastly, Loyalty is also charged for conformance pack evaluation

First `100,000` conformance pack evaluations costs `$0.001` per conformance pack evaluation per region.

Next `400,000` conformance pack evaluations `(100,001-500,000)` costs `$0.0008` per conformance pack evaluation per region.

`500,001` and more conformance pack evaluations costs `$0.0005` per conformance pack evaluation per region

<ins>Billing breakdown for enabling AWS Config in Loyalty's AWS Organization</ins>

To ensure overall security complaince in Loyalty's AWS Organization, we recommend CIS and PCI-DSS conformance packs

Removing duplicate AWS config rule entries to prevent being billed for the same rule in two different conformance packs,

- CIS conformance pack has `60` AWS Config rules
- PCI-DSS conformance pack has `97` AWS Config rules

Assuming `10,000` configuration items recorded across various resource types per account per region and `300` AWS Config rule evaluations per AWS Config rule, lets take a look at 3 use cases


_Use case I(Enabling AWS Config in ONLY the Infrastructure OU)_

Total no of accounts = `4`

Total no of regions = `5`

Total no of conformance packs = `2` i.e (60 + 97) * 300 = `47,100` conformance pack evaluations

Cost of conformance packs for the first 100,000 conformance pack evaluations at $0.001 each = `47,100` * `$0.001` = `$47.1`

Cost of configuration items = `10,000` * `$0.003` = `$30`

Total AWS Config bill 

(`$47.1` + `$30`) * 4 * 5 = `$1,542`


_Use case II(Enabling AWS Config in all production accounts)_

Total no of accounts = `18`

Total no of regions = `5`

Total no of conformance packs = `2` i.e (60 + 97) * 300 = `47,100` conformance pack evaluations

Cost of conformance packs for the first 100,000 conformance pack evaluations at $0.001 each = `47,100` * `$0.001` = `$47.1`

Cost of configuration items = `10,000` * `$0.003` = `$30`

Total AWS Config bill 

(`$47.1` + `$30`) * 18 * 5 = `$6,939`


_Use case III(Enabling AWS Config in all accounts)_

Total no of accounts = `57`

Total no of regions = `5`

Total no of conformance packs = `2` i.e (60 + 97) * 300 = `47,100` conformance pack evaluations

Cost of conformance packs for the first 100,000 conformance pack evaluations at $0.001 each = `47,100` * `$0.001` = `$47.1`

Cost of configuration items = `10,000` * `$0.003` = `$30`

Total AWS Config bill 

(`$47.1` + `$30`) * 57 * 5 = `$21,973.5`


Find the link to the config pricing and calculator below

[ConfigPricing](https://aws.amazon.com/config/pricing/)

[ConfigCalculator](https://calculator.aws/#/createCalculator/Config)



<ins>__Impact of Solution__</ins>

_Pros_
- AWS Config provides comprehenzive visibility into the configuration of resources across your aws account as well as a resource inventory.
- By continuously monitoring resource configurations, AWS Config helps identify unauthorized changes and misconfigurations, allowing for timely remediation.
- AWS Config facilitates compliance management by providing automated assessments against predefined or custom rules, helping organizations adhere to regulatory requirements and internal policies.

_Cons_
- Enabling AWS Config incurs additional cost based on the number of configuration items recorded, the number of active AWS Config rule evaluations, and the number of conformance pack evaluations per region per account.



<ins>__Long Term Solution__</ins>

We can define AWS Config managed and custom rules that automatically audit the Organization against predefined security policies like misconfigured security groups and automatically remediate non-compliant resources by triggering AWS Lambda functions to apply necessary changes, such as modifying Security group entries to restrict access.