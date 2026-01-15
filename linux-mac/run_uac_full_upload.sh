#!/bin/bash

#Unzip UAC to current directory

tar -xzf uac.tar.gz 

read -rp "S3 bucket region (e.g. us-east-1): " bucket_region
read -rp "S3 bucket name for upload (e.g. '2025-case-a' w/o quotes): " bucket_name
read -rp "Access key for secure upload: " access_key
read -rp "Secret key for secure upload: " secret_key

echo "Review settings: $bucket_region : $bucket_name : $access_key : $secret_key" 
read -rp "Confirm execution? (y/n):" confirm_execution

if [[ "$confirm_execution" =~ ^[Yy]$ ]]; then
  cd  uac-3.2.0
  sudo ./uac -p profiles/full.yaml -o uac-%hostname%-%timestamp% --s3-provider amazon --s3-region bucket_region --s3-bucket $bucket_name --s3-access-key $access_key --s3-secret-key $secret_key ../
else
   "Cancelled. Re-run to correct input errors."
fi
