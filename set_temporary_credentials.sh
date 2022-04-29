#!/bin/bash
# USAGE:
# source set_temporary_credentials.sh Role MFAcode [Duration]
# source set_temporary_credentials.sh poweruser 123456 3600
# NOTE:
# Duration in seconds (900 - 43200) (15min to 12 hours), default=3600
ROLE=$1
CODE=$2
DURATION="${3:-3600}"
NAME=`aws sts get-caller-identity | jq -r ".Arn" | cut -d/ -f2`
#echo "$NAME $ROLE $CODE $DURATION"

# Poweruser role requires MFA
case $ROLE in
  admin|poweruser|readonly|tacowrite)
    aws sts get-session-token \
     --serial-number "arn:aws:iam::118211588532:mfa/$NAME" \
     --token-code $2 > /tmp/creds.txt

    export AWS_ACCESS_KEY_ID="$(cat /tmp/creds.txt | jq -r ".Credentials.AccessKeyId")"
    export AWS_SECRET_ACCESS_KEY="$(cat /tmp/creds.txt | jq -r ".Credentials.SecretAccessKey")"
    export AWS_SESSION_TOKEN="$(cat /tmp/creds.txt | jq -r ".Credentials.SessionToken")" ;;
esac

aws sts assume-role \
 --role-arn "arn:aws:iam::118211588532:role/$1" \
 --duration-seconds "$DURATION" \
 --role-session-name "$NAME" > /tmp/creds.txt

export AWS_ACCESS_KEY_ID="$(cat /tmp/creds.txt | jq -r ".Credentials.AccessKeyId")"
export AWS_SECRET_ACCESS_KEY="$(cat /tmp/creds.txt | jq -r ".Credentials.SecretAccessKey")"
export AWS_SESSION_TOKEN="$(cat /tmp/creds.txt | jq -r ".Credentials.SessionToken")"

aws sts get-caller-identity

EXPIRATION="$(cat /tmp/creds.txt | jq -r ".Credentials.Expiration")"
echo "Temporary credentials set. Expiration = $EXPIRATION"

echo "To return to previous identity:"
echo "unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN"

rm /tmp/creds.txt
