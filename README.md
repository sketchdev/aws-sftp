# aws-sftp
There are tutorials on the internet of setting up SFTP servers in Linux. There are tutorials out there for using S3 as a mounted file system. This tutorial sets out to combine these two concepts in addition to setting up a fault-tolerant, highly-available environment in which to deploy your resulting server ready for production use.

To view our reference article, please visit http://sketchdev.io/set-up-an-sftp-server-backed-by-s3-on-aws/

## Project Setup ##
The main file for this project is `resources/sftp-setup.template`. It's a CloudFormation template file that leverages AWS' Auto Scaling service, which needs some resource files stored in S3 as it launches new/multiple servers. In just a moment, we'll walk you through getting those files in place. Given the parameterized nature of this CloudFormation template, we suggest that you leverage the AWS Console for launching this stack if you are fairly unfamiliar with AWS and its features.

For the duration of this setup, whenever you see "yourcompany", please replace it with a lowercased, hyphenated (non-space) version of the name. For example, if your company name is "ACME Widgets, Inc.", please use "acme-widgets-inc" as the substitute.

### Add Ancillary Files ###
If you don't already have command line access to AWS, please see their [documentation](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html) for setting that up. Once that's in place, run through the rest of this segment using the AWS CLI.

Create some buckets in S3 (remember to replace "yourcompany" in the instructions below!):

```bash
aws s3 mb s3://yourcompany-ftp
aws s3 mb s3://yourcompany-development-software
aws s3 mb s3://yourcompany-keys
```

Upload the sample files:

```bash
# copy the user setup script
aws s3 cp resources/user-setup.sh s3://yourcompany-development-software/ftp/

# copy the sample users file
aws s3 cp ancillary-resources/sample-users/users.csv s3://yourcompany-development-software/ftp/

# copy all sample host keys
aws s3 cp ancillary-resources/sample-hostkeys/ s3://yourcompany-keys/ftp/ --recursive
```

## Launch the Server ##
Now that the setup is complete, launch the `sftp-setup.template` CloudFormation template in AWS. As previously mentioned, we recommend launching it via the AWS Console if you are unfamiliar with parameterized templates. View the [AWS documentation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-console-create-stack.html) for the latest instructions on launching a CloudFormation stack via the console.

## Connect ##
Once the stack has launched successfully, you should be able to connect to it. Inside this project under `ancillary-resources/sample-users/` is a users.csv file that you've hopefully looked at already before launching this thing. It has sample usernames and passwords (among other things) that get created on the server when it launches. Use one of these users to try and connect to your server.

If you enabled DNS when launching the CloudFormation stack by setting `EnableDNS` to true, you should be able to hit your SFTP server at the domain you specified. However, if you did NOT set `EnableDNS` to true, you can connect to the SFTP server through the Elastic Load Balancer (ELB) created by the template. The DNS record for the ELB can be found by using the following command:

```bash
aws elb describe-load-balancers --load-balancer-names development-Sftp --query 'LoadBalancerDescriptions[*].{SftpDns:DNSName}' --output text
```
