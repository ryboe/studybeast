# This is for production only. We do not run the API in a container for local
# development.
FROM rust:slim-buster AS builder
WORKDIR /usr/src/api
COPY . .
RUN cargo build --release

# We dynamically link these C libraries.
#   linux-vdso.so.1
#   libdl.so.2
#   librt.so.1
#   libpthread.so.0
#   libgcc_s.so.1
#   libc.so.6
#   libm.so.6
#   /lib64/ld-linux-x86-64.so.2
# Because we need to dynamically link libgcc_s, we need to use the distroless/cc
# container, which has libgcc installed. The smaller distroless base images
# won't work.
FROM gcr.io/distroless/cc
LABEL maintainer "ryan@studybeast.com"
ENV STAGE "production"
COPY --from=builder /usr/src/api/target/release/studybeast-api /
EXPOSE 8080
CMD ["/studybeast-api"]
