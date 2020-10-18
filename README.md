# TLDR

copy `bin/build-elista.sh` into bin folder

copy `config/elista.env.example` into config folder, edit values to fit your setup and rename to `config/elista.env`

run `./bin/build-elista.sh` to create elista script

run `./bin/elista.sh` to deploy

# Pre-requisites

Rails

Rbenv

Postgres

Nginx with Passenger enabled

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

TODO If you want to run locally

### Conventions

Directory name should be same as repo name, for now