#!/usr/bin/env bash

leader=$(mysql -sN <<EOF
  USE kubecf;
  insert ignore into db_leader_election ( anchor, host, last_seen_active )
    values ( 1, '${HOSTNAME}', now() ) on duplicate key update host = if(last_seen_active < now() - interval 60 second,
    values(host), host), last_seen_active = if(host = values(host), values(last_seen_active), last_seen_active);
    select host from db_leader_election;
EOF
)

[ "${leader}" == "${HOSTNAME}" ]
