
# Manually create an IAM user and set permissions
The folowing JSON shows the required IAM permissions. You must change your bucket name in the below example from `transcribe-everything-placed-here`. If required, you can also rename the function from `CreateTranscription`. Be aware template.yaml must be updated to reflect your changes. 
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "iam:GetRole",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "lambda:CreateFunction",
                "lambda:GetFunctionConfiguration",
                "lambda:UpdateFunctionCode"
            ],
            "Resource": [
                "arn:aws:lambda:*:*:function:transcribe-on-s3-upload-CreateTranscription*"
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


# Manual steps if you are not using CI
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

