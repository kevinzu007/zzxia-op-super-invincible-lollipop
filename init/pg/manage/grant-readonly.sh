#!/bin/bash


while read DB
do
    echo "----- ${DB} -----"
/usr/local/pgsql/bin/psql << EOF
    \c ${DB}
    grant select on all tables    in schema public to ff83df9995bc56df ;
    grant select on all sequences in schema public to ff83df9995bc56df ;
    alter default privileges in schema public grant select ON tables    TO ff83df9995bc56df ;
    alter default privileges in schema public grant select ON sequences TO ff83df9995bc56df ;
    \q
EOF
done < ./pg_db.list


