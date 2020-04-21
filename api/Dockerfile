# This is for production only. We do not run the API in a container for local
# development.
FROM rust:alpine AS builder
WORKDIR /usr/src/api
COPY . .
RUN cargo build --release

FROM alpine
COPY --from=builder /usr/src/api/target/release/studybeast-api /usr/local/bin/studybeast-api
CMD ["studybeast-api"]
