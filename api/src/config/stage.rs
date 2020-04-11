use std::fmt;

#[derive(Debug, PartialEq, Eq)]
pub enum Stage {
    Development,
    IntegrationTesting,
    Staging,
    Production,
}

impl fmt::Display for Stage {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        let s = match self {
            Stage::Development => "development",
            Stage::IntegrationTesting => "integration-testing",
            Stage::Staging => "staging",
            Stage::Production => "production",
        };
        f.write_str(s)
    }
}

impl From<String> for Stage {
    fn from(s: String) -> Self {
        Self::from(s.as_str())
    }
}

impl From<&str> for Stage {
    fn from(s: &str) -> Self {
        match s {
            "development" => Stage::Development,
            "integration-testing" => Stage::IntegrationTesting,
            "staging" => Stage::Staging,
            "production" => Stage::Production,
            _ => panic!("unknown development stage '{}'", s),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn stage_is_correct_after_conversion_to_string_and_back() {
        let stages = [
            Stage::Development,
            Stage::IntegrationTesting,
            Stage::Staging,
            Stage::Production,
        ];

        for orig_stage in stages.iter() {
            let new_stage = Stage::from(format!("{}", orig_stage));
            assert_eq!(new_stage, *orig_stage);
        }
    }
}
