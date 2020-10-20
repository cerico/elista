set -x
source config/elista.env
mkdir -p config/nginx
echo config/elista.env >> .gitignore
cp config/database.yml config/database.yml.bk
mv config/credentials.yml.enc config/credentials.yml.enc.bkup.$(date +'%s')
rm config/master.key
RAILS_ENV=production EDITOR=vim rails credentials:edit
echo "  password: <%= Rails.application.credentials.production[:db_password] %>" >> config/database.yml
git add config/credentials.yml.enc config/database.yml .gitignore
git commit -m "Credentials and Database updated by Elista"
git push origin $branch
cat <<EOTF > config/nginx/$app_name.conf
server {
  listen 80;
  listen [::]:80;

  server_name $url;
  root $remote_app_location/$app_name/public;

  passenger_enabled on;
  passenger_app_env production;
  passenger_friendly_error_pages on;
  passenger_ruby ${remote_rbenv}/shims/ruby;

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
    if [ -d ${remote_rbenv}/versions/`cat .ruby-version` ]
      then
      rbenv local `cat .ruby-version`
    else
      rbenv install `cat .ruby-version`
      rbenv local `cat .ruby-version`
    fi
    RAILS_ENV=production
    bundle config set without 'development test'
    bundle update
    RAILS_ENV=production bundle install
    yarn install --check-files
    ./bin/webpack
    RAILS_ENV=production bundle exec rake db:migrate
  else
    git clone $repo $app_name
    cd $app_name
    if [ -d ${remote_rbenv}/versions/`cat .ruby-version` ]
      then
      rbenv local `cat .ruby-version`
    else 
      rbenv install `cat .ruby-version`
      rbenv local `cat .ruby-version`
    fi
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
  RAILS_ENV=production
  bundle config set without 'development test'  
  bundle install
  spring stop
  yarn install --check-files
  ls bin
  ./bin/webpack
  RAILS_ENV=production bundle exec rake db:create
  RAILS_ENV=production bundle exec rake db:migrate
  RAILS_ENV=production bundle exec rake db:seed
  RAILS_ENV=production bundle exec rails assets:precompile
  sudo service nginx reload
EOF
 echo "Done!"
EOTF
chmod a+x ./bin/elista.sh
