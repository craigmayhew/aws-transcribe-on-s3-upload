# Thanks to https://gist.github.com/mdjnewman/b9d722188f4f9c6bb277a37619665e77 

REGION=us-east-1
STACK_NAME=transcribe-on-s3-upload

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

  set +e
  update_output=$( aws cloudformation update-stack \
    --region $REGION \
    --stack-name $STACK_NAME \
    --template-body file://template.yaml \
    --capabilities CAPABILITY_IAM 2>&1)
  status=$?
  set -e

  echo "$update_output"

  if [ $status -ne 0 ] ; then

    # Don't fail for no-op update
    if [[ $update_output == *"ValidationError"* && $update_output == *"No updates"* ]] ; then
      echo -e "\nFinished create/update - no updates to be performed"
      exit 0
    else
      exit $status
    fi

  fi


  echo "Waiting for stack update to complete ..."
  aws cloudformation wait stack-update-complete \
    --region $REGION \
    --stack-name $STACK_NAME \

fi

# once stack is ready, update lambda function with one we built in CI
echo -e "\nStack ready ... Deploying freshly built lambda"
