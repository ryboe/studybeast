//! TODO

use chrono;
use log::{Level, Log, Metadata, Record};
use std::io;

pub struct LogEntryLogger {
    name: String,
    severity: Level,
    dest: io::Writer,
}

impl LogEntryLogger {
    pub fn new(name: &str) -> Self {
        LogEntryLogger {
            name: name.to_string(),
            severity: Level::Info,
            dest: io::stdout(),
        }
    }

    pub fn name(&mut self, name: &str) -> Self {
        self.name = name.to_string();
        self
    }

    pub fn severity(&mut self, severity: Level) -> Self {
        self.severity = severity;
        self
    }

    pub fn destination(&mut self, dest: io::Write) -> Self {
        self.dest = dest;
        self
    }
}

impl Log for LogEntryLogger {
    fn enabled(&self, metadata: Metadata) -> bool {
        metadata.level <= self.severity
    }

    fn log(&self, record: &Record) {
        if !self.enabled(record.metadata()) {
            return;
        }

        let json_record = json!({ "" });
    }
}
