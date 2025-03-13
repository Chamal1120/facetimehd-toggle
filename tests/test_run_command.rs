use facetimehd_toggle::run_command;

#[test]
fn test_run_command_success() {
    let result = run_command("echo", &["Hello", "Rust"]);
    assert!(result.is_ok(), "Command should succeed");

    let child = result.unwrap();
    let output = child.wait_with_output().unwrap();
    assert!(output.status.success(), "Command should exit successfully");
}

#[test]
fn test_run_command_failure() {
    let result = run_command("nonexistentcommand", &[]);
    assert!(result.is_err(), "Nonexistent command should fail");
}
