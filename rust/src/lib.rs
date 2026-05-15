use wolfram_library_link::{export, NumericArray};
use wgpu_3dgs_core::PlyGaussians;

mod render;

#[export]
pub fn wl_ply_gaussian_count(path: String) -> i64 {
    let file = match std::fs::File::open(&path) {
        Ok(f) => f,
        Err(_) => return -1,
    };
    let mut reader = std::io::BufReader::new(file);

    let header = match PlyGaussians::read_header(&mut reader) {
        Ok(h) => h,
        Err(_) => return -1,
    };

    if let Some(count) = header.count() {
        return count as i64;
    }

    let iter = match PlyGaussians::read_gaussians(&mut reader, header) {
        Ok(it) => it,
        Err(_) => return -1,
    };

    let mut count: i64 = 0;
    for result in iter {
        if result.is_ok() {
            count += 1;
        }
    }
    count
}

#[export]
pub fn wl_ply_gaussian_positions(path: String) -> NumericArray<f32> {
    let file = match std::fs::File::open(&path) {
        Ok(f) => f,
        Err(_) => return NumericArray::<f32>::from_slice(&[]),
    };
    let mut reader = std::io::BufReader::new(file);

    let header = match PlyGaussians::read_header(&mut reader) {
        Ok(h) => h,
        Err(_) => return NumericArray::<f32>::from_slice(&[]),
    };

    let count = match header.count() {
        Some(c) => c,
        None => 0,
    };

    let iter = match PlyGaussians::read_gaussians(&mut reader, header) {
        Ok(it) => it,
        Err(_) => return NumericArray::<f32>::from_slice(&[]),
    };

    let mut data = Vec::with_capacity((count * 3) as usize);

    for result in iter {
        if let Ok(gaussian) = result {
            data.push(gaussian.pos[0]);
            data.push(gaussian.pos[1]);
            data.push(gaussian.pos[2]);
        }
    }

    NumericArray::<f32>::from_slice(&data)
}

#[export]
pub fn wl_ply_gaussian_colors(path: String) -> NumericArray<f32> {
    let empty = NumericArray::<f32>::from_slice(&[]);
    let file = match std::fs::File::open(&path) {
        Ok(f) => f,
        Err(_) => return empty,
    };
    let mut reader = std::io::BufReader::new(file);

    let header = match PlyGaussians::read_header(&mut reader) {
        Ok(h) => h,
        Err(_) => return empty,
    };

    let count = header.count().unwrap_or(0);
    let iter = match PlyGaussians::read_gaussians(&mut reader, header) {
        Ok(it) => it,
        Err(_) => return empty,
    };

    let mut data = Vec::with_capacity((count * 4) as usize);
    for result in iter {
        if let Ok(pod) = result {
            let g = wgpu_3dgs_core::Gaussian::from_ply(&pod);
            let c = g.color.to_array();
            data.push(c[0] as f32 / 255.0);
            data.push(c[1] as f32 / 255.0);
            data.push(c[2] as f32 / 255.0);
            data.push(c[3] as f32 / 255.0); // opacity
        }
    }
    NumericArray::<f32>::from_slice(&data)
}

#[export]
pub fn wl_ply_gaussian_scales(path: String) -> NumericArray<f32> {
    let empty = NumericArray::<f32>::from_slice(&[]);
    let file = match std::fs::File::open(&path) {
        Ok(f) => f,
        Err(_) => return empty,
    };
    let mut reader = std::io::BufReader::new(file);

    let header = match PlyGaussians::read_header(&mut reader) {
        Ok(h) => h,
        Err(_) => return empty,
    };

    let count = header.count().unwrap_or(0);
    let iter = match PlyGaussians::read_gaussians(&mut reader, header) {
        Ok(it) => it,
        Err(_) => return empty,
    };

    let mut data = Vec::with_capacity((count * 3) as usize);
    for result in iter {
        if let Ok(g) = result {
            let s = g.scale;
            data.push(s[0]);
            data.push(s[1]);
            data.push(s[2]);
        }
    }
    NumericArray::<f32>::from_slice(&data)
}

#[export]
pub fn wl_ply_gaussian_rotations(path: String) -> NumericArray<f32> {
    let empty = NumericArray::<f32>::from_slice(&[]);
    let file = match std::fs::File::open(&path) {
        Ok(f) => f,
        Err(_) => return empty,
    };
    let mut reader = std::io::BufReader::new(file);

    let header = match PlyGaussians::read_header(&mut reader) {
        Ok(h) => h,
        Err(_) => return empty,
    };

    let count = header.count().unwrap_or(0);
    let iter = match PlyGaussians::read_gaussians(&mut reader, header) {
        Ok(it) => it,
        Err(_) => return empty,
    };

    let mut data = Vec::with_capacity((count * 4) as usize);
    for result in iter {
        if let Ok(g) = result {
            let r = g.rot;
            data.push(r[0]);
            data.push(r[1]);
            data.push(r[2]);
            data.push(r[3]);
        }
    }
    NumericArray::<f32>::from_slice(&data)
}

#[export]
pub fn wl_ply_gaussian_opacities(path: String) -> NumericArray<f32> {
    let empty = NumericArray::<f32>::from_slice(&[]);
    let file = match std::fs::File::open(&path) {
        Ok(f) => f,
        Err(_) => return empty,
    };
    let mut reader = std::io::BufReader::new(file);

    let header = match PlyGaussians::read_header(&mut reader) {
        Ok(h) => h,
        Err(_) => return empty,
    };

    let count = header.count().unwrap_or(0);
    let iter = match PlyGaussians::read_gaussians(&mut reader, header) {
        Ok(it) => it,
        Err(_) => return empty,
    };

    let mut data = Vec::with_capacity(count as usize);
    for result in iter {
        if let Ok(pod) = result {
            let g = wgpu_3dgs_core::Gaussian::from_ply(&pod);
            data.push(g.color.w as f32 / 255.0);
        }
    }
    NumericArray::<f32>::from_slice(&data)
}

#[export]
pub fn wl_ply_gaussian_render(path: String, width: i64, height: i64, px: f64, py: f64, pz: f64, pitch: f64, yaw: f64, fov: f64, display_mode: i64) -> NumericArray<u8> {
    let params = [px as f32, py as f32, pz as f32, pitch as f32, yaw as f32, fov as f32];
    if let Some(arr) = render::render_gaussian_to_image(&path, width as u32, height as u32, &params, display_mode as u8) {
        arr
    } else {
        NumericArray::<u8>::from_slice(&[])
    }
}
