# Thanks to https://gist.github.com/mdjnewman/b9d722188f4f9c6bb277a37619665e77 
#!/bin/bash

REGION=eu-west-2
STACK_NAME=transcribe-on-s3-upload
LAMBDA_FUNCTION_NAME=CreateTranscription #Change function name here if you wish.
S3_TRANSCRIBE_BUCKET_NAME=transcribe-on-s3-upload
S3_TRANSCRIBE_DEPLOYMENT_BUCKET_NAME=${S3_TRANSCRIBE_BUCKET_NAME}-deploy
CLI_ARGUMENT_COUNT="1"

#
# Cloudformation arguments.
#
args=(
    --region ${REGION} 
    --stack-name ${STACK_NAME} 
    --parameter-overrides S3Bucket=${S3_TRANSCRIBE_BUCKET_NAME} \
                          LambdaFunctionName=${LAMBDA_FUNCTION_NAME}
    --capabilities CAPABILITY_IAM
)

#
# Lambda deploy arguments.
#
lambda_args=(
    --region ${REGION} 
    --function-name ${LAMBDA_FUNCTION_NAME} 
)

s3_deployment_args=(
    --region ${REGION} 
)
#
# Test to see if script was called locally supplying an AWS profile name as parameter. 
# If a profile parameter is found then configure aws arguments with supplied profile.
#
# If we do not find a profile configured then we assume the AWS Credentials have created as a set of environment variables.
#
if [ "$#" == "${CLI_ARGUMENT_COUNT}" ];
then

  echo
  echo "We are deploying from a local machine..."
  echo

  PROFILE_PARAM=$1

  args+=(
    --profile ${PROFILE_PARAM}
  )

  lambda_args+=(
    --profile ${PROFILE_PARAM}
  )

  s3_deployment_args+=(
    --profile ${PROFILE_PARAM}
  )

else
  echo
  echo "Assuming we are deploying using CI..."
  echo
fi 

echo -e "\nDeploying Cloudformation Stack..."

#
# Deploy our Cloudformation Stack
#

aws cloudformation deploy --template-file aws-templates/create-transcribe-application-template.yaml "${args[@]}" 

#
# Deploy our Lambda Function to AWS. We need to copy the file to an S3 bucket first and then deploy from  the bucket.
# 
# This is allow out 60M to get around the size limitation when updating an existing lambda function.
#
echo
echo -e "\nDeploying freshly built lambda"
echo
#
# Create our deployment bucket
#
echo "Create our deployment bucket"

LOOK_FOR_BUCKET=`aws s3 ls "${s3_deployment_args[@]}" s3://${S3_TRANSCRIBE_DEPLOYMENT_BUCKET_NAME}`

if [ -z ${LOOK_FOR_BUCKET} ];
then
    echo "S3 Bucket does not exist... Lets create it..."
    aws s3 mb s3://${S3_TRANSCRIBE_DEPLOYMENT_BUCKET_NAME} "${s3_deployment_args[@]}"
else
    echo "S3 Bucket already exists..."
fi

#
# Upload our zipfile
#
echo
echo "Upload our zipfile"
echo
aws s3 cp build/function.zip s3://${S3_TRANSCRIBE_DEPLOYMENT_BUCKET_NAME} "${s3_deployment_args[@]}"

#
# Deploy the lambda in function.zip over the existing stub lambda function
#
echo
echo "Deploy the lambda in function.zip over the existing stub lambda function"
echo

aws lambda update-function-code "${lambda_args[@]}" --s3-bucket ${S3_TRANSCRIBE_DEPLOYMENT_BUCKET_NAME} --s3-key function.zip  --publish > /dev/null 2>&1

# set to 3.7 after upload of zipfile

aws lambda update-function-configuration "${lambda_args[@]}" --function-name $LAMBDA_FUNCTION_NAME --runtime python3.7 > /dev/null 2>&1

#
# Delete our deployment bucket
#
echo
echo "Delete our deployment bucket"
echo

aws s3 rb s3://${S3_TRANSCRIBE_DEPLOYMENT_BUCKET_NAME}  "${s3_deployment_args[@]}" --force 
# All is well
exit 0
