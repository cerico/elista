set -x
source config/elista.env
mkdir -p config/nginx
echo config/elista.env >> .gitignore
cp config/database.yml config/database.yml.bk
rm config/credentials.yml.enc
rm config/master.key
RAILS_ENV=production EDITOR=vim rails credentials:edit
git add config/credentials.yml.enc config/database.yml .gitignore
git commit -m "creds"
git push origin main
cat <<EOTF > config/nginx/$app_name.conf
server {
  listen 80;
  listen [::]:80;

  server_name $url;
  root $remote_app_location/$app_name/public;

  passenger_enabled on;
  passenger_app_env production;
  passenger_friendly_error_pages on;
  passenger_ruby $remote_ruby_location;

  location /cable {
    passenger_app_group_name ${app_name}_websocket;
    passenger_force_max_concurrent_requests_per_process 0;
  }

  # Allow uploads up to 100MB in size
  client_max_body_size 100m;

  location ~ ^/(assets|packs) {
    expires max;
    gzip_static on;
  }
}
EOTF

cat <<EOTF > bin/elista.local.sh
source config/elista.env
echo "  password: <%= Rails.application.credentials.production[:db_password] %>" >> config/database.yml
password=\`echo 'Rails.application.credentials.production[:db_password]' | RAILS_ENV=production bundle exec rails c | tail -2 | head -1 | tr -d '"'\`
psql -c "CREATE user $app_name PASSWORD '\$password' createdb";
RAILS_ENV=production ./bin/rake db:create
RAILS_ENV=production ./bin/rake db:migrate
RAILS_ENV=production ./bin/rake db:seed
RAILS_ENV=production rails assets:precompile
cp -r config/nginx/* $local_nginx_location
brew services restart nginx
EOTF
chmod a+x bin/elista.local.sh
cat <<EOTF > bin/elista.sh
source config/elista.env

ssh $user@$server -i $key << EOF
  cd $remote_app_location
  echo $app_name
  bash -i
  if [ -d $app_name ]
  then
    echo "hello"
    cd $app_name
    git pull origin $branch
    which ruby
    rbenv versions
    rbenv local 2.6.5
    bundle update
    bundle install
    RAILS_ENV=production bundle exec rake db:migrate
  else
    git clone $repo
  fi
EOF
ssh -q $user@$server -i $key  "[[ -f $remote_app_location/$app_name/config/master.key ]]"
retVal=$?
echo $retVal
if [ $retVal -eq 0 ]; then
  echo "Done!"
  exit
fi
ls
sftp -i $key $user@$server << EOF
  cd $remote_app_location/$app_name/config
  mput config/master.key
  cd $remote_nginx_location
  mput config/nginx/*
EOF
ssh $user@$server -i $key << EOF
  bash -i
  cd $remote_app_location/$app_name
  password=\`echo 'Rails.application.credentials.production[:db_password]' | RAILS_ENV=production bundle exec rails c | tail -2 | head -1 | tr -d '"'\`
  sudo -u postgres psql -c "CREATE user $app_name PASSWORD '\$password' createdb";
  bundle install
  RAILS_ENV=production ./bin/rake db:create
  RAILS_ENV=production ./bin/rake db:migrate
  RAILS_ENV=production ./bin/rake db:seed
  RAILS_ENV=production ./bin/rails assets:precompile
  sudo service nginx reload
EOF
 echo "Done!"
EOTF
chmod a+x ./bin/elista.sh
