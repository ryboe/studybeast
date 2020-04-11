use crate::user::{get_users, User};
use juniper::{self, FieldResult};

pub struct Query;

#[juniper::graphql_object]
impl Query {
    #[graphql(description = "List of all users.")]
    pub fn users() -> FieldResult<Vec<User>> {
        let users = get_users();
        Ok(users)
    }
}
