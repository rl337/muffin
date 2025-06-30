FROM alpine:latest

RUN apk add --no-cache docker make gettext ansible

WORKDIR /

ENTRYPOINT ["make"]