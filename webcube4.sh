#!/bin/bash

# __author__ = "Alberto Pettarin"
# __copyright__ = "Copyright 2017, Alberto Pettarin (www.albertopettarin.it)"
# __license__ = "MIT"
# __version__ = "1.0.0"
# __email__ = "alberto@albertopettarin.it"
# __status__ = "Production"



##############################################################################
#
# COMMON FUNCTIONS
#
##############################################################################

usage() {
  echo ""
  echo "Usage:"
  echo "  $ sh $0 connect [--debug]"
  echo "  $ sh $0 disconnect [--debug]"
  echo ""
  echo "Notes:"
  echo "  1. you need curl and node to be installed and in your PATH"
  echo "  2. put your router admin password in ~/.webcube4, e.g. by running:"
  echo "     $ echo \"yourpass\" > ~/.webcube4 && chmod 400 ~/.webcube4"
  echo ""
}

printdebug() {
  if [ "$1" -eq 1 ]
  then
    echo "[DEBU] $2"
  fi
}

printwarning() {
  echo "[WARN] $1"
}

printerror() {
  echo "[ERRO] $1"
}

##############################################################################
#
# CONSTANTS
#
##############################################################################

CONF_PATH="$HOME/.conf/webcube4"

PASSWORD_FILE="$CONF_PATH/password"
OLD_PASSWORD_FILE="$HOME/.webcube4"

WEB_ROOT="192.168.1.1"
WEB_ROOT_FILE="$CONF_PATH/webroot"

API_USER="admin"
API_USER_FILE="$CONF_PATH/user"

CURL_EXEC="curl"
NODE_EXEC="node"
NODE_COMPUTE_JS="compute.js"

CONNECT="connect"
DISCONNECT="disconnect"

PAGE_INDEX_STUB="/html/index.html"
API_LOGIN_STUB="/api/user/login"
API_DIAL_STUB="/api/dialup/dial"

HEADER="/tmp/webcube4.header"
PAGE="/tmp/webcube4.page"
DATA="/tmp/webcube4.data"
HEADER2="/tmp/webcube4.header2"
PAGE2="/tmp/webcube4.page2"
DATA2="/tmp/webcube4.data2"
HEADER3="/tmp/webcube4.header3"
PAGE3="/tmp/webcube4.page3"



##############################################################################
#
# VARIABLES
#
##############################################################################

COMMAND=""
DEBUG=0



##############################################################################
#
# MAIN SCRIPT
#
##############################################################################

# remove tmp files, if already existing
rm -f "$HEADER" "$PAGE" "$DATA" "$HEADER2" "$PAGE2" "$DATA2" "$HEADER3" "$PAGE3"

# check if curl is available
$CURL_EXEC --version > /dev/null 2> /dev/null
if [ "$?" != 0 ]
then
  printerror "Cannot run '$CURL_EXEC'. Make sure it is installed. Aborting."
  exit 1
fi

# check if node is available
$NODE_EXEC --version > /dev/null 2> /dev/null
if [ "$?" != 0 ]
then
  printerror "Cannot run '$NODE_EXEC'. Make sure it is installed. Aborting."
  exit 1
fi

# check that we have at least one argument
if [ "$#" -lt 1 ]
then
  usage
  exit 1
fi

# check that the first command is either "connect" or "disconnect"
COMMAND="$1"
if [ "$COMMAND" != "$CONNECT" ] && [ "$COMMAND" != "$DISCONNECT" ]
then
  printerror "Unknown command '$COMMAND'"
  usage
  exit 1
fi

# check if we must print debug info
if [ "$#" -ge 2 ] && [ "$2" == "--debug" ]
then
  DEBUG=1
fi

if [ ! -d "$CONF_PATH" ]
then
  printwarning "Creating missing config path '$CONF_PATH'."
fi

if [ -e "$OLD_PASSWORD_FILE" ]
then
  printwarning "Moving old password file '$OLD_PASSWORD_FILE' to '$PASSWORD_FILE'."
fi

# read wifi password
if [ ! -e "$PASSWORD_FILE" ]
then
  printerror "Unable to read file '$PASSWORD_FILE'"
  usage
  exit 1
fi
PASSWORD=`cat "$PASSWORD_FILE"`
#printdebug "$DEBUG" "Password: '$WIFI_PASSWORD'"

# read api user
if [ -e "$API_USER_FILE" ]
then
  API_USER=`cat "$API_USER_FILE"`
  printdebug "$DEBUG" "API User set: $API_USER"
fi

# read web root
if [ -e "$WEB_ROOT_FILE" ]
then
  WEB_ROOT=`cat "$WEB_ROOT_FILE"`
  printdebug "$DEBUG" "Web root set: $WEB_ROOT"
fi

# set urls
PAGE_INDEX="http://$WEB_ROOT/html/index.html"
API_LOGIN="http://$WEB_ROOT/api/user/login"
API_DIAL="http://$WEB_ROOT/api/dialup/dial"

# get index page and save header
echo -n "[INFO] Getting index... "
curl \
  -D "$HEADER" \
  "$PAGE_INDEX" > "$PAGE" 2> /dev/null
echo "done"

# get cookie
COOKIE=`grep "Set-Cookie" "$HEADER" | cut -d ":" -f 2 | cut -d ";" -f 1`
printdebug "$DEBUG" "Cookie: '$COOKIE'"

# get tokens (the first one is not used)
CSRF_TOKEN_1=`grep "csrf_token" "$PAGE" | cut -d "\"" -f 4 | head -n1`
CSRF_TOKEN_2=`grep "csrf_token" "$PAGE" | cut -d "\"" -f 4 | tail -n1`
printdebug "$DEBUG" "Token 1: '$CSRF_TOKEN_1'"
printdebug "$DEBUG" "Token 2: '$CSRF_TOKEN_2'"

# get password by running the JS
LOGIN_PASSWORD=`node "$NODE_COMPUTE_JS" "$API_USER" "$PASSWORD" "$CSRF_TOKEN_2"`
printdebug "$DEBUG" "Password: '$LOGIN_PASSWORD'"

# put request data into file
echo -n "[INFO] Logging in... "
echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?><request><Username>$API_USER</Username><Password>$LOGIN_PASSWORD</Password><password_type>4</password_type></request>" > "$DATA"

# post request
curl \
  -X POST \
  --cookie "$COOKIE" \
  -d "@$DATA" \
  -H "__RequestVerificationToken: $CSRF_TOKEN_2" \
  -D "$HEADER2" \
  "$API_LOGIN" > "$PAGE2" 2> /dev/null
echo "done"

# check result
IS_OK=`grep "OK" "$PAGE2" | wc -l`
if [ "$IS_OK" != "1" ]
then
  printerror "Failure, something went wrong."
  exit 1
fi

# get request verification token
RV_TOKEN_ALL=`grep "__RequestVerificationToken:" "$HEADER2"`
COOKIE2=`grep "Set-Cookie" "$HEADER2" | cut -d ":" -f 2 | cut -d ";" -f 1`
printdebug "$DEBUG" "Cookie: '$COOKIE2'"

# set the appropriate info message and request parameters
MESSAGE=""
RV_TOKEN_INDEX=-1
if [ "$COMMAND" == "$CONNECT" ]
then
  MESSAGE="Connecting... "
  RV_TOKEN_INDEX=4
  REQ_ACTION=1
fi
if [ "$COMMAND" == "$DISCONNECT" ]
then
  MESSAGE="Disconnecting... "
  RV_TOKEN_INDEX=14
  REQ_ACTION=0
fi

# get request verification token
RV_TOKEN=`echo "$RV_TOKEN_ALL" | cut -d "#" -f "$RV_TOKEN_INDEX"`
printdebug "$DEBUG" "RV Token: '$RV_TOKEN'"

# put request data into file and post it
echo -n "[INFO] $MESSAGE"
echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?><request><Action>$REQ_ACTION</Action></request>" > "$DATA2"
curl \
  -X POST \
  --cookie "$COOKIE2" \
  -d "@$DATA2" \
  -H "__RequestVerificationToken: $RV_TOKEN" \
  -D "$HEADER3" \
  "$API_DIAL" > "$PAGE3" 2> /dev/null
echo "done"

# check result
IS_OK=`grep "OK" "$PAGE3" | wc -l`
if [ "$IS_OK" != "1" ]
then
  printerror "Failure, something went wrong."
  exit 1
fi

# success and exit
echo "[INFO] Success!"

# remove tmp files, if already existing
rm -f "$HEADER" "$PAGE" "$DATA" "$HEADER2" "$PAGE2" "$DATA2" "$HEADER3" "$PAGE3"

exit 0
