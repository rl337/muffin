FROM alpine:latest

RUN apk add --no-cache docker make gettext ansible rsync openssh bash

WORKDIR /

ENTRYPOINT ["make"]