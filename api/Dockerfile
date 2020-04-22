# This is for production only. We do not run the API in a container for local
# development.
FROM rust:slim-buster AS builder
WORKDIR /usr/src/api
COPY . .
RUN cargo build --release

FROM gcr.io/distroless/cc
ENV STAGE "production"
COPY --from=builder /usr/src/api/target/release/studybeast-api /
EXPOSE 8080
CMD ["/studybeast-api"]
