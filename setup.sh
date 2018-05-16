set -x
set -e
# add cf command to provision cloudant with name cloudant-mqtt-watson and upload document
# cf create-service
#
# bx target -s dev

cd MqttWatsonEventProvider/ && cf push
cd ..
sleep 5
export provider_url=$(cf apps | grep mqtt-watson | awk '{print $6}' | tr -d ',' | xargs echo -n )
# clean up
./uninstall.sh openwhisk.ng.bluemix.net $(wsk property get --auth | awk '{print $3'}) "wsk"
wsk trigger delete subscription-event-trigger
sleep 1
./install.sh openwhisk.ng.bluemix.net $(wsk property get --auth | awk '{print $3'}) "wsk" "http://${provider_url}/mqtt-watson"
sleep 1
echo "create trigger that'll be invoked each time a message is received at given topic"
# wsk trigger delete subscription-event-trigger
# wsk package delete mqtt-watson
wsk trigger create msgReceived \
  --feed mqtt-watson/feed-action \
  --param topic "iot-2/type/${IOT_DEVICE_TYPE}/id/${IOT_DEVICE_ID}/evt/msgin/fmt/json" \
  --param url "ssl://${IOT_ORG}.messaging.internetofthings.ibmcloud.com:8883" \
  --param username "${IOT_API_KEY}" \
  --param password "${IOT_AUTH_TOKEN}" \
  --param client "a:${IOT_ORG}:wskmqttsub_$(date +%s)"

wsk rule create handleClientMsg msgReceived translateText

echo "parse app logs to determine if the feed is able to connect to MQTT broker"
cf logs mqtt-watson --recent
