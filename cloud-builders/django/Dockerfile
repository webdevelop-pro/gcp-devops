FROM python:3.12.0-alpine3.18 as build
ENV PYTHONUNBUFFERED 1

RUN apk add --no-cache --virtual .build-deps \
  build-base ca-certificates linux-headers musl-dev \
  libffi-dev python3-dev openssl-dev openssh-client \
  git gcc

WORKDIR /usr/local/app
RUN ln -s /usr/local/app /app

RUN python -m venv  /usr/local/app
COPY requirements.txt /usr/local/app/requirements.txt
ENV PATH="/usr/local/app/venv/bin:$PATH"
RUN pip install -r /usr/local/app/requirements.txt

RUN find /usr/local/app \
        \( -type d -a -name test -o -name tests \) \
        -o \( -type f -a -name '*.pyc' -o -name '*.pyo' \) \
        -exec rm -rf '{}' + \
    && runDeps="$( \
        scanelf --needed --nobanner --recursive /usr/local/app \
                | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
                | sort -u \
                | xargs -r apk info --installed \
                | sort -u \
    )" \
    && apk add --virtual .rundeps $runDeps \
    && apk del .build-deps

# RUN ./build-deploy.sh build
CMD ["/bin/sh"]
