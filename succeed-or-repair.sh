#!/bin/sh
if ! flyway migrate -configFiles="/project/config/app/flyway.conf"; then
    echo "==================================================="
    echo "===== Migration failed, attempting repair now ====="
    echo "==================================================="
    flyway repair -configFiles="/project/config/app/flyway.conf"
    exit 1
fi

exit 0
