#Run the script from the dir where you've staged the the generic VR collector exe and the yaml file
#IMPORTANT: You'll need to edite the "your-triage_uploads" bucket name in the inline policy below to reflect an S3 bucket that exists in your AWS tenant. The script does not create the bucket, just the "folder"
#Change the "deployment_identifier" below for department or region or customer, etc. 
$deployment_identifier = "xyz-usa" 
$new_inline_policy = @"
{
    "Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "uploadonly",
			"Effect": "Allow",
			"Action": [
				"s3:PutObject"
			],
			"Resource": [
				"arn:aws:s3:::your-triage-uploads/$deployment_identifier",
				"arn:aws:s3:::your-triage-uploads/$deployment_identifier/*"
			]
		}
	]
}
"@
$json_inline_policy = $new_inline_policy > $deployment_identifier-upload-policy.json
#Make sure the "your-triage-uploads" bucket name matches your S3 bucket name below
Write-S3Object -BucketName your-triage-uploads -Key $deployment_identifier/ -Content $deployment_identifier
New-IAMUser -UserName $deployment_identifier 
Add-IAMUserTag -UserName $deployment_identifier -Tag @{ Key = 'Name'; Value = 'Triage Collector Upload User'}
Write-IAMUserPolicy -username $deployment_identifier -PolicyName $deployment_identifier'_upload_policy' -PolicyDocument (get-content -raw $deployment_identifier-upload-policy.json)
$deployment_creds = New-IAMAccessKey -UserName $deployment_identifier | Select-Object UserName, AccessKeyId, SecretAccessKey 
#You probably don't need to save/document these creds, but they are exported into a CSV in the directory where you execute the script just in case.
$deployment_creds | Export-Csv $deployment_identifier-keys.csv -NoTypeInformation
$credentials_key= ($deployment_creds).AccessKeyId
$credentials_secret=($deployment_creds).SecretAccessKey
$vr_yaml_template = get-content .\s3-upload-full-config.yaml
$vr_yaml_template.Replace('CREDENTIALSKEY',$credentials_key).Replace('CREDENTIALSSECRET',$credentials_secret).Replace('CUSTOMERDIR',$deployment_identifier) | Out-File $deployment_identifier-vr_template.yaml
#You will need to change "your-staged-collector" to reflect the name of your staged collector
.\your-staged-collector-s3-upload-v0.7.0-4-windows-amd64.exe config repack $deployment_identifier-vr_template.yaml $deployment_identifier-s3-upload-collector-v0704-Win-x64.exe
