# add cf command to provision cloudant with name cloudant-mqtt-watson and upload document
# cf create-service
#
bx target -s dev

cd MqttWatsonEventProvider/ && cf push
# ./install.sh openwhisk.ng.bluemix.net $(bx wsk property get --auth | awk '{print $3'}) "bx wsk"
# ./uninstall.sh openwhisk.ng.bluemix.net $(wsk property get --auth | awk '{print $3'}) "wsk" https://mqtt-watson-supraliminal-reinterview.mybluemix.net/mqtt-watson
cd ..
provider_url=$(cf routes | grep mqtt-watson | head -n 1 | awk '{print $2"."$3}')
./install.sh openwhisk.ng.bluemix.net $(wsk property get --auth | awk '{print $3'}) "wsk" ${provider_url}

echo "parse these logs to see if the feed is able to connect to MQTT broker"
cf logs ${provider_url} --recent

wsk trigger delete subscription-event-trigger
wsk trigger create subscription-event-trigger \
  --feed mqtt-watson/feed-action \
  --param topic "iot-2/type/${IOT_DEVICE_TYPE}/id/${IOT_DEVICE_ID}/evt/msgin/fmt/json" \
  --param url "${IOT_ORG}.messaging.internetofthings.ibmcloud.com:1883" \
  --param username "${IOT_API_KEY}" \
  --param password "${IOT_AUTH_TOKEN}" \
  --param client "a:${IOT_ORG}:wskmqttsub"
