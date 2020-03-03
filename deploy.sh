# Thanks to https://gist.github.com/mdjnewman/b9d722188f4f9c6bb277a37619665e77 
#!/bin/bash
# set -x

REGION=eu-west-2
STACK_NAME=transcribe-on-s3-upload
LAMBDA_FUNCTION_NAME=CreateTranscription
S3_TRANSCRIBE_BUCKET_NAME=transcribe-on-s3-upload
CLI_ARGUMENT_COUNT="1"

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

#
# Test to see if script was called locally supplying an AWS profile name as parameter. 
# If a profile parameter is found then configure aws arguments with supplied profile.
#
if [ "$#" == "${CLI_ARGUMENT_COUNT}" ];
then

  echo
  echo "We are deploying locally..."
  echo

  PROFILE_PARAM=$1

  args+=(
    --profile ${PROFILE_PARAM}
  )

  lambda_args+=(
    --profile ${PROFILE_PARAM}
  )

else
  echo
  echo "We are deploying using CI..."
  echo
fi 

echo -e "\nDeploying Cloudformation Stack..."

aws cloudformation deploy --template-file template.yaml "${args[@]}"


echo -e "\nDeploying freshly built lambda"
aws lambda update-function-code "${lambda_args[@]}" --zip-file fileb://function.zip  --publish

# All is well
exit 0