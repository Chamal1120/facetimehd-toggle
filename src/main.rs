use gtk::prelude::*;
use gtk::glib;
use libappindicator::{AppIndicator, AppIndicatorStatus};
use facetimehd_toggle::run_command;
use std::fs;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Mutex};

const STATE_FILE: &str = "/tmp/facetimehd_state";

fn read_camera_state() -> bool {
    if let Ok(modules) = fs::read_to_string("/proc/modules") {
        return modules.contains("facetimehd");
    }
    fs::read_to_string(STATE_FILE)
        .map(|s| s.trim() == "enabled")
        .unwrap_or(false)
}

fn write_camera_state(enabled: bool) {
    let state = if enabled { "enabled" } else { "disabled" };
    let _ = fs::write(STATE_FILE, state);
}

fn get_icon_name(enabled: bool) -> &'static str {
    if enabled {
        "camera-on"
    } else {
        "camera-off"
    }
}

fn main() {
    gtk::init().expect("Failed to initialize GTK.");

    let initial_state = read_camera_state();
    write_camera_state(initial_state);

    let current_state = Arc::new(AtomicBool::new(initial_state));
    let indicator = Arc::new(Mutex::new(
        AppIndicator::new("facetimehd_toggle", get_icon_name(initial_state)),
    ));
    indicator.lock().unwrap().set_status(AppIndicatorStatus::Active);

    // Create the menu
    let mut menu = gtk::Menu::new();

    // Enable Camera item
    let enable_item = gtk::MenuItem::with_label("Enable FaceTimeHD");
    enable_item.connect_activate(|_| {
        match run_command("pkexec", &["modprobe", "facetimehd"]) {
            Ok(_) => {
                write_camera_state(true);
                println!("Camera enabled - icon will update shortly");
            }
            Err(e) => eprintln!("Failed to enable camera: {}", e),
        }
    });
    menu.append(&enable_item);

    // Disable Camera item
    let disable_item = gtk::MenuItem::with_label("Disable FaceTimeHD");
    disable_item.connect_activate(|_| {
        match run_command("pkexec", &["modprobe", "-r", "facetimehd"]) {
            Ok(_) => {
                write_camera_state(false);
                println!("Camera disabled - icon will update shortly");
            }
            Err(e) => eprintln!("Failed to disable camera: {}", e),
        }
    });
    menu.append(&disable_item);

    // Status item
    let status_item = gtk::MenuItem::with_label(&format!(
        "Status: {}",
        if initial_state { "Enabled" } else { "Disabled" }
    ));
    status_item.set_sensitive(false);
    menu.append(&status_item);
    let status_item_clone = status_item.clone();

    // Quit item
    let quit_item = gtk::MenuItem::with_label("Quit");
    quit_item.connect_activate(|_| {
        let _ = fs::remove_file(STATE_FILE);
        gtk::main_quit();
    });
    menu.append(&quit_item);

    menu.show_all();
    indicator.lock().unwrap().set_menu(&mut menu);

    // Set up periodic state checking
    let current_state_clone = current_state.clone();
    let indicator_clone = indicator.clone();

    glib::timeout_add_seconds_local(2, move || {
        let new_state = read_camera_state();
        let old_state = current_state_clone.load(Ordering::Relaxed);

        if new_state != old_state {
            current_state_clone.store(new_state, Ordering::Relaxed);
            println!("State changed: {}", if new_state { "enabled" } else { "disabled" });

            if let Ok(mut ind) = indicator_clone.lock() {
                ind.set_icon_full(get_icon_name(new_state), "Camera");
            }

            // Update status text
            status_item_clone.set_label(&format!(
                "Status: {}",
                if new_state { "Enabled" } else { "Disabled" }
            ));
        }

        true.into()
    });

    gtk::main();
}

