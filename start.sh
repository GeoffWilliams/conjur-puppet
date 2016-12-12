#!/bin/bash -ex

docker-compose build

docker-compose up -d conjur
docker-compose exec -T conjur /opt/conjur/evoke/bin/wait_for_conjur > /dev/null
echo Conjur is ready
echo Loading base policies
docker-compose exec -T conjur \
  conjur policy load --as-group security_admin /var/lib/possum-example/policy/conjur.yml

echo Loading policy extensions
docker-compose exec -T conjur \
  conjur policy load --as-group security_admin /var/puppet-policies/conjur.yml

echo Creating host factory token
docker-compose exec -T conjur \
  conjur hostfactory tokens create --duration-days 365 prod/inventory | tee inventory_token.json

password=$(openssl rand -hex 12)

echo Loading inventory-db password
docker-compose exec -T conjur \
  conjur variable values add prod/inventory-db/password $password

cat inventory_token.json | docker-compose run --rm jq -r ".[0].token" > inventory_token.txt

docker-compose exec -T conjur cat /opt/conjur/etc/ssl/ca.pem > conjur.pem

docker-compose up -d puppetdbpostgres puppetdb puppet puppetboard puppetexplorer