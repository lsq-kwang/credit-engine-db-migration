FROM flyway/flyway:8.4.1-alpine

WORKDIR /project

COPY migration/sql sql

COPY succeed-or-repair.sh succeed-or-repair.sh

ENTRYPOINT ["./succeed-or-repair.sh"]
