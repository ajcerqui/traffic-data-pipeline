FROM jrembold/web2db

# These values will be overridden in Railway
ENV TABLE_NAME=raw_traffic_json
ENV SCRIPT_URL=placeholder
ENV DB_CONNECTION_STRING=placeholder
ENV CRON_SCHEDULE="0 */4 * * *"

