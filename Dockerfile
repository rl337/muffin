FROM alpine:latest

RUN apk add --no-cache docker make gettext ansible rsync

WORKDIR /

ENTRYPOINT ["make"]