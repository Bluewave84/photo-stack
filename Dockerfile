FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    bash \
    enfuse \
    hugin-tools \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /photos
COPY stack-images.sh /usr/local/bin/stack-images
RUN sed -i 's/\r$//' /usr/local/bin/stack-images \
    && chmod +x /usr/local/bin/stack-images
ENTRYPOINT ["/bin/bash", "/usr/local/bin/stack-images"]
