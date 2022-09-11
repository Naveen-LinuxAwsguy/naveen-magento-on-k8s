#!/bin/bash

sleep 2

#### INITIALIZING ####

files=(/var/www/html/magento/*)
if [ ${#files[@]} -lt 10 ]; then 
    echo "[INFO] Copying all Source Files to ${APP_HOME}";
	cp -r $TMP_APP_HOME/. $APP_HOME/.
    echo "[INFO] All app files copied to ${APP_HOME}";
else
	echo "[INFO] ${APP_HOME} is not empty. Updating only /app /var & /pub directory with latest code";
    cp $TMP_APP_HOME/*.* $APP_HOME/.
    cp -r ${TMP_APP_HOME}/app $APP_HOME/
    cp -r $TMP_APP_HOME/var $APP_HOME/
    cp -r $TMP_APP_HOME/pub $APP_HOME/

    cp -r $TMP_APP_HOME/bin $APP_HOME/
    cp -r $TMP_APP_HOME/lib $APP_HOME/
    cp -r $TMP_APP_HOME/phpserver $APP_HOME/
    cp -r $TMP_APP_HOME/setup $APP_HOME/

    echo "[INFO] Source Files updated";
fi

echo
echo
echo "[INFO] Initialization completed.";

sleep 1

# Always chown webroot for better mounting
chown -Rf nginx:nginx $APP_HOME/
chmod -R 777 $APP_HOME/

# Start supervisord and services
/usr/local/bin/supervisord -n -c /etc/supervisord.conf