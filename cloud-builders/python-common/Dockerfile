FROM python:3.11.5-alpine3.18@sha256:738ac14925d69ff88103c028573de949286c8d5c81afb202954512aa6207bbc2 as build
ENV PYTHONUNBUFFERED 1

RUN apk add --no-cache --virtual .build-deps \
  build-base ca-certificates linux-headers musl-dev \
  libffi-dev python3-dev openssl-dev openssh-client \
  git gcc

WORKDIR /usr/local/app/aiohttp_boilerplate.git

RUN python -m venv /usr/local/app/venv
ENV PATH="/usr/local/app/venv/bin:$PATH"
RUN pip install aiohttp==3.8.5 asyncpg==0.28.0 marshmallow==2.21.0 PyJWT==2.4.0 ujson==5.8.0 uvloop==0.17.0 aiocache==0.11.1 python-json-logger==2.0.7 django_environ==0.10.0
RUN git clone https://github.com/webdeveloppro/aiohttp_boilerplate.git /usr/local/app/aiohttp_boilerplate.git && \
  cd /usr/local/app/aiohttp_boilerplate.git && \
  git checkout -q 2353213f09bec2513225fbd38102e7d6b651b5c3 .

RUN find /usr/local \
        \( -type d -a -name test -o -name tests \) \
        -o \( -type f -a -name '*.pyc' -o -name '*.pyo' \) \
        -exec rm -rf '{}' + \
    && runDeps="$( \
        scanelf --needed --nobanner --recursive /usr/local/app/local \
                | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
                | sort -u \
                | xargs -r apk info --installed \
                | sort -u \
    )" \
    && apk add --virtual .rundeps $runDeps \
    && apk del .build-deps
