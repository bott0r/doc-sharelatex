#!/bin/bash
export PATH=$PATH:/opt/texbin

# create data paths
mkdir -p /data/db
mkdir -p /data/user_files
mkdir -p /data/compiles
mkdir -p /data/cache
mkdir -p /data/tmp
mkdir -p /data/tmp/uploads
mkdir -p /data/tmp/dumpFolder
mkdir -p /data/logs/

mkdir -p /var/lib/sharelatex/data
chown www-data:www-data /var/lib/sharelatex/data

mkdir -p /var/lib/sharelatex/data/user_files
chown www-data:www-data /var/lib/sharelatex/data/user_files

mkdir -p /var/lib/sharelatex/data/compiles
chown www-data:www-data /var/lib/sharelatex/data/compiles

mkdir -p /var/lib/sharelatex/data/cache
chown www-data:www-data /var/lib/sharelatex/data/cache

mkdir -p /var/lib/sharelatex/data/template_files
chown www-data:www-data /var/lib/sharelatex/data/template_files

mkdir -p /var/lib/sharelatex/tmp/dumpFolder
chown www-data:www-data /var/lib/sharelatex/tmp/dumpFolder

mkdir -p /var/lib/sharelatex/tmp
chown www-data:www-data /var/lib/sharelatex/tmp

mkdir -p /var/lib/sharelatex/tmp/uploads
chown www-data:www-data /var/lib/sharelatex/tmp/uploads

mkdir -p /var/lib/sharelatex/tmp/dumpFolder
chown www-data:www-data /var/lib/sharelatex/tmp/dumpFolder

chown www-data:www-data /var/www/

if [ ! -e "/var/lib/sharelatex/data/db.sqlite" ]; then
       touch /var/lib/sharelatex/data/db.sqlite
fi

chown www-data:www-data /var/lib/sharelatex/data/db.sqlite

mongod &
redis-server &

# Waiting for mongodb to startup
until nc -z localhost 27017
do
    sleep 1
done

# replace CRYPTO_RANDOM in settings file
CRYPTO_RANDOM=$(dd if=/dev/urandom bs=1 count=32 2>/dev/null | base64 -w 0 | rev | cut -b 2- | rev | tr -d '\n+/'); \
sed -i "0,/CRYPTO_RANDOM/s/CRYPTO_RANDOM/$CRYPTO_RANDOM/" /etc/sharelatex/settings.coffee &
CRYPTO_RANDOM=$(dd if=/dev/urandom bs=1 count=32 2>/dev/null | base64 -w 0 | rev | cut -b 2- | rev | tr -d '\n+/'); \
sed -i "0,/CRYPTO_RANDOM/s/CRYPTO_RANDOM/$CRYPTO_RANDOM/" /etc/sharelatex/settings.coffee &

# start sharelatex with logging to files
SHARELATEX_CONFIG=/etc/sharelatex/settings.coffee node /sharelatex/chat/app.js >> /data/logs/chat.log 2>&1 &
SHARELATEX_CONFIG=/etc/sharelatex/settings.coffee node /sharelatex/clsi/app.js >> /data/logs/clsi.log 2>&1 &
SHARELATEX_CONFIG=/etc/sharelatex/settings.coffee node /sharelatex/docstore/app.js >> /data/logs/docstore.log 2>&1 &
SHARELATEX_CONFIG=/etc/sharelatex/settings.coffee node /sharelatex/document-updater/app.js >> /data/logs/document-updater.log 2>&1 &
SHARELATEX_CONFIG=/etc/sharelatex/settings.coffee node /sharelatex/filestore/app.js >> /data/logs/filestore.log 2>&1 &
SHARELATEX_CONFIG=/etc/sharelatex/settings.coffee node /sharelatex/real-time/app.js >> /data/logs/real-time.log 2>&1 &
SHARELATEX_CONFIG=/etc/sharelatex/settings.coffee node /sharelatex/spelling/app.js >> /data/logs/spelling.log 2>&1 &
SHARELATEX_CONFIG=/etc/sharelatex/settings.coffee node /sharelatex/tags/app.js >> /data/logs/tags.log 2>&1 &
SHARELATEX_CONFIG=/etc/sharelatex/settings.coffee node /sharelatex/track-changes/app.js >> /data/logs/track-changes.log 2>&1 &
SHARELATEX_CONFIG=/etc/sharelatex/settings.coffee node /sharelatex/web/app.js >> /data/logs/web.log 2>&1


#echo "Checking can connect to mongo and redis"
#cd /var/www/sharelatex && grunt check:redis
#cd /var/www/sharelatex && grunt check:mongo
#echo "All checks passed"


cd /sharelatex && grunt migrate -v
