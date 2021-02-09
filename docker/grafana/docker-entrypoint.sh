#!/bin/sh

mkdir -p /var/lib/grafana/dashboards
cp -a /etc/grafana/dashboards/* /var/lib/grafana/dashboards/
/run.sh
