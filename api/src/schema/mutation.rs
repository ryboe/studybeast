use crate::user::{User, UserInput};
use juniper::{self, FieldResult};

pub struct Mutation;

#[juniper::graphql_object]
impl Mutation {
    // pub fn new_user(user_input: UserInput) -> FieldResult<User> {
    //     // TODO: store user in some kind of data store
    //     Ok(User::new(user_input.email))
    // }
}
