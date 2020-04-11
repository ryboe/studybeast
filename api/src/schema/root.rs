//! TODO

use crate::schema::{Mutation, Query};
use juniper::{EmptySubscription, RootNode};

// pub struct Context;

pub type Schema = RootNode<'static, Query, Mutation, EmptySubscription<()>>;

pub fn create_schema() -> Schema {
    Schema::new(Query, Mutation, EmptySubscription::new())
}
