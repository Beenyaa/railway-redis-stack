FROM ubuntu:focal

RUN apt-get update -qqy
RUN apt-get upgrade -qqy
RUN apt-get install dumb-init
RUN apt-get install -y libssl-dev libgomp1
ADD ./redis-stack /var/cache/apt/redis-stack/
RUN mkdir -p /data/redis
RUN touch /.dockerenv

RUN dpkg -i /var/cache/apt/redis-stack/redis-stack-server*.deb

RUN rm -rf /var/cache/apt

COPY ./etc/scripts/entrypoint.sh /entrypoint.sh
RUN chmod a+x /entrypoint.sh

EXPOSE 6379

ENV REDISBLOOM_ARGS ""
ENV REDISEARCH_ARGS ""
ENV REDISJSON_ARGS ""
ENV REDISTIMESERIES_ARGS ""
ENV REDISGRAPH_ARGS ""
ENV REDIS_ARGS ""

CMD ["/entrypoint.sh"]
