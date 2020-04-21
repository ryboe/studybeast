//! TODO
use crate::schema::Schema;
use actix_web::http::Method;
use actix_web::{self, web, web::HttpRequest, HttpResponse, Responder};
use juniper::http::{graphiql::graphiql_source, GraphQLRequest};
use serde_json::{self, json};
use std::sync::Arc;

pub async fn health_check_handler(req: HttpRequest) -> impl Responder {
    let resp_body = if req.method() != Method::GET {
        let msg = format!("{} method not allowed", req.method().as_str());
        json!({"errors":[{"message":msg}]})
    } else {
        json!({"data":"up"})
    };

    HttpResponse::Ok().json(resp_body)
}

pub async fn not_found_handler() -> impl Responder {
    HttpResponse::Ok().json(json!({"errors":[{"message":"not found"}]}))
}

pub async fn graphql_handler(
    schema: web::Data<Arc<Schema>>,
    req: web::Json<GraphQLRequest>,
) -> Result<HttpResponse, actix_web::Error> {
    let graphql_resp = req.execute(&schema, &()).await;
    let body = serde_json::to_string(&graphql_resp).map_err(actix_web::Error::from)?;

    Ok(HttpResponse::Ok()
        .content_type("application/json")
        .body(body))
}

pub async fn graphiql_handler() -> impl Responder {
    let body = graphiql_source("/graphql", None);
    HttpResponse::Ok()
        .content_type("text/html; charset=UTF-8")
        .body(body)
}
