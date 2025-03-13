use gtk::prelude::*;
use libappindicator::{AppIndicator, AppIndicatorStatus};
use facetimehd_toggle::run_command;

fn main() {
    // Initialize GTK
    gtk::init().expect("Failed to initialize GTK.");

    // Create the AppIndicator (tray icon)
    let mut indicator = AppIndicator::new("facetimehd_toggle", "camera-video-symbolic");
    indicator.set_status(AppIndicatorStatus::Active);

    // Create the menu
    let mut menu = gtk::Menu::new();

    // Enable Camera item
    let enable_item = gtk::MenuItem::with_label("Enable facetimehd");
    enable_item.connect_activate(|_| {
        run_command("pkexec", &["modprobe", "facetimehd"]).expect("failed to enable facetimehd");
    });
    menu.append(&enable_item);

    // Disable Camera item
    let disable_item = gtk::MenuItem::with_label("Disable facetimehd");
    disable_item.connect_activate(|_| {
        run_command("pkexec", &["modprobe", "-r", "facetimehd"]).expect("failed disable facetimehd");
    });
    menu.append(&disable_item);

    // Quit item
    let quit_item = gtk::MenuItem::with_label("Quit");
    quit_item.connect_activate(|_| {
        gtk::main_quit();
    });
    menu.append(&quit_item);

    // Show the menu
    menu.show_all();
    indicator.set_menu(&mut menu);

    // Start the GTK main loop
    gtk::main();
}

