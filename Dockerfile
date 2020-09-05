FROM golang:buster
LABEL maintainer="Andrew Cooper<me@andrewcooper.me>"

ENV JOBBER_VER v1.3.1
ENV SRC_HASH 8d8cdeb941710e168f8f63abbfc06aab2aadfdfc22b3f6de7108f56403860476

RUN apt-get update && apt-get install -y make rsync grep ca-certificates openssl wget

WORKDIR /go_wkspc/src/github.com/dshearer
RUN wget "https://api.github.com/repos/dshearer/jobber/tarball/${JOBBER_VER}" -O jobber.tar.gz && \
    echo "${SRC_HASH}  jobber.tar.gz" | sha256sum -cw && \
    tar xzf *.tar.gz && rm *.tar.gz && mv dshearer-* jobber && \
    cd jobber && \
    make check && \
    make install DESTDIR=/jobber-dist/

FROM python:3.7-buster

RUN mkdir -p /tmp/wheel \
&&  pip3 install \
    gphotos-sync

RUN mkdir /jobber
COPY --from=0 /jobber-dist/usr/local/libexec/jobberrunner /usr/local/libexec/jobberrunner
COPY --from=0 /jobber-dist/usr/local/bin/jobber /usr/local/bin/jobber

RUN addgroup jobberuser && \
    adduser --system --ingroup jobberuser jobberuser && \
    mkdir -p "/var/jobber/$(id -u jobberuser)" && \
    chown -R jobberuser:jobberuser "/var/jobber/$(id -u jobberuser)"

COPY jobfile /home/jobberuser/.jobber
RUN chown jobberuser:jobberuser /home/jobberuser/.jobber && \
    chmod 0600 /home/jobberuser/.jobber

RUN mkdir -p /home/jobberuser/.config /gphotos-config
RUN ln -s /gphotos-config /home/jobberuser/.config/gphotos-sync
VOLUME /gphotos-config

RUN mkdir /gphotos-storage
VOLUME /gphotos-storage

USER jobberuser
ENTRYPOINT ["jobberrunner"]
CMD ["/home/jobberuser/.jobber"]
