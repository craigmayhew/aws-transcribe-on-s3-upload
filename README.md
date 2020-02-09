# AWS Transcribe on S3 Upload
An AWS stack that upon upload of mp4 files, adds docx transcriptions to the same bucket.

[![Build Status](https://travis-ci.org/craigmayhew/aws-transcribe-on-s3-upload.svg?branch=master)](https://travis-ci.org/craigmayhew/aws-transcribe-on-s3-upload)

## Manually create an IAM user and set permissions
The folowing JSON shows the required IAM permissions. You must change your bucket name in the below example from `transcribe-everything-placed-here`. If required, you can also rename the function from `CreateTranscription`. Be aware template.yaml must be updated to reflect your changes. 
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
                "arn:aws:s3:::transcribe-everything-placed-here"
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


## Manual steps if you are not using CI
```sh
# deploy cloudformation stack
aws cloudformation create-stack --template-body file://template.yaml --capabilities CAPABILITY_IAM --stack-name "transcribe-on-s3-upload"
# update cloudformation stack
cat template.yaml template-after-create.yaml > template-update-stack.yaml
aws cloudformation update-stack --template-body file://template-update-stack.yaml --capabilities CAPABILITY_IAM --stack-name "transcribe-on-s3-upload"
# run build script to create a lambda zip with the python packages baked in
chmod +x build.sh
./build.sh
# deploy zip file over place holder lambda
aws lambda update-function-code \
  --region $REGION \
  --function-name CreateTranscription \
  --zip-file fileb://function.zip \
  --publish
```

## Thank you
https://github.com/kibaffo33/aws_transcribe_to_docx - my repo is just an aws deploy of kibaffo33's excellent repo.
