#!/usr/bin/env bash
set -x
echo "Setup EAP with remote AMQ Broker"
$JBOSS_HOME/bin/jboss-cli.sh --file=$JBOSS_HOME/extensions/extensions.cli
