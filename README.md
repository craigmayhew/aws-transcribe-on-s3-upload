# AWS Transcribe on S3 Upload

[![Build Status](https://travis-ci.org/craigmayhew/aws-transcribe-on-s3-upload.svg?branch=master)](https://travis-ci.org/craigmayhew/aws-transcribe-on-s3-upload)

An AWS stack that upon upload of mp4 files, adds docx transcriptions to the same bucket.

In this document I will being using AWS Region **eu-west-2** throughout.
### 1 Create an IAM user and set permissions

In the AWS Console create an IAM User and attach an IAM security policy as shown below.

You must change your bucket name in the below example from `transcribe-on-s3-upload`. 

If required, you can also rename the function from `CreateTranscription`. 
Be aware **template.yaml** must be updated to reflect your changes. 

**JSON Policy Document**
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "iam:CreateRole",
                "iam:DeleteRolePolicy",
                "iam:GetRole",
                "iam:PassRole",
                "iam:PutRolePolicy"
            ],
            "Resource": "arn:aws:iam::*:role/transcribe-on-s3-upload-LambdaExecutionRole-*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "lambda:AddPermission",
                "lambda:CreateFunction",
                "lambda:DeleteFunction",
                "lambda:GetFunctionConfiguration",
                "lambda:GetFunction",
                "lambda:UpdateFunctionConfiguration",
                "lambda:UpdateFunctionCode"
            ],
            "Resource": [
                "arn:aws:lambda:*:*:function:CreateTranscription"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutBucketNotification",
                "s3:CreateBucket"
            ],
            "Resource": [
                "arn:aws:s3:::transcribe-on-s3-upload"
            ]
        },
        {
            "Effect": "Allow",
            "Action": "cloudformation:*",
            "Resource": "arn:aws:cloudformation:*:*:stack/transcribe-on-s3-upload/*"
        }
    ]
}
```


### 2 Manual steps to deploy AWS Resources

If you are not going to deploy with CI then you can either use the provided script or run the build and deployment steps in your terminal with the provided instructions.

Make sure you have:
* Installed the AWS cli using these [instructions](https://docs.aws.amazon.com/cli/latest/userguide//install-cliv1.html). I have built and tested this solution with awscli version **1.17.10** 
* Configured an IAM User  with the permissions listed above.
* Created a set of AWS Access keys for the IAM User created in step 2 and installed them on your local machine under an [awscli profile](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html).

#### 2.1 macOS Catalina (10.15.x)

Use  [deploy-locally-macos.sh](deploy-locally-macos.sh) to deploy a Cloudformation stack from your mac to AWS. 

This script will create a local docker environment and build **function.zip** before deploying a Cloudformation Stack that will host the necessary resources to support transcribing video to a word document. **function.zip** is then deployed into the Cloudformation stack.

This script will install a number of software components locally: 
* Install [awscli](https://docs.aws.amazon.com/cli/latest/userguide//install-cliv1.html) if its not found.
* Install [docker](https://docs.docker.com/v17.09/machine/install-machine/) but it won't be able to start it first time around. Reboot your machine and run this script again for first successful deploy.
* Install [docker-machine](https://docs.docker.com/v17.09/machine/overview/)
* Install or upgrade [virtualbox](https://www.virtualbox.org/wiki/Downloads). Apple have added extra security which means virtualbox will not have permissions to run. Follow these instructions:
>  1 Restart your mac in Recovery mode (cmd + R)
   2 Open a **Terminal** and enter:
   3 **spctl kext-consent add VB5E2TV963**
   4 Restart your mac.


Run deployment script:
```
chmod 775 ./deploy-locally-macos.sh
./deploy-locally-macos.sh my-aws-dev-profile
```

#### 2.2 Other Operating Systems using bash shell


##### Build function.zip

It is assumed that
* **awscli** is installed. [Install instructions](https://docs.aws.amazon.com/cli/latest/userguide//install-cliv1.html)
* **docker** is installed and running. [Install Instructions](https://docs.docker.com/install/)
* **docker-machine** is installed. [Install Instructions](https://docs.docker.com/v17.09/machine/install-machine/)
* **virtualbox** is installed. [Install Instructions](https://www.virtualbox.org/wiki/Downloads)

##### Build Script
```
#!/bin/bash
yes | docker-machine rm  default
docker-machine create --driver virtualbox default
docker-machine env default
eval $(docker-machine env default)
rm -Rf ${PWD}/package
docker rm transcriber:local
docker build -t transcriber:local .
docker run -v ${PWD}:/var/app -w /var/app -it transcriber:local /bin/sh -c "chmod +x build.sh && ./build.sh; exit"
```


##### Deploy AWS Resources
```
#!/bin/bash
REGION=eu-west-2
STACK_NAME=transcribe-on-s3-upload
LAMBDA_FUNCTION_NAME=CreateTranscription
S3_TRANSCRIBE_BUCKET_NAME=transcribe-on-s3-upload
AWS_PROFILE=my-aws-dev-profile
#
# Cloudformation arguments.
#
args=(
    --region ${REGION} 
    --stack-name ${STACK_NAME} 
    --parameter-overrides S3Bucket=${S3_TRANSCRIBE_BUCKET_NAME} 
    --capabilities CAPABILITY_IAM
)
#
# Lambda deploy arguments.
#
lambda_args=(
    --region ${REGION} 
    --function-name $LAMBDA_FUNCTION_NAME 
)
echo -e "\nDeploying Cloudformation Stack..."
aws cloudformation deploy --template-file template.yaml "${args[@]}"

echo -e "\nDeploying freshly built lambda"
aws lambda update-function-code "${lambda_args[@]}" --zip-file fileb://function.zip  --publish

```
### 3 Test a Transcription
##### 3.1 Test Transcription on macOS via script


You will need: 
* An mp4 video or audio file e.g test.mp4. 
* Configured a local **AWS Profile** using the keys generated and attached as an output to the stack you deployed above. See the outputs section of your Cloudformation Stack.

I have hardcoded the S3 bucket to **transcribe-on-s3-upload** in the script below. 
Edit environment variable **S3_TRANSCRIBE_BUCKET_NAME** as appropriate.

Usage:
```
./transcription-test-macos.sh my-test-profile mp4-file number-of-speakers-in-file
```

Example:
Here my configured AWS Profile is called **my-test-profile**
```
chmod 775 ./transcription-test-macos.sh
./transcription-test-macos.sh my-test-profile test.mp4 4
```

You will see output similiar to this:
```
Current status Transcription Job is: IN_PROGRESS
Checking status again in 30 seconds....
.
.
.
Checking status again in 30 seconds....
Current status Transcription Job is: IN_PROGRESS

Transcription Complete. Let's wait for 2 mins to allow the docx file to be generated.
```

If Microsoft Word is installed on your machine you should see a transcription of your mp4 file :). Otherwise you can open it in any program that supports **docx**.

##### 3.2 Test Transcription via user upload

You can also test transcribing a file by uploading it to the S3 bucket you created  earlier and just wait for the transcription to appear in the bucket. 

###### 3.2.1 awscli from command line

I'm using **test.mp4** as my test file.
If your S3 bucket is called **transcribe-on-s3-upload** then you can use the AWS keys generated during stack deployment above to upload a file to S3. Below I created a **AWS_PROFILE** and attached my keys

```
AWS_PROFILE=my-test-profile
AWS_DEFAULT_REGION=eu-west-2
aws s3 cp test.mp4 s3://transcribe-on-s3-upload 
```

You can keep an eye on the contents of bucket:
```
aws s3 ls s3://transcribe-on-s3-upload/test* 
```
For a file called **test.mp4** you should eventually see a transcription docx file called **test.mp4-transcript.docx**. Copy the file locally with the following command:
```
aws s3 cp s3://transcribe-on-s3-upload/test.mp4-transcript.docx .
```

##### 3.3 Test Transcription via File Transfer Application

* Install your application of choice that supports AWS S3. 
* Configure with access keys as generated by our Cloudformaton stack deployment above
* Upload your **test.mp4** file and wait for your **test.mp4-transcript.docx** file to appear in the same folder

#### 4 Debug Lambda locally

You do not have to deploy a function to AWS to see if it works. It can happen on your local machine. AWS supply docker machine images for all supported Lambda environments.

Here is a quick overview.
###### Example Function

lambdaTest.py
```
from __future__ import print_function

import boto3
import datetime
import os
import time
import urllib.request
from urllib.parse import unquote_plus
from botocore.exceptions import ClientError

def handler(event, context):
    x = datetime.datetime.now()
    print("Compiles")
    return "Complete"
```

Make sure you have installed and started docker on your machine and you are in the same folder as the test function above.

In one terminal run:
```

docker run --rm   -e DOCKER_LAMBDA_STAY_OPEN=1 -p 9001:9001   -v "$PWD":/var/task:ro,delegated   lambci/lambda:python3.7 lambdaTest.handler
```

Output:
```
Lambda API listening on port 9001...
```
In a second terminal run:
```
aws lambda invoke --endpoint http://localhost:9001 --region eu-west-2 --no-sign-request   --function-name 'lambdaTest' --payload '{}' output.json
cat output.json
```

Output:
```
{
    "StatusCode": 200,
    "ExecutedVersion": "$LATEST"
}

"Complete"

```

The first terminal simulates a lambda machine and the second terminal simulates a function call.

##### References
https://hub.docker.com/r/lambci/lambda/#docker-tags
https://hub.docker.com/r/lambci/lambda/tags
https://aws.amazon.com/premiumsupport/knowledge-center/lambda-layer-simulated-docker/

## Thank you
https://github.com/kibaffo33/aws_transcribe_to_docx - my repo is just an aws deploy of kibaffo33's excellent repo.
