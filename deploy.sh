# Thanks to https://gist.github.com/mdjnewman/b9d722188f4f9c6bb277a37619665e77 

REGION=eu-west-2
STACK_NAME=transcribe-on-s3-upload
LAMBDA_FUNCTION_NAME=CreateTranscription

# check if cloudformation stack exists
if ! aws cloudformation describe-stacks --region $REGION --stack-name $STACK_NAME ; then
  # install stack if does not exist
  echo -e "\nStack does not exist, creating ..."
  aws cloudformation create-stack \
    --region $REGION \
    --stack-name $STACK_NAME \
    --template-body file://template.yaml \
    --capabilities CAPABILITY_IAM

  echo "Waiting for stack to be created ..."
  aws cloudformation wait stack-create-complete \
    --region $REGION \
    --stack-name $STACK_NAME \

else
  # update stack if it already exists
  echo -e "\nStack exists, attempting update ..."

  # concat s3 notifications on to our cloudformation template
  # we do this only on update of stack, as s3 has a limitation
  # where you can't define bucket notifications on bucket create
  # sadly this requires this deploy be run twice on the first ever deploy
  cat template.yaml template-after-create.yaml > template-update-stack.yaml

  set +e
  update_output=$( aws cloudformation update-stack \
    --region $REGION \
    --stack-name $STACK_NAME \
    --template-body file://template-update-stack.yaml \
    --capabilities CAPABILITY_IAM 2>&1)
  status=$?
  set -e

  echo "$update_output"

  if [ $status -ne 0 ] ; then

    # Don't fail for no-op update
    if [[ $update_output == *"ValidationError"* && $update_output == *"No updates"* ]] ; then
      echo -e "\nFinished create/update - no updates to be performed"
    else
      exit $status
    fi

  else
    echo "Waiting for stack update to complete ..."
    aws cloudformation wait stack-update-complete \
      --region $REGION \
      --stack-name $STACK_NAME
  fi

fi

# horrible workaround because lambda doesn't support
# uploading zipfiles for python3.8 runtimes at present
# so we set to 3.7 before upload of zipfile
aws lambda update-function-configuration \
   --region $REGION \
   --function-name $LAMBDA_FUNCTION_NAME
   --runtime python3.7

# once stack is ready, update lambda function with one we built in CI
echo -e "\nStack ready ... Deploying freshly built lambda"
aws lambda update-function-code \
  --region $REGION \
  --function-name $LAMBDA_FUNCTION_NAME \
  --zip-file fileb://function.zip \
  --publish

# horrible workaround because lambda doesn't support
# uploading zipfiles for python3.8 runtimes at present
# so we set to 3.8 after upload of zipfile
aws lambda update-function-configuration \
   --region $REGION \
   --function-name $LAMBDA_FUNCTION_NAME
   --runtime python3.8

echo -e "\nLambda updated"

# All is well
exit 0

