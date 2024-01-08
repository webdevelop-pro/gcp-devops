FROM python:3.12-alpine3.19@sha256:ae1f508f01ac1806e84c68b43ee0983b586426dfa39f5d21eced0dd7f5e230f4 as build
ENV PYTHONUNBUFFERED 1

RUN apk add --no-cache --virtual .build-deps \
  build-base ca-certificates linux-headers musl-dev \
  libffi-dev python3-dev openssl-dev openssh-client \
  git gcc

WORKDIR /usr/local/app/
RUN python -m venv /usr/local/app/venv
ENV PATH="/usr/local/app/venv/bin:$PATH"
RUN pip install https://github.com/webdeveloppro/aiohttp_boilerplate/archive/refs/tags/v0.5.4.zip

# in case if we want to install latest
# RUN RUN pip install https://github.com/webdeveloppro/aiohttp_boilerplate/archive/refs/tags/$(curl -s https://api.github.com/repos/webdeveloppro/aiohttp_boilerplate/releases/latest | grep tag_name | grep -Eo '"([^ _]*)"' | tr -d '"').zip

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
