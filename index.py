from __future__ import print_function

import boto3
import datetime
import os
import time
import tscribe
import urllib.request
from urllib.parse import unquote_plus
from botocore.exceptions import ClientError
from lxml import etree

def test():
    transcribe = boto3.client('transcribe', region_name='eu-west-2')
    x = datetime.datetime.now()
    print("Compiles")
    return "Compiles"

def handler(event, context):
    transcribe = boto3.client('transcribe', region_name='eu-west-2')
    for record in event['Records']:
        x = datetime.datetime.now()
        
        number_of_speakers = int(os.getenv('ENV_NUMBER_OF_SPEAKERS'))
        s3_bucket = record['s3']['bucket']['name']
        s3_filekey = unquote_plus(record['s3']['object']['key'])
        job_name = "Transcribe-Video-" + x.strftime("%Y-%m-%d-%H-%M-%S")
        job_uri = "s3://"+s3_bucket+"/"+s3_filekey
        print(job_uri)

        transcribe.start_transcription_job(
            TranscriptionJobName=job_name,
            Media={'MediaFileUri': job_uri},
            MediaFormat='mp4',
            LanguageCode='en-GB',
            Settings={
                'ShowSpeakerLabels': True,
                'MaxSpeakerLabels': number_of_speakers,
            },
        )

        while True:
            status = transcribe.get_transcription_job(TranscriptionJobName=job_name)
            if status['TranscriptionJob']['TranscriptionJobStatus'] in ['COMPLETED', 'FAILED']:
                break
            print("Transcribing...")
            time.sleep(5)


        s3_client = boto3.client('s3')
        try:
            local_json_file = '/tmp/local_saved_file'
            urllib.request.urlretrieve(status['TranscriptionJob']['Transcript']['TranscriptFileUri'], local_json_file)
            bucket = os.getenv('ENV_S3BUCKET')
           
            object_json_name = s3_filekey+'-transcript.json'
            response = s3_client.upload_file(local_json_file, bucket, object_json_name)
            
            # convert json to docx
            object_docx_name = s3_filekey+"-transcript.docx"
            local_docx_file = '/tmp/' + object_docx_name
            tmp_dir = '/tmp/'
            tscribe.write(local_json_file, save_as=local_docx_file, tmp_dir=tmp_dir)

            #upload docx to s3
            response = s3_client.upload_file(local_docx_file, bucket, object_docx_name)

            # # delete transcription job
            # transcribe.delete_transcription_job(
            #     TranscriptionJobName=job_name
            # )

        except ClientError as e:
            logging.error(e)
            return False

    return "Complete"
