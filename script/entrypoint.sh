#!/usr/bin/env bash

echo "***********************Executing Entrypoint shell script****************************"
echo "************************************************************************************"
TRY_LOOP="30"



POSTGRES_HOST=${POSTGRES_HOST:-postgres}
POSTGRES_PORT=5432


export \
POSTGRES_HOST \
POSTGRES_PORT \


#cp /airflow.cfg ${AIRFLOW_HOME}/airflow.cfg
#chown -R airflow: ${AIRFLOW_HOME}

# Defaults and back-compat
: "${AIRFLOW__CORE__FERNET_KEY:=${FERNET_KEY:=$(python -c "from cryptography.fernet import Fernet; FERNET_KEY = Fernet.generate_key().decode(); print(FERNET_KEY)")}}"
: "${AIRFLOW__CORE__EXECUTOR:=${EXECUTOR:-Sequential}Executor}"



#Airflow Support to define Airflow configuration as Environment Variables
export \
 AIRFLOW__CORE__EXECUTOR \
 AIRFLOW__CORE__FERNET_KEY \
 AIRFLOW__CORE__LOAD_EXAMPLES \
 AIRFLOW__CORE__SQL_ALCHEMY_CONN \
 ENV_ID \
 KEY \
 PYTHONPATH \

# Load DAGs exemples (default: Yes)
if [[ -z "$AIRFLOW__CORE__LOAD_EXAMPLES" && "${LOAD_EX:=n}" == n ]]
then
 AIRFLOW__CORE__LOAD_EXAMPLES=False
fi





wait_for_port() {
 local name="$1" host="$2" port="$3"
 local j=0
 while ! nc -z "$host" "$port" >/dev/null 2>&1 < /dev/null; do
   j=$((j+1))
   if [ $j -ge $TRY_LOOP ]; then
     echo >&2 "$(date) - $host:$port still not reachable, giving up"
     exit 1
   fi
   echo "$name" "$host" "$port"
   echo "$(date) - waiting for $name... $j/$TRY_LOOP"
   sleep 5
 done
}

if [ "$AIRFLOW__CORE__EXECUTOR" != "SequentialExecutor" ]; then

wait_for_port "Postgresql" "$POSTGRES_HOST" "$POSTGRES_PORT"

fi



case "$1" in
 webserver)
   airflow initdb
   exec airflow webserver
   ;;
 worker)
    # To give the webserver time to run initdb.
    sleep 10
    exec airflow "$@"
    ;;
 scheduler)
    sleep 10
    (while :; do echo 'Serving logs';  airflow serve_logs; sleep 1; done) &
    (while :; do echo 'Starting scheduler';  airflow scheduler ; sleep 1; done)
    ;;

 flower)
   exec airflow "$@"
   ;;
 version)
   exec airflow "$@"
   ;;
 *)
   # The command is something like bash, not an airflow subcommand. Just run it in the right environment.
   exec "$@"
   ;;
esac