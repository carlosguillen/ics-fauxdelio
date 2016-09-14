FROM marcelmaatkamp/alpine-base

# add packages
RUN apk update && apk upgrade && \
    apk add make && \
    apk add perl-net-ssleay && \
    apk add perl-libwww perl-io-tty perl-data-uuid

# install perl modules needed to run the server
RUN curl -L https://cpanmin.us | perl - App::cpanminus
RUN cpanm --notest REST::Client Data::Faker POE Const::Fast

RUN mkdir -p /opt/fauxdelio
ADD fauxdelio.pl /opt/fauxdelio/fauxdelio.pl

RUN rm /var/cache/apk/*
RUN rm -rf /root/.cpanm/*
