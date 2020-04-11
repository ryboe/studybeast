//! TODO

use juniper::{GraphQLInputObject, GraphQLObject};
use std::str::FromStr;
use uuid::Uuid;

#[derive(Clone, Debug, GraphQLObject)]
pub struct User {
    /// The user's UUIDv4 as a string.
    pub id: Uuid,
    /// The user's email.
    pub email: String,
}

impl User {
    pub fn new(email: String) -> Self {
        User {
            id: Uuid::new_v4(),
            email,
        }
    }
}

#[derive(Clone, Debug, GraphQLInputObject)]
pub struct UserInput {
    /// The user's email address.
    pub email: String,
}

pub fn get_users() -> Vec<User> {
    vec![
        User {
            id: Uuid::from_str("bf1c130b-9e35-45c6-9609-41d00e0f4bc8").unwrap(),
            email: "eat@my.balls".to_string(),
        },
        User {
            id: Uuid::from_str("6b3f1f48-a91d-40d4-8742-e578d5abee1d").unwrap(),
            email: "shit@cock.balls".to_string(),
        },
    ]
}
