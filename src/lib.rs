use std::process::{Command, Child};

// Run the terminal commands
pub fn run_command(program: &str, args: &[&str]) -> Result<Child, std::io::Error> {
    Command::new(program)
        .args(args)
        .spawn()
}
