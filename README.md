# TLDR

copy `build-elista.sh` into your applications' bin folder

copy `elista.env.example` into your applications config folder, edit values to fit your setup and rename to `elista.env`

run `./bin/build-elista.sh` in your application to create the elista script

run `./bin/elista.sh` to deploy

# Pre-requisites

Rails

Rbenv

Postgres

Nginx with Passenger enabled on your server

# Info

On first run, Elista deploys your application, sets up your database user, creates and migrates your database, and configures nginx so your application is available on your specified URL.


`./bin/build-elista.sh` creates two files, `./bin/elista.sh`, and `./config/nginx/*.conf`. It also edits our credentials file in production mode, where we can add our production db password

### credentials.yml.enc

On running the script, you will be prompted to edit this file, add the following

```
production:
    db_password: yourpasswordhere
```

### elista.sh

You can now run `./bin/elista.sh` based on your specific setup to deploy

### nginx.conf

The nginx conf file is uploaded to your nginx directory as part of the elista process

### TODO

1) Install letsencrypt so applications available on 443

2) Switch ruby version on web server where necessary, and install if not available
