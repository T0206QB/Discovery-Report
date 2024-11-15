date=$(date -d "yesterday" '+%Y-%m-%d')
echo $date
download_bucket="transformed-data-analytics-accessplus-prod"
upload_bucket="zipped-data-analytics-accessplus-prod"


local_dir="/home/ec2-user/report/Data/$date"
echo $local_dir
# SNS Topic ARN
sns_topic_arn="arn:aws:sns:us-east-2:542203793781:zipped-analytics-files-topic"


folder_exists=$(aws s3 ls s3://$download_bucket/$date/)
if [ -n "$folder_exists" ]; then
    # if Folder exists,lets download its contents
     mkdir -p $local_dir
     aws s3 cp s3://$download_bucket/$date/track/ $local_dir/ --recursive


    zip_file="/home/ec2-user/report/Data/$date.zip"
    zip -r $zip_file $local_dir

    aws s3 cp $zip_file s3://$upload_bucket/$date/

    pre_signed_url=$(aws s3 presign s3://$upload_bucket/$date/$(basename $zip_file) --expires-in 3600)
    aws sns publish --topic-arn $sns_topic_arn --message "Download the zipped data for $date: $pre_signed_url"

    # Delete the zip file locally
    rm $zip_file

    echo "Process completed successfully for $date."
else
    echo "Folder for $date does not exist in S3 bucket."
fi
