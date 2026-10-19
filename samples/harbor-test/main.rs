#[cfg(target_os = "windows")]
fn main() {
    use std::iter::once;
    use std::os::windows::ffi::OsStrExt;
    use std::ffi::OsStr;
    use std::ptr::null_mut;

    #[link(name = "user32")]
    unsafe extern "system" {
        fn MessageBoxW(hwnd: *mut std::ffi::c_void, text: *const u16, title: *const u16, kind: u32) -> i32;
    }

    fn wide(s: &str) -> Vec<u16> {
        OsStr::new(s).encode_wide().chain(once(0)).collect()
    }
    let title = wide("Harbor Test - Game Dock");
    let body = wide("Success! Game Dock started a standalone Windows executable.\n\nThis is a launcher integration test, not a game.");
    unsafe { MessageBoxW(null_mut(), body.as_ptr(), title.as_ptr(), 0x40); }
}

#[cfg(not(target_os = "windows"))]
fn main() {
    println!("Harbor Test is intended for Windows.");
}
