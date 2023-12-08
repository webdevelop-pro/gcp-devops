FROM python:3.11.7-alpine3.18@sha256:5e6a1b5f58efba3b2bd4affdce2a5075832c986fa6ccfad32c3998b8c91a3ca0 as build
ENV PYTHONUNBUFFERED 1

RUN apk add --no-cache --virtual .build-deps \
  build-base ca-certificates linux-headers musl-dev \
  libffi-dev python3-dev openssl-dev openssh-client \
  git gcc

WORKDIR /usr/local/app/aiohttp_boilerplate.git

RUN python -m venv /usr/local/app/venv
ENV PATH="/usr/local/app/venv/bin:$PATH"
RUN git clone https://github.com/webdeveloppro/aiohttp_boilerplate.git /usr/local/app/aiohttp_boilerplate.git && \
  cd /usr/local/app/aiohttp_boilerplate.git && \
  git checkout -q 432d8578af6d933b92f79d95b8a532f59ddfa947 .
RUN pip install -r /usr/local/app/aiohttp_boilerplate.git/requirements.txt

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

ADD . /app
WORKDIR /app

# RUN ./build-deploy.sh build
COPY ./etc /app/etc
CMD ["/bin/sh"]
