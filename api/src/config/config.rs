use crate::config::Stage;
use derivative::Derivative;
use dotenv;
use std::env;
use std::error::Error;
use std::path::Path;

#[derive(Derivative)]
#[derivative(Debug)]
pub struct Config {
    pub stage: Stage,
    pub port: u16,
    // db API creds
    // #[derivative(Debug="ignore")]
    // my_secret: String
}

impl Config {
    pub fn from_env() -> Result<Self, Box<dyn Error>> {
        // If this is development, we need to source all the env vars in
        // `development.env`. In prod, the env vars will already be set.
        let stage = Stage::from(env::var("STAGE")?);
        if stage == Stage::Development {
            let project_root = Path::new(env!("CARGO_MANIFEST_DIR")).parent().unwrap();
            let env_file_path = project_root.join("development.env");
            let _ = dotenv::from_path(env_file_path)?;
        }

        let port: u16 = env::var("PORT")?.parse()?;

        let cfg = Config { stage, port };
        Ok(cfg)
    }
}

// TODO
// pub fn init_logger(stage: Stage) {
//     match stage {
//         Stage::Development | Stage::IntegrationTesting => {

//         },
//         Stage::Production | Stage::Staging => {

//         },
//     }
// }
