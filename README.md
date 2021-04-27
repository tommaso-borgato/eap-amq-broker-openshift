# AMQ Broker - setup

- create-ssh.sh
- `oc create secret generic amq-broker-ssl-secret --from-file=broker.ks=./ssh/server-keystore.jks --from-file=client.ts=./ssh/client-keystore.jks --from-literal=keyStorePassword=secret --from-literal=trustStorePassword=secret`
- `oc apply -f operatorgroup.yaml`
- `oc apply -f subscription.yaml`
- `oc apply -f activemqartemis.yaml`
- `oc apply -f in-queue-address.yaml`
- `oc apply -f out-queue-address.yaml`
- `oc apply -f test-queue-address.yaml`

# EAP - setup

- `git clone git@github.com:tommaso-borgato/eap-amq-broker.git -b mdb-bug`
- `cd eap-amq-broker && mvn package`
- `oc secrets link builder <your secret to pull images from registry.redhat.io>`
- `oc new-build --name=eap-jms registry.redhat.io/jboss-eap-7/eap73-openjdk8-openshift-rhel7:latest --binary=true`
- `oc start-build eap-jms --from-file=target/ROOT.war --wait`
- `oc new-app eap-jms`
- `oc expose service/eap-jms`
- `oc set env deployment/eap-jms DISABLE_EMBEDDED_JMS_BROKER=true`
- `oc set volume deployment/eap-jms --add --name=amq-broker-ssl-secret -m /etc/secrets -t secret --secret-name=amq-broker-ssl-secret`
- extensions.sh
- `oc create configmap jboss-cli --from-file=postconfigure.sh=postconfigure.sh --from-file=extensions.cli=extensions.cli`
- `oc set volume deployment/eap-jms --add --name=jboss-cli -m /opt/eap/extensions -t configmap --configmap-name=jboss-cli --default-mode='0755' --overwrite`

# Reproduce

- `export EAP_ROUTE=$(oc get route eap-jms -o template --template '{{ .spec.host}}')`
- `curl ${EAP_ROUTE}/jms-test?request=send-request-message-for-mdb`: response is "Sent a text message with to ActiveMQQueue[inQueue]"
- `curl ${EAP_ROUTE}/jms-test?request=consume-reply-message-for-mdb`: response is "null message details: null"

# Compare

Using branch `main` in `eap-amq-broker` the behaviour is the correct one:

- `git checkout main`
- `oc start-build eap-jms --from-file=target/ROOT.war --wait`
- `curl ${EAP_ROUTE}/jms-test?request=send-request-message-for-mdb`: response is "Sent a text message with to ActiveMQQueue[inQueue]"
- `curl ${EAP_ROUTE}/jms-test?request=consume-reply-message-for-mdb`: response is like "Hello MDB - reply message! message details: ActiveMQMessage[ID:046cfa30-a75d-11eb-a940-0a580a8302fa]:PERSISTENT/ClientMessageImpl[messageID=2611, durable=true, address=outQueue,userID=046cfa30-a75d-11eb-a940-0a580a8302fa,properties=TypedProperties[inMessageId=ID:f851e0ed-a75b-11eb-b6ef-0a580a800572,__AMQ_CID=0465f54a-a75d-11eb-a940-0a580a8302fa,_AMQ_ROUTING_TYPE=1]]"