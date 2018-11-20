# Docker image for building a rpi img locally
# based upon
# https://vsupalov.com/build-docker-image-clone-private-repo-ssh-key/
# https://vsupalov.com/docker-arg-env-variable-guide/#setting-arg-values

FROM debian:stable as intermediate
RUN apt-get update && apt-get install -y git

# add credentials on build
ARG SSH_PRIVATE_KEY
RUN mkdir /root/.ssh/
RUN echo "${SSH_PRIVATE_KEY}" > /root/.ssh/id_rsa
RUN chmod 600 /root/.ssh/id_rsa

# make sure your domain is accepted
RUN touch /root/.ssh/known_hosts
RUN ssh-keyscan  github.com >> /root/.ssh/known_hosts

RUN git clone https://github.com/TheSin-/rpi-img-builder.git

FROM debian:stable
COPY --from=intermediate /rpi-img-builder /opt/rpi-img-builder
RUN apt-get update && apt-get install -y build-essential wget git lzop u-boot-tools binfmt-support qemu qemu-user-static multistrap parted dosfstools

CMD echo "Built docker image."

