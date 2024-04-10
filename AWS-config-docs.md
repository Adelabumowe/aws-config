# Setting up Config in AWS Organization

<ins>___Summary___</ins>

This document outlines the importance of AWS Config, the step by step guide to enabling AWS Config in Loyalty AWS Organization. The primary aim of enabling aws config is to gain visibility and control over the configuration of resources within your AWS environment

<ins>___Goal___</ins>

The primary goal is to ensure that all resources are continuously monitored and tracked and if in an event a resource becomes uncompliant, automated remediation strategies are kicked into operation.

<ins>Solution</ins>

The strategy involves the implentation of a script that automatically creates cloudformation stacks which in turn enables AWS Config across Loyalty AWS Organization. This proposed method ensures that when a new aws account is added to the organization, AWS config is automatically enabled in all regions in that account.

<ins>Plan of execution</ins>

Note: These commands must be run by an administrator i.e 

- Using your credentials from the management account or
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

This script creates a stackset in the masteraccount using the delegated admin credentials. The stackset in turn creates cloudformation stacks that enables aws config in every enabled region in every account asides the master account(This was created in the first step). See below images

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

<ins>Step 3</ins>: Deploy AWS Config Conformance Packs of your chosing across your Organization to help manage compliance of your AWS resources at scale using common frameworks and also set up an aggregator which collects AWS Config configuration and Compliance data from multiple regions in multiple accounts.

_Note_:  This script might take a while to complete

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

<ins>Step 2</ins>: Set up an aggregator which collects AWS Config configuration and Compliance data from multiple regions in multiple accounts and deploys AWS Config Conformance Packs across your Organization to help manage compliance of your AWS resources at scale using common frameworks.

Using the management profile/delegated admin, run 
```sh
./aggregatorandconformancepacks.sh
```

[List of Conformance Packs](https://github.com/awslabs/aws-config-rules/tree/master/aws-config-conformance-packs)



<ins>___Pricing model___</ins>

You pay per configuration item delivered in your AWS account per AWS Region and a configuration item is created whenever a resource undergoes a configuration change for example, when a security group is changed. Configuration items can be delivered periodically or continuously

Periodic Recording(Every 24hrs, only if a change occurs) per configuration item per account per region is $0.0012
Continuous Recording(Immediately a change occurs) per configuration item per account per region is $0.003

You are also charged based on the number of AWS Config rule evaluations recorded and a rule evaluation is recorded every time a resource is evaluated.

First `100,000` rule evaluations costs `$0.001` per rule evaluation per region.

Next `400,000` rule evaluations `(100,001-500,000)` costs `$0.0008` per rule evaluation per region.

`500,001` and more rule evaluations costs `$0.0005` per rule evaluation per region

You are also charged for conformance pack evaluation

First `100,000` conformance pack evaluations costs `$0.001` per conformance pack evaluation per region.

Next `400,000` conformance pack evaluations `(100,001-500,000)` costs `$0.0008` per conformance pack evaluation per region.

`500,001` and more conformance pack evaluations costs `$0.0005` per conformance pack evaluation per region


<ins>For example</ins>

You have the following usage in the `2` enabled regions in `2` accounts in a given month:

`9,000` configuration items recorded across various resource types(Assuming `300` items per day i.e Lets say `10` items for each of the `30` resources)

`50,000` AWS Config rule evaluations across all config rules in each region in each account

`1` [conformance pack](https://github.com/awslabs/aws-config-rules/blob/master/aws-config-conformance-packs/Operational-Best-Practices-for-CIS-AWS-v1.4-Level1.yaml) for CIS v1.4.0 benchmark containing `43` AWS Config rules with `200` rule evaluations per AWS Config rule

<ins>___Cost of configuration items___</ins>

Continuous recording : `9000` * `2 regions` * `2 accounts` * `$0.003` = `$108`

Periodic recording : `1` period config item per resource * `30 resources` * `30 days` * `2 regions` * `2 accounts` * `$0.012` = `$43.2`

<ins>___Cost of AWS config rules___</ins>

First `100,000` evaluations at `$0.001` each = `50,000` * `2 regions` * `2 accounts` * `$0.001` = `$200`

<ins>___Cost of conformance pack___</ins>

Total no of conformance pack evaluation = `1` * `43` * `200` * `2 regions` * `2 accounts` = `34,400` conformance pacls evaluations

First `100,000` conformance pack evaluations at `$0.001` each = `34,400` * `$0.001` = `$34.4`

<ins>___Total monthly cost___</ins>

Continuous recording - `108` + `200` + `34.4` = `$342.4`

Periodic recording - `43.2` + `200` + `34.4` = `$277.6`

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