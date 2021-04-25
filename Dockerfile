FROM scalingo/scalingo-18

ADD . buildpack

ADD .env /env/.env
RUN buildpack/bin/env.sh /env/.env /env
RUN buildpack/bin/compile /build /cache /env
RUN rm -rf /app/mattermost
RUN cp -rf /build/mattermost /app/mattermost

EXPOSE ${PORT}

ENTRYPOINT [ "/app/mattermost/bin/run" ]