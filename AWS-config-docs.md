# Setting up Config in AWS Organization

<ins>___Summary___</ins>

This document outlines the importance of AWS Config, Pricing comparison and the step by step guide to enabling AWS Config in an AWS Organization. The primary aim of enabling aws config is to gain visibility and control over the configuration of resources within your AWS environment

<ins>___Goal___</ins>

The primary goal is to ensure that all resources are continuous monitored and tracked and if in an event a resource becomes uncompliant, automated remediation strategies are kicked into operation.

<ins>Solution</ins>

The strategy involves the implentation of a script that automatically creates cloudformation stacks which in turn creates aws config service linked roles and then proceeds to enable AWS Config across the AWS Organization. This proposed method ensures that when a new aws account is added to the organization, AWS config is automatically enabled in all regions in that account. Using this method won't enable AWS Config in the management account; so that can be done by using a script as shown below

<ins>Plan of execution</ins>

Note: These commands must be run by an administrator i.e either using your credentials from the management account or by registering a delegated administrator.

Note: To register a delegated admin, run the below command using your credentials from the management account___(Edit the script and add the preferred account ID)___
```sh
./createdelegatedadmin.sh
```

Step 1: Create a cloudformation stackset which deploys a stack that creates aws config service linked roles in all target accounts in your organization 

Using the management profile, run 
```sh
./servicelinkedrole.sh
```
Using the delegated admin profile, run 
```sh
./servicelinkedroledelegated.sh
```

Step 2: When step 1 is done, proceed to create a cloudformation stackset which deploys a stack that enables aws config across all accounts in the organization

Using the management profile, run 
```sh
./config.sh
```
Using the delegated admin profile, run 
```sh
./configdelegated.sh
```

Step 3: Set up an aggregator which collects AWS Config configuration and Compliance data from multiple regions in multiple accounts

Using the management profile, run 
```sh
./configaggregator.sh
```
Using the delegated admin profile, run 
```sh
./configaggregator.sh
```

<ins>___Pricing model___</ins>

You pay per configuration item delivered in your AWS account per AWS Region and a configuration item is created whenever a resource undergoes a configuration change for example, when a security group is changed. Configuration items can be delivered periodically or continuously

Periodic Recording(Every 24hrs, only if a change occurs) per configuration item per account per region is $0.0012
Continuous Recording(Immediately a change occurs) per configuration item per account per region is $0.003

You are also charged based on the number of AWS Config rule evaluations recorded and a rule evaluation is recorded every time a resource is evaluated.

First `100,000` rule evaluations costs `$0.001` per rule evaluation per region.

Next `400,000` rule evaluations `(100,001-500,000)` costs `$0.0008` per rule evaluation per region.

`500,001` and more rule evaluations costs `$0.0005` per rule evaluation per region

<ins>For example</ins>

You have the following usage in the `2` enabled regions in `2` accounts in a given month:

`9,000` configuration items recorded across various resource types(Assuming `300` items per day i.e Lets say `10` items for each of the `30` resources)

`50,000` AWS Config rule evaluations across all config rules in each region in each account

<ins>___Cost of configuration items___</ins>

Continuous recording : `9000` * `2 regions` * `2 accounts` * `$0.003` = `$108`

Periodic recording : `1` period config item per resource * `30 resources` * `30 days` * `2 regions` * `2 accounts` * `$0.012` = `$43.2`

<ins>___Cost of AWS config rules___</ins>

First `100,000` evaluations at `$0.001` each = `50,000` * `2 regions` * `2 accounts` * `$0.001` = `$200`

<ins>___Total monthly cost___</ins>

Continuous recording - `108` + `200` = `$308`

Periodic recording - `43.2` + `200` = `$243.2`

Find the link to the config calculator below
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