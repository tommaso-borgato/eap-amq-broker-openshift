mkdir ssh
cd ssh

# Generate a self-signed certificate for the broker keystore: server-keystore.jks
keytool -genkey -noprompt -alias server -keyalg RSA \
-keysize 2048 -validity 3650 -keystore server-keystore.jks \
-dname "CN=Tom Ross, OU=GSS, O=Red Hat, L=Reading, ST=Berks, C=UK" \
-keypass secret -storepass secret
# Export the certificate, so that it can be shared with clients: server-keystore.jks --> server-certificate
keytool -export -noprompt -alias server -file server-certificate -keystore server-keystore.jks -storepass secret
# Generate a self-signed certificate for the client keystore: client-keystore.jks
keytool -genkey -noprompt -alias client -keyalg RSA \
-keysize 2048 -validity 3650 -keystore client-keystore.jks \
-dname "CN=Tom Ross, OU=GSS, O=Red Hat, L=Reading, ST=Berks, C=UK" \
-keypass secret -storepass secret
# Create a client truststore that imports the broker certificate: server-certificate --> client-keystore.jks
keytool -import -noprompt -alias server -file server-certificate -keystore client-keystore.jks -storepass secret

