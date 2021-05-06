# mattermost-buildpack

> This buildpack aims at installing a [Mattermost](https://mattermost.com) instance on [Scalingo](https://www.scalingo.com) and let you configure it at your convenance.

## Usage

Simply deploy by cliking on this button:

[![Deploy to Scalingo](https://cdn.scalingo.com/deploy/button.svg)](https://my.scalingo.com/deploy?source=https://github.com/MTES-MCT/mattermost-scalingo#main)

Or create an app. You must have an add-on database `postgresql` or `mysql`.
[Add this buildpack environment variable][1] to your Scalingo application to install the `Mattermost` server:

```shell
BUILDPACK_URL=https://github.com/MTES-MCT/mattermost-buildpack#main
```

And other environment variables are set by example in a `.env.sample` file.

`PORT` and `SCALINGO_POSTGRESQL_URL` are provided by Scalingo.

Addon configuration by default:

```shell
MM_SQLSETTINGS_DRIVERNAME=postgres # if required replace by mysql
MM_SQLSETTINGS_DATASOURCE=$SCALINGO_POSTGRESQL_URL # SCALINGO_POSTGRESQL_URL is provided by scalingo at app boot step
```

Warning ⚠️: you should copy the database url in `MM_SQLSETTINGS_DATASOURCE` and change `sslmode` if `prefer` is unknown by mattermost.

By default the buildpack install the latest release enterprise edition:

```shell
MATTERMOST_EDITION= # enterprise by default, set team if you prefer
MATTERMOST_VERSION=latest # latest release by default, you can change with specific version
```

All other environment variables are specific to mattermost, see [documentation](https://docs.mattermost.com/administration/config-settings.html#environment-variables).

You can also persist your config in each build and deploy:

```shell
MM_CONFIG=$SCALINGO_POSTGRESQL_URL # persists config in database
```

You can list plugins to install at build:

```shell
## From marketplace set ids
MATTERMOST_MARKETPLACE_PLUGINS=com.github.matterpoll.matterpoll,memes
## From Github set owner/repo
MATTERMOST_GITHUB_PLUGINS=blindsidenetworks/mattermost-plugin-bigbluebutton,scottleedavis/mattermost-plugin-remind
```

## Hacking

You set environment variables in `.env`:

```shell
cp .env.sample .env
```

Run an interactive docker scalingo stack:

```shell
docker run --name mattermost -it -p 8065:8065 -v "$(pwd)"/.env:/env/.env -v "$(pwd)":/buildpack scalingo/scalingo-18:latest bash
```

And test in it:

```shell
bash buildpack/bin/detect
bash buildpack/bin/env.sh /env/.env /env
bash buildpack/bin/compile /build /cache /env
bash buildpack/bin/release
```

Run Mattermost server:

```shell
export PATH=$PATH:/build/mattermost/bin
mattermost server
```

You can also use docker-compose in order to test with a complete stack (db, s3, smtp):

```shell
docker-compose up --build -d
```

You can test postdeploy (install plugins list):

```shell
bash /app/mattermost/bin/postdeploy
```

`.env.sample` is configured to work with this stack. You just need to create the bucket `mattermost` in minio.

[1]: https://doc.scalingo.com/platform/deployment/buildpacks/custom
