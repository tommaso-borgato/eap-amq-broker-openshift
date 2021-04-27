export ROUTE=$(oc get route amq-broker-all-0-svc-rte -o template --template '{{ .spec.host}}')
echo "[INFO] Usign Route ${ROUTE} to connect EAP to AMQ"

cat << EOF > extensions.cli
embed-server --std-out=echo  --server-config=standalone-openshift.xml
batch
/system-property=artemis.host:add(value=$ROUTE)
/system-property=artemis.port:add(value=443)
/system-property=artemis.user:add(value=admin)
/system-property=artemis.password:add(value=admin)
/socket-binding-group=standard-sockets/remote-destination-outbound-socket-binding=artemis-external-broker:add(host=\${artemis.host},port=\${artemis.port})
/subsystem=naming/binding="java:global/remote":add(binding-type=external-context,class=javax.naming.InitialContext,environment={java.naming.factory.initial => org.apache.activemq.artemis.jndi.ActiveMQInitialContextFactory,java.naming.provider.url => "tcp://\${artemis.host}:\${artemis.port}",connectionFactory.ConnectionFactory => "tcp://\${artemis.host}:\${artemis.port}",queue.testQueue => testQueue,queue.outQueue => outQueue, queue.inQueue => inQueue},module=org.apache.activemq.artemis)
/subsystem=naming/binding="java:/jms/amq/queue/testQueue":add(binding-type=lookup,lookup="java:global/remote/testQueue")
/subsystem=naming/binding="java:/jms/amq/queue/outQueue":add(binding-type=lookup,lookup="java:global/remote/outQueue")
/subsystem=naming/binding="java:/jms/amq/queue/inQueue":add(binding-type=lookup,lookup="java:global/remote/inQueue")
/subsystem=messaging-activemq/remote-connector=netty-remote-broker-ssl:add(params={ssl-enabled => true,trustStorePath => "/etc/secrets/client.ts",trustStorePassword => secret},socket-binding=artemis-external-broker)
/subsystem=messaging-activemq/pooled-connection-factory=activemq-ra-remote:add(connectors=[netty-remote-broker-ssl],entries=["java:/RemoteJmsXA","java:jboss/RemoteJmsXA","java:jboss/DefaultJMSConnectionFactory"],ha=false,max-pool-size=30,min-pool-size=15,password=\${artemis.password},statistics-enabled=true,transaction=xa,use-auto-recovery=false,user=\${artemis.user},jndi-params="java.naming.factory.initial=org.apache.activemq.artemis.jndi.ActiveMQInitialContextFactory;java.naming.provider.url=tcp://\${artemis.host}:\${artemis.port};java.naming.security.principal=\${artemis.user};java.naming.security.credentials=\${artemis.password}",rebalance-connections=true,setup-attempts=-1,setup-interval=5000,use-jndi=false,allow-local-transactions=true)
/subsystem=ee:write-attribute(name=jboss-descriptor-property-replacement,value=true)
/subsystem=ee:write-attribute(name=annotation-property-replacement,value=true)
/subsystem=ee:write-attribute(name=spec-descriptor-property-replacement,value=true)
/subsystem=ejb3:write-attribute(name=default-resource-adapter-name, value=activemq-ra-remote)
/subsystem=ee/service=default-bindings:write-attribute(name=jms-connection-factory, value=java:jboss/DefaultJMSConnectionFactory)
run-batch
quit
EOF