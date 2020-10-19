# TLDR

copy `build-elista.sh` into your applications' bin folder

copy `elista.env.example` into your applications config folder, edit values to fit your setup and rename to `elista.env`

run `./bin/build-elista.sh` in your applications to create the elista script

run `./bin/elista.sh` to deploy

# Pre-requisites

Rails

Rbenv

Postgres

Nginx with Passenger enabled on your server

# Info

`./bin/create.sh` creates three files, `./bin/elista.local.sh`, `./bin/elista.sh`, and `./config/nginx/*.conf`. It also edits our credentials file in production mode, where we can add our production db password

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

### elista.local.sh

If you want to run production locally with nginx TODO