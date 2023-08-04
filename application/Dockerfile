# Hello GrayLog
# This container runs the Graylog web app
#
ARG DOCKER_REGISTRY="docker.io/library"
FROM ${DOCKER_REGISTRY}/python:3.10-alpine3.16 as base

WORKDIR /app/hello-graylog

ADD src/ /app/hello-graylog/
ADD scripts/entrypoint.sh /
ADD src/ /app

RUN apk add --update --no-cache --virtual .tmp-build-deps \
    gcc libc-dev linux-headers postgresql-dev \
    && apk add libffi-dev

RUN pip install --upgrade pip 
RUN cd /app && pip install -r /app/requirements.txt

CMD /entrypoint.sh
