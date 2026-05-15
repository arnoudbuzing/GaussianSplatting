use std::ffi::CStr;
use std::os::raw::{c_char, c_int, c_void};

use wgpu_3dgs_core::PlyGaussians;

// ── LibraryLink ABI types ────────────────────────────────────────────────────
// These mirror the minimal subset of WolframLibrary.h that we need.

#[allow(non_camel_case_types)]
type mint = i64; // 64-bit kernel integer on modern Wolfram

#[allow(non_camel_case_types)]
type errcode_t = c_int;

/// The `MArgument` union from WolframLibrary.h.
/// In C it is `union { mbool *boolean; mint *integer; mreal *real;
///                      char **utf8string; … }`.
/// We only need the `integer` and `utf8string` arms here.
#[repr(C)]
#[derive(Copy, Clone)]
union MArgument {
    boolean: *mut c_int,
    integer: *mut mint,
    real:    *mut f64,
    utf8str: *mut *mut c_char,
    // Other arms (tensor, image, …) omitted – same pointer width.
    _opaque: *mut c_void,
}

/// Opaque handle passed to every LibraryLink function.
#[allow(non_camel_case_types)]
type WolframLibraryData = *mut c_void;

// ── Helper: safely read a UTF-8 string from an MArgument ────────────────────
/// Reads the UTF-8 string pointer from `Args[index]`.
///
/// The pointer chain is: `Args[index]` is an `MArgument` whose `utf8str`
/// field is a `char**`. Dereference once to get the `char*`.
///
/// # Safety
/// Caller must guarantee `index` is in bounds and the arg type is UTF8String.
unsafe fn get_utf8_string(args: *const MArgument, index: usize) -> Option<&'static str> {
    let marg = *args.add(index);
    // utf8str is *mut *mut c_char; dereference to get the char*
    let char_ptr: *mut c_char = *marg.utf8str;
    if char_ptr.is_null() {
        return None;
    }
    CStr::from_ptr(char_ptr).to_str().ok()
}

// ── The exported LibraryLink function ────────────────────────────────────────

/// `wl_ply_gaussian_count(path: UTF8String) -> Integer`
///
/// Reads a 3DGS PLY file and returns the number of Gaussian splats it
/// contains, or -1 on any error.
#[no_mangle]
pub unsafe extern "C" fn wl_ply_gaussian_count(
    _lib_data: WolframLibraryData,
    argc: mint,
    args: *mut MArgument,
    res: MArgument,
) -> errcode_t {
    // We expect exactly 1 argument.
    if argc != 1 || args.is_null() {
        return 1; // LIBRARY_FUNCTION_ERROR
    }

    let path_str = match get_utf8_string(args as *const MArgument, 0) {
        Some(s) => s,
        None => {
            *res.integer = -1;
            return 0;
        }
    };

    let count = ply_gaussian_count_impl(path_str);
    *res.integer = count;
    0 // LIBRARY_NO_ERROR
}

/// Pure-Rust implementation (also usable in unit tests).
fn ply_gaussian_count_impl(path: &str) -> mint {
    let file = match std::fs::File::open(path) {
        Ok(f) => f,
        Err(e) => {
            eprintln!("[GaussianSplatting] Cannot open {:?}: {}", path, e);
            return -1;
        }
    };
    let mut reader = std::io::BufReader::new(file);

    let header = match PlyGaussians::read_header(&mut reader) {
        Ok(h) => h,
        Err(e) => {
            eprintln!("[GaussianSplatting] read_header failed for {:?}: {}", path, e);
            return -1;
        }
    };

    // Fast path: Inria-format PLY exposes the count directly from the header.
    if let Some(count) = header.count() {
        return count as mint;
    }

    // Slow path: iterate through all Gaussians (Custom format).
    let iter = match PlyGaussians::read_gaussians(&mut reader, header) {
        Ok(it) => it,
        Err(e) => {
            eprintln!("[GaussianSplatting] read_gaussians failed for {:?}: {}", path, e);
            return -1;
        }
    };

    let mut count: mint = 0;
    for result in iter {
        match result {
            Ok(_) => count += 1,
            Err(e) => {
                eprintln!("[GaussianSplatting] Gaussian parse error: {}", e);
                return -1;
            }
        }
    }
    count
}

// ── Unit tests (no LibraryLink runtime needed) ───────────────────────────────
#[cfg(test)]
mod tests {
    use super::ply_gaussian_count_impl;

    #[test]
    fn test_missing_file() {
        assert_eq!(ply_gaussian_count_impl("/nonexistent/path.ply"), -1);
    }
}
