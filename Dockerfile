FROM ubuntu:focal
CMD ["/bin/bash"]
RUN /bin/sh -c apt-get update -qqy
RUN /bin/sh -c apt-get upgrade -qqy
RUN /bin/sh -c apt-get install dumb-init
RUN /bin/sh -c apt-get install -y libssl-dev libgomp1
ADD ./redis-stack /var/cache/apt/redis-stack/ # buildkit
RUN /bin/sh -c mkdir -p /data/redis /data/redisinsight
RUN /bin/sh -c touch /.dockerenv
RUN /bin/sh -c dpkg -i /var/cache/apt/redis-stack/redis-stack-server*.deb # buildkit
RUN /bin/sh -c rm -rf /var/cache/apt
COPY ./entrypoint.sh /entrypoint.sh 
RUN /bin/sh -c chmod a+x /entrypoint.sh
EXPOSE 6379
ENV REDISBLOOM_ARGS=
ENV REDISEARCH_ARGS=
ENV REDISJSON_ARGS=
ENV REDISTIMESERIES_ARGS=
ENV REDISGRAPH_ARGS=
ENV REDIS_ARGS=
CMD ["/entrypoint.sh"]
