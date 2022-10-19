DAYSBACK=90 #DAYS TO LOOK BACK FOR ACTIVITY
PROJECT=devoteam-gc #CHANGE TO YOUR DESIRED BIGQUERY PROJECT
DATE=$(date  --date="$DAYSBACK days ago" +"%Y-%m-%d")
echo $DATE



echo removing old files..
rm -r datasetPermissions
rm -r tablePermissions
rm -r informationSchemas

mkdir datasetPermissions
mkdir tablePermissions
mkdir informationSchemas

rm result.csv
echo USER,DATASET,TABLE>result.csv






echo pulling information schemas...

bq query --format=prettyjson --nouse_legacy_sql \
'SELECT
  user_email,
  referenced_tables,
  query
FROM
  `region-us`.INFORMATION_SCHEMA.JOBS
  where date(creation_time) > "'$DATE'"
' >informationSchemas/jobsByUserEU.json




#  --AND job_type="QUERY




bq ls --format=prettyjson --project_id $PROJECT > datasets.json

echo pulling iam settings.. ignore jq: errors

for DATASET in $(jq -r '.[] | .datasetReference.datasetId' datasets.json)
do
    bq show --format=prettyjson devoteam-gc:$DATASET > datasetPermissions/$DATASET-Permissions.json
    DSUSERS=$(jq -r '.access | keys[] as $k | "\($k), \(.[$k] | .userByEmail)"' datasetPermissions/$DATASET-Permissions.json)
    for DSUSER in $DSUSERS
    do
        if [[ "$DSUSER" == *"@"* ]]; then
        echo $DSUSER, $DATASET, DATASET LEVEL>>result.csv
        fi
    done

    TABLES=$(bq ls "$PROJECT:$DATASET" | awk '{print $1}' | tail +3)
    for TABLE in $TABLES
    do
        bq get-iam-policy $PROJECT:$DATASET.$TABLE > tablePermissions/$DATASET-$TABLE.json
        USERS=$(jq -r '.bindings | keys[] as $k | "\($k), \(.[$k] | .members)"' tablePermissions/$DATASET-$TABLE.json)
        for USER in $USERS
        do
            if [[ "$USER" == *"@"* ]]; then
                echo ${USER//,/ },$DATASET,$TABLE>>result.csv
            fi
        done #USERS DONE
        rm tablePermissions/$DATASET-$TABLE.json
    done #TABLE DONE
    rm datasetPermissions/$DATASET-Permissions.json
done #DATASET DONE
rm datasets.json

echo analysing inactive users
python3 analyse.py
sed -i '1d' inactiveDatasetAccounts.csv
sed -i '1d' inactiveTableAccounts.csv