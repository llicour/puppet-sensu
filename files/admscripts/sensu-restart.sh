/sbin/service rabbitmq-server restart
sleep 5
/sbin/service sensu-server restart
/sbin/service sensu-api restart
/sbin/service sensu-client restart
/sbin/service sensu-dashboard restart

