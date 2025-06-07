use clap::Parser;
use std::ffi::c_void;
use std::fs;
use std::ptr::null_mut;
#[repr(C)]
#[derive(Debug, Clone, Copy)]
pub struct BofObjectHandle {
    bits: u32,
}
#[derive(Parser)]
#[command(name = "bof_runner", about = "Run a BOF from a file")]
struct Args {
    bof_filename: String,
}

#[link(name = "lib/bof_launcher_win_x64", kind = "static")]
unsafe extern "C" {
    pub fn bofObjectInitFromMemory(
        file_data_ptr: *const u8,             // Matches `const unsigned char*`
        file_data_len: i32,                   // Matches `int`
        out_bof_handle: *mut BofObjectHandle, // Matches `BofObjectHandle*`, output can't be NULL
    ) -> i32;

    pub fn bofObjectRun(
        bof_handle: BofObjectHandle,
        arg_data_ptr: *const c_void,
        arg_data_len: i32,
        out_bof_handle: &mut *mut c_void,
    ) -> i32;

    pub fn bofObjectRelease(bof_handle: BofObjectHandle);
}
/// Basic bof runner without argument support
fn main() {
    println!("Hello from bof_runner, feel free to run your BOFS!");

    let args = Args::parse();

    println!("Running BOF: {}", args.bof_filename);

    let bof_data = match fs::read(&args.bof_filename) {
        Ok(data) => data,
        Err(e) => {
            eprintln!("Error reading BOF file: {}", e);
            std::process::exit(1);
        }
    };

    let mut bof_handle: BofObjectHandle = BofObjectHandle { bits: 0 };
    let mut bof_context: *mut c_void = null_mut();
    unsafe {
        let result =
            bofObjectInitFromMemory(bof_data.as_ptr(), bof_data.len() as i32, &mut bof_handle);
        dbg!(result);
    }

    dbg!(bof_handle.clone());

    unsafe {
        let _ = bofObjectRun(bof_handle, null_mut(), 0, &mut bof_context);
    }

    unsafe {
        bofObjectRelease(bof_handle);
    }
}
