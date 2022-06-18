. ./secret_variables.ps1

# Create Buckets:
function create_bucket ($bucket_name) {
	aws s3api create-bucket `
		--bucket $bucket_name `
		--region us-east-1 `
		--object-ownership BucketOwnerEnforced `
		--output text >> setup.log
	aws s3api put-bucket-encryption `
		--bucket $bucket_name `
		--server-side-encryption-configuration '{\"Rules\": [{\"ApplyServerSideEncryptionByDefault\": {\"SSEAlgorithm\": \"AES256\"}}]}'
	aws s3api put-public-access-block `
		--bucket $bucket_name `
		--public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
}
	
create_bucket $bucket_raw
create_bucket $bucket_athena
create_bucket $bucket_clean
create_bucket $bucket_analytics

# Create Databases:
aws glue create-database `
	--database-input ('{\"Name\": \"' + $db_raw + '\", \"Description\": \"This database is created using AWS CLI\"}')

aws glue create-database `
	--database-input ('{\"Name\": \"' + $db_clean + '\", \"Description\": \"This database is created using AWS CLI\"}')

aws glue create-database `
	--database-input ('{\"Name\": \"' + $db_analytics + '\", \"Description\": \"This database is created using AWS CLI\"}')

# Create Roles:
aws iam create-role `
	--role-name $glue_role `
	--assume-role-policy-document file://policies/trust-glue.json
aws iam attach-role-policy `
	--role-name $glue_role `
	--policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
aws iam attach-role-policy `
	--role-name $glue_role `
	--policy-arn arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole

aws iam create-role `
	--role-name $lambda_role `
	--assume-role-policy-document file://policies/trust-lambda.json
aws iam attach-role-policy `
	--role-name $lambda_role `
	--policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
aws iam attach-role-policy `
	--role-name $lambda_role `
	--policy-arn arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole

# Create Crawlers:
aws glue create-crawler `
	--name $json_crawler `
	--database-name $db_raw `
	--role $glue_role `
	--targets '{\"S3Targets\": [{\"Path\": \"s3://' + $bucket_raw + '/youtube/raw_statistics_reference_data\"}]}'

aws glue create-crawler `
	--name $csv_crawler `
	--database-name $db_raw `
	--role $glue_role `
	--targets '{\"S3Targets\": [{\"Path\": \"s3://' + $bucket_raw + '/youtube/raw_statistics\"}]}'

aws glue create-crawler `
	--name $parquet_crawler `
	--database-name $db_clean `
	--role $glue_role `
	--targets '{\"S3Targets\": [{\"Path\": \"s3://' + $bucket_clean + '/youtube/raw_statistics\"}]}'

# Upload data:
aws s3 cp ./data s3://$bucket_raw/youtube/raw_statistics_reference_data/ `
	--recursive `
	--exclude "*" `
	--include "*.json"

aws s3 cp ./data/CAvideos.csv s3://$bucket_raw/youtube/raw_statistics/region=ca/
aws s3 cp ./data/DEvideos.csv s3://$bucket_raw/youtube/raw_statistics/region=de/
aws s3 cp ./data/CAvideos.csv s3://$bucket_raw/youtube/raw_statistics/region=ca/
aws s3 cp ./data/DEvideos.csv s3://$bucket_raw/youtube/raw_statistics/region=de/
aws s3 cp ./data/CAvideos.csv s3://$bucket_raw/youtube/raw_statistics/region=ca/
aws s3 cp ./data/DEvideos.csv s3://$bucket_raw/youtube/raw_statistics/region=de/
aws s3 cp ./data/FRvideos.csv s3://$bucket_raw/youtube/raw_statistics/region=fr/
aws s3 cp ./data/GBvideos.csv s3://$bucket_raw/youtube/raw_statistics/region=gb/
aws s3 cp ./data/INvideos.csv s3://$bucket_raw/youtube/raw_statistics/region=in/
aws s3 cp ./data/JPvideos.csv s3://$bucket_raw/youtube/raw_statistics/region=jp/
aws s3 cp ./data/KRvideos.csv s3://$bucket_raw/youtube/raw_statistics/region=kr/
aws s3 cp ./data/MXvideos.csv s3://$bucket_raw/youtube/raw_statistics/region=mx/
aws s3 cp ./data/RUvideos.csv s3://$bucket_raw/youtube/raw_statistics/region=ru/
aws s3 cp ./data/USvideos.csv s3://$bucket_raw/youtube/raw_statistics/region=us/

# Run Crawlers:
aws glue start-crawler --name $json_crawler
aws glue start-crawler --name $csv_crawler
aws glue start-crawler --name $parquet_crawler











