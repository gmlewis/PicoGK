use std::path::PathBuf;

fn main() {
    let manifest_dir = std::env::var("CARGO_MANIFEST_DIR").unwrap();
    let crate_dir = PathBuf::from(&manifest_dir);
    let native_dir = crate_dir.join("../../../../native");

    let (platform_dir, lib_name) = if cfg!(target_os = "macos") {
        if cfg!(target_arch = "aarch64") {
            ("osx-arm64", "picogk.26")
        } else {
            panic!("PicoGK 2.x native libraries are only distributed for macOS arm64");
        }
    } else if cfg!(target_os = "linux") {
        ("linux-x64", "picogk.26")
    } else {
        panic!("Unsupported platform for PicoGK FFI");
    };

    let lib_dir = native_dir.join(platform_dir);

    if lib_dir.exists() {
        if cfg!(target_os = "macos") {
            let out_dir = std::env::var("OUT_DIR").unwrap();
            let out_path = PathBuf::from(&out_dir);
            let link_target = lib_dir.join(format!("{}.dylib", lib_name));
            let link_name = out_path.join(format!("lib{}.dylib", lib_name));
            let _ = std::fs::remove_file(&link_name);
            let _ = std::os::unix::fs::symlink(&link_target, &link_name);
            println!("cargo:rustc-link-search=native={}", out_path.display());
        } else if cfg!(target_os = "linux") {
            // The new runtime is built without a "lib" prefix; the linker's
            // -l<name> expects lib<name>.so, so provide an alias in OUT_DIR.
            let out_dir = std::env::var("OUT_DIR").unwrap();
            let out_path = PathBuf::from(&out_dir);
            let link_target = lib_dir.join(format!("{}.so", lib_name));
            let link_name = out_path.join(format!("lib{}.so", lib_name));
            let _ = std::fs::remove_file(&link_name);
            let _ = std::os::unix::fs::symlink(&link_target, &link_name);
            println!("cargo:rustc-link-search=native={}", out_path.display());
        }
        println!("cargo:rustc-link-search=native={}", lib_dir.display());
        println!("cargo:rustc-link-lib=dylib={}", lib_name);
        // The generated gos_bindings cdylib does not inherit this link-arg;
        // build the binding with `sdk/gos/picogkffi/build.sh` (or set
        // RUSTFLAGS) so the wrapper gets the native rpath too.
        println!("cargo:rustc-link-arg=-Wl,-rpath,{}", lib_dir.display());
    } else if let Ok(custom) = std::env::var("PICOGK_LIB") {
        let custom_path = PathBuf::from(&custom);
        if custom_path.is_dir() {
            println!("cargo:rustc-link-search=native={}", custom_path.display());
        }
        println!("cargo:rustc-link-lib=dylib={}", lib_name);
        println!("cargo:rustc-link-arg=-Wl,-rpath,{}",
            if custom_path.is_dir() { custom_path.display().to_string() } else { custom });
    } else {
        panic!("PicoGK native library not found. Set PICOGK_LIB env var.");
    }

    if cfg!(target_os = "macos") {
        cc::Build::new()
            .file("viewer_dispatch.c")
            .compile("viewer_dispatch");
    }

    println!("cargo:rerun-if-env-changed=PICOGK_LIB");
    println!("cargo:rerun-if-changed=build.rs");
    println!("cargo:rerun-if-changed=viewer_dispatch.c");
}

