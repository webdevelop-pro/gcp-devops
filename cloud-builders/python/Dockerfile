FROM python:3.7-slim

RUN set -ex \
    && savedAptMark="$(apt-mark showmanual)" \
    && apt-get update && apt-get install -y --no-install-recommends git gcc g++ && rm -rf /var/lib/apt/lists/* \
    && pip install aiodns==2.0.0 \
    aiohttp==3.5.4 \
    aiohttp-boilerplate==0.1.1 \
    aioresponses==0.6.0 \
    appnope==0.1.0 \
    asn1crypto==0.24.0 \
    astroid==2.2.5 \
    markupsafe==2.0.1 \
    async-lru==1.0.2 \
    async-timeout==3.0.1 \
    asyncpg==0.18.3 \
    atomicwrites==1.3.0 \
    attrs==19.1.0 \
    backcall==0.1.0 \
    cchardet==2.1.4 \
    certifi==2019.6.16 \
    cffi==1.12.3 \
    chardet==3.0.4 \
    Click==7.0 \
    click-log==0.3.2 \
    coverage==4.5.3 \
    coverage-badge==1.0.1 \
    cryptography==2.7 \
    Cython==0.29.12 \
    decorator==4.4.0 \
    docopt==0.6.2 \
    docusign-esign==1.0.3 \
    dwollav2==1.3.0 \
    entrypoints==0.3 \
    flake8==3.7.8 \
    freezegun==0.3.12 \
    future==0.17.1 \
    idna==2.8 \
    idna-ssl==1.1.0 \
    importlib-metadata==0.18 \
    ipython==6.5.0 \
    ipython-genutils==0.2.0 \
    isort==4.3.21 \
    jedi==0.14.1 \
    jwcrypto==0.6.0 \
    lazy-object-proxy==1.4.1 \
    marshmallow==2.19.5 \
    mccabe==0.6.1 \
    mock==3.0.5 \
    more-itertools==7.2.0 \
    multidict==4.5.2 \
    munch==2.3.2 \
    num2words==0.5.10 \
    packaging==19.0 \
    parso==0.5.1 \
    pbr==5.4.1 \
    pexpect==4.7.0 \
    pickleshare==0.7.5 \
    pluggy==0.12.0 \
    prompt-toolkit==1.0.16 \
    ptyprocess==0.6.0 \
    py==1.8.0 \
    py-oauth2==0.0.10 \
    pycares==3.0.0 \
    pycodestyle==2.5.0 \
    pycparser==2.19 \
    pyflakes==2.1.1 \
    Pygments==2.4.2 \
    PyJWT==1.7.1 \
    pylint==2.3.1 \
    pyparsing==2.4.0 \
    pyre-check==0.0.29 \
    pytest==5.0.1 \
    pytest-aiohttp==0.3.0 \
    pytest-cov==2.7.1 \
    pytest-mock==1.10.4 \
    pytest-sugar==0.9.2 \
    pytest-timeout==1.3.3 \
    python-dateutil==2.8.0 \
    pywatchman==1.4.1 \
    requests==2.22.0 \
    simplegeneric==0.8.1 \
    six==1.12.0 \
    SQLAlchemy==1.3.6 \
    termcolor==1.1.0 \
    traitlets==4.3.2 \
    typed-ast==1.4.0 \
    ujson==1.35 \
    urllib3==1.25.3 \
    uvloop==0.12.2 \
    wcwidth==0.1.7 \
    wrapt==1.11.2 \
    xxhash==1.3.0 \
    yarl==1.3.0 \
    zipp==0.5.2 \
    bandit \
    && apt-mark auto '.*' > /dev/null \
    && apt-mark manual $savedAptMark \
    && find /usr/local -type f -executable -not \( -name '*tkinter*' \) -exec ldd '{}' ';' \
    | awk '/=>/ { print $(NF-1) }' \
    | sort -u \
    | xargs -r dpkg-query --search \
    | cut -d: -f1 \
    | sort -u \
    | xargs -r apt-mark manual \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    \
    && find /usr/local -depth \
    \( \
    \( -type d -a \( -name test -o -name tests \) \) \
    -o \
    \( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
    \) -exec rm -rf '{}' + \
    && rm -rf /root/.cache
RUN apt-get update && apt-get install -y --no-install-recommends make git gcc && rm -rf /var/lib/apt/lists/*
CMD ["python3"]
