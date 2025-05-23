#!/bin/bash

# Hacky script to facilitate CLI access to CSDA Maxar data by creating a cookie file for curl / GDAL
# Data: https://search.earthdata.nasa.gov/search?q=CSDA

# USAGE:
# ./create_csda_cookie.sh CSDA_USERNAME CSDA_PASSWORD CSDA_MFACODE

# EXAMPLE:
# ./create_csda_cookie.sh scottyhq abcdefg 123456
#
# export URL=https://data.csdap.earthdata.nasa.gov/csdap-cumulus-prod-protected/WV03_Pan_L1B___1/2022/181/WV03_20220630192433_1040010078CB3400_22JUN30192433-P1BS-506564128070_01_P001/WV03_20220630192433_1040010078CB3400_22JUN30192433-P1BS-506564128070_01_P001-BROWSE.jpg
# curl -L -O -b /tmp/csda-cookie.txt "$URL"
# GDAL_DISABLE_READDIR_ON_OPEN=EMPTY_DIR GDAL_HTTP_COOKIEFILE=/tmp/csda-cookie.txt gdalinfo "/vsicurl/$URL"

# CLI INPUTES
# ---------------------------------
CSDA_USERNAME=$1
CSDA_PASSWORD=$2
CSDA_MFACODE=$3

# Start w/ clean cookie file
COOKIEFILE="/tmp/csda-cookie.txt"
rm $COOKIEFILE

# Set up Session
# ---------------------------------
BASEURL="https://data.csdap.earthdata.nasa.gov"
SUBFOLDER="/csdap-cumulus-prod-protected/"
IMAGE="WV02_Pan_L1B___1/2022/331/WV02_20221127142659_10300100DDD05E00_22NOV27142659-P1BS-507015111040_01_P010/WV02_20221127142659_10300100DDD05E00_22NOV27142659-P1BS-507015111040_01_P010-BROWSE.jpg"
TESTURL="${BASEURL}${SUBFOLDER}${IMAGE}"
echo 'Setting up CSDA Session...'
curl -L -b $COOKIEFILE -c $COOKIEFILE $TESTURL &> /dev/null
# Read Session Token
SESSION=`grep XSRF ${COOKIEFILE} | awk '{print $NF}'`

# User name and password login
# ---------------------------------
COGNITO_URL="https://auth-csdap.auth.us-west-2.amazoncognito.com"
CLIENT_ID="23m4hvqfej9sh1nsej0e772ejt"
echo 'Logging into AWS Cognito...'
curl -L -b $COOKIEFILE -c $COOKIEFILE \
  "${COGNITO_URL}/login?response_type=code&client_id=${CLIENT_ID}&redirect_uri=${BASEURL}/login&state=${SUBFOLDER}${IMAGE}" \
  --data-raw "_csrf=${SESSION}&username=${CSDA_USERNAME}&password=${CSDA_PASSWORD}" &> /dev/null

# Token changes...
SESSION=`grep XSRF ${COOKIEFILE} | awk '{print $NF}'`

# MFA Login
# ---------------------------------
echo 'Completing MFA...'
curl -L -b $COOKIEFILE -c $COOKIEFILE  \
  "${COGNITO_URL}/mfa?response_type=code&client_id=${CLIENT_ID}&redirect_uri=${BASEURL}/login&state=${SUBFOLDER}${IMAGE}" \
  --data-raw "_csrf=${SESSION}&authentication_code=${CSDA_MFACODE}&cognitoAsfData=" &> /dev/null

# Success?
echo "--------------------------------"
echo "Wrote cookie to ${COOKIEFILE} that expires in 24 hours"
echo "You can now use the cookie with curl or GDAL"
echo "Example:"
echo "export URL=${TESTURL}"
echo "curl -L -O -b ${COOKIEFILE} \"\$URL\""
echo "GDAL_DISABLE_READDIR_ON_OPEN=EMPTY_DIR GDAL_HTTP_COOKIEFILE=${COOKIEFILE} gdalinfo \"/vsicurl/\$URL\""
echo "--------------------------------"
