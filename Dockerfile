FROM scalingo/scalingo-18

ADD . buildpack

ADD .env /env/.env
RUN buildpack/bin/env.sh /env/.env /env
RUN buildpack/bin/compile /build /cache /env
RUN rm -rf /app/mattermost
RUN cp -rf /build/mattermost /app/mattermost

HEALTHCHECK CMD curl --fail http://localhost:8065 || exit 1

EXPOSE 8065

ENTRYPOINT [ "/app/mattermost/bin/mattermost" ]