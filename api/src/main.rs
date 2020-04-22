mod config;
mod handlers;
mod schema;
mod user;

use actix_rt;
use actix_web::{
    guard, http::ContentEncoding, middleware::Compress, middleware::DefaultHeaders, web, App,
    HttpServer,
};
use config::Config;
use handlers::{graphiql_handler, graphql_handler, health_check_handler, not_found_handler};
use schema::create_schema;
use std::io;
use std::sync::Arc;

#[actix_rt::main]
async fn main() -> io::Result<()> {
    let cfg = Config::from_env().expect("failed to read env vars");
    let host_port = format!("127.0.0.1:{}", cfg.port);
    let graphql_schema = Arc::new(create_schema());

    // TODO: replace with proper logging
    println!("starting server on {}", host_port);

    HttpServer::new(move || {
        // GUARDS block requests that don't have the right HTTP verb or content-type
        let get_or_post_only = guard::Any(guard::Get()).or(guard::Post());
        let json_only = guard::Header("Content-Type", "application/json");

        // ROUTES map HTTP verbs to handlers and apply guards
        let health_check_route = web::route().to(health_check_handler);
        let graphql_route = web::route()
            .guard(get_or_post_only)
            .guard(json_only)
            .to(graphql_handler);
        let graphiql_route = web::get().to(graphiql_handler);
        let not_found_route = web::to(not_found_handler);

        // `X-Content-Type-Options: nosniff` prevents the browser from sniffing
        // the content type of the response away from what the server has
        // specified. This prevents certain attacks.
        let default_headers = DefaultHeaders::new()
            .content_type()
            .header("X-Content-Type-Options", "nosniff");

        App::new()
            // TODO: db client
            // TODO: async LogEntry logger middleware
            // TODO: auth0 for authentication
            // TODO: rate limiter middleware (https://docs.rs/actix-ratelimit/0.2.1/actix_ratelimit/)
            // TODO: middleware enforces max content-length of 256 KB
            // TODO: pprof middleware server (https://pingcap.com/blog/quickly-find-rust-program-bottlenecks-online-using-a-go-tool/)
            .data(graphql_schema.clone())
            .wrap(Compress::new(ContentEncoding::Br))
            .wrap(default_headers)
            .default_service(not_found_route)
            .route("/", health_check_route)
            .route("/graphql", graphql_route)
            .route("/graphiql", graphiql_route)
    })
    .bind(host_port)?
    .run()
    .await
}
