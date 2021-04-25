#!/bin/bash
# usage: /app/mattermost/bin/run

export MM_SERVICESETTINGS_LISTENADDRESS=":${PORT}"

/app/mattermost/bin/mattermost