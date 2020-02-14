#!/bin/bash
# set -x

#
# Test the Transcribe stack
#

REGION=eu-west-2
S3_TRANSCRIBE_BUCKET_NAME=transcribe-on-s3-upload
LAMBDA_FUNCTION_NAME=CreateTranscription
CLI_ARGUMENT_COUNT="3"

#
# Transcribe test arguments
# 
transcribe_args=(
    --region ${REGION} 
)

#
# Lambda deploy arguments.
#
lambda_args=(
    --region ${REGION} 
    --function-name $LAMBDA_FUNCTION_NAME 
)

#
# Test to see if script was called with AWS profile parameter locally
#
if [ "$#" == "${CLI_ARGUMENT_COUNT}" ];
then 
  PROFILE_PARAM="$1"
  FILE_TO_TRANSCRIBE="$2"
  NUMBER_OF_SPEAKERS="$3"

  transcribe_args+=(
    --profile ${PROFILE_PARAM}
  )

  lambda_args+=(
    --profile ${PROFILE_PARAM}
  )

else
  echo 
  echo "Usage: ./transscription-test-macos.sh <aws-profile> <file.mp4> <number-speakers-in-mp4-file>"
  echo
  echo
  echo "Example ./transcription-test-macos.sh my-aws-dev-profile what-the-tech.mp4 4"
  echo
  exit 0
fi 

#
# Copy file to S3 bucket
#

echo
echo "Run a test transcription..."
echo

# FILE_TO_TRANSCRIBE=Mauled-by-Windows-10X-EHFKt0qh-fM.mp4
RUN_DATE_AND_TIME=`date +%d-%m-%Y-%H-%M-%S`
FILE_TO_TRANSCRIBE_UNIQ_temp=${RUN_DATE_AND_TIME}-${FILE_TO_TRANSCRIBE}
FILE_TO_TRANSCRIBE_UNIQ=${FILE_TO_TRANSCRIBE_UNIQ_temp//\ }

cp "${FILE_TO_TRANSCRIBE}" ${FILE_TO_TRANSCRIBE_UNIQ}
TRANSCRIPTION_DOCX=${FILE_TO_TRANSCRIBE_UNIQ}-transcript.docx

#
# Set the variable ENV_NUMBER_OF_SPEAKERS in $LAMBDA_FUNCTION_NAME  to the correct number of speakers.
#
aws lambda update-function-configuration  "${lambda_args[@]}" \
 --environment "Variables={"ENV_NUMBER_OF_SPEAKERS"='${NUMBER_OF_SPEAKERS}',"ENV_S3BUCKET"='${S3_TRANSCRIBE_BUCKET_NAME}'}"

#
# Upload mp4 file to S3
#
aws s3 "${transcribe_args[@]}" cp ${FILE_TO_TRANSCRIBE_UNIQ}  s3://${S3_TRANSCRIBE_BUCKET_NAME}

#
# Lets wait for 60 seconds to allow transcribe to startup
#

echo
echo "lets sleep for 60 seconds to allow transcribe to start-up..."
echo
sleep  60 


for jobName in `aws transcribe "${transcribe_args[@]}" list-transcription-jobs | jq '.TranscriptionJobSummaries[].TranscriptionJobName'`
do
  jobName_CLEAN=${jobName//\"}
  TRANSCRIBE_JOB_STATUS=`aws transcribe "${transcribe_args[@]}"  get-transcription-job --transcription-job-name ${jobName_CLEAN} | jq  ' .TranscriptionJob | select (.Media.MediaFileUri=="s3://'${S3_TRANSCRIBE_BUCKET_NAME}'/'${FILE_TO_TRANSCRIBE_UNIQ}'") ' | jq .TranscriptionJobStatus`

  TRANSCRIBE_JOB_STATUS_CLEAN=${TRANSCRIBE_JOB_STATUS//\"}

  if [ ! -z ${TRANSCRIBE_JOB_STATUS_CLEAN} ];
  then
    break;
  fi

done

while [[ ${TRANSCRIBE_JOB_STATUS_CLEAN} != COMPLETED ]];
do
  #
  # Output the current status of the Data Pipeline Runner...
  #
  echo "Current status Transcription Job is: ${TRANSCRIBE_JOB_STATUS_CLEAN}"

  #
  # Wait for a minute and check status again
  #

  echo "Checking status again in 30 seconds...."

  sleep 30

  #
  # Lets check the status again...
  #
  TRANSCRIBE_JOB_STATUS=`aws transcribe "${transcribe_args[@]}"  get-transcription-job --transcription-job-name ${jobName_CLEAN} \
                        | jq  ' .TranscriptionJob | select (.Media.MediaFileUri=="s3://'${S3_TRANSCRIBE_BUCKET_NAME}'/'${FILE_TO_TRANSCRIBE_UNIQ}'") ' | jq .TranscriptionJobStatus`

  TRANSCRIBE_JOB_STATUS_CLEAN=${TRANSCRIBE_JOB_STATUS//\"}
done

echo
echo  "Transcription Complete. Let's wait for 2 mins to allow the docx file to be generated."
echo 

sleep 120 

aws s3 "${transcribe_args[@]}" cp s3://${S3_TRANSCRIBE_BUCKET_NAME}/"${TRANSCRIPTION_DOCX}" . 

open /Applications/Microsoft\ Word.app ${TRANSCRIPTION_DOCX}

#
# 
#
# All is well
exit 0
