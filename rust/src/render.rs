use std::sync::mpsc;
use wgpu_3dgs_viewer::{Viewer, Camera, DefaultGaussianPod};
use wgpu_3dgs_core::{PlyGaussians, Gaussians, ReadIterGaussian};
use wolfram_library_link::NumericArray;
use glam::{Vec3, Quat};

pub fn render_ply_to_image(path: &str, width: u32, height: u32, camera_params: &[f32], display_mode: u8) -> Option<NumericArray<u8>> {
    let file = std::fs::File::open(path).ok()?;
    let mut reader = std::io::BufReader::new(file);
    let ply = PlyGaussians::read_from(&mut reader).ok()?;
    let gaussians = Gaussians::from(ply);
    
    pollster::block_on(render_async(gaussians, width, height, camera_params, display_mode))
}

async fn render_async(gaussians: Gaussians, width: u32, height: u32, camera_params: &[f32], display_mode: u8) -> Option<NumericArray<u8>> {
    let instance = wgpu::Instance::default();
    let adapter = instance
        .request_adapter(&wgpu::RequestAdapterOptions {
            power_preference: wgpu::PowerPreference::HighPerformance,
            compatible_surface: None,
            force_fallback_adapter: false,
        })
        .await
        .ok()?;

    let (device, queue) = adapter
        .request_device(
            &wgpu::DeviceDescriptor {
                label: None,
                required_features: wgpu::Features::empty(),
                required_limits: wgpu::Limits::default(),
                ..Default::default()
            }
        )
        .await
        .ok()?;

    let texture_format = wgpu::TextureFormat::Rgba8Unorm;
    let mut viewer: Viewer<DefaultGaussianPod> = Viewer::new(&device, texture_format, &gaussians).ok()?;

    let mut camera = Camera::new(0.1..100.0, camera_params.get(5).cloned().unwrap_or(std::f32::consts::FRAC_PI_4));
    camera.pos = Vec3::new(
        camera_params.get(0).cloned().unwrap_or(0.0),
        camera_params.get(1).cloned().unwrap_or(0.0),
        camera_params.get(2).cloned().unwrap_or(3.0),
    );
    camera.pitch = camera_params.get(3).cloned().unwrap_or(0.0);
    camera.yaw = camera_params.get(4).cloned().unwrap_or(std::f32::consts::PI);

    viewer.update_camera(&queue, &camera, glam::UVec2::new(width, height));
    viewer.update_model_transform(&queue, Vec3::ZERO, Quat::IDENTITY, Vec3::ONE);
    let mode = match display_mode {
        1 => wgpu_3dgs_core::GaussianDisplayMode::Ellipse,
        2 => wgpu_3dgs_core::GaussianDisplayMode::Point,
        _ => wgpu_3dgs_core::GaussianDisplayMode::Splat,
    };

    viewer.update_gaussian_transform(
        &queue,
        1.0, 
        mode,
        wgpu_3dgs_core::GaussianShDegree::new(0).unwrap(), 
        false,
        wgpu_3dgs_core::GaussianMaxStdDev::default(),
    );

    let texture_desc = wgpu::TextureDescriptor {
        size: wgpu::Extent3d {
            width,
            height,
            depth_or_array_layers: 1,
        },
        mip_level_count: 1,
        sample_count: 1,
        dimension: wgpu::TextureDimension::D2,
        format: texture_format,
        usage: wgpu::TextureUsages::RENDER_ATTACHMENT | wgpu::TextureUsages::COPY_SRC,
        label: None,
        view_formats: &[],
    };
    let texture = device.create_texture(&texture_desc);
    let texture_view = texture.create_view(&wgpu::TextureViewDescriptor::default());

    let mut encoder = device.create_command_encoder(&wgpu::CommandEncoderDescriptor::default());

    {
        let _rpass = encoder.begin_render_pass(&wgpu::RenderPassDescriptor {
            label: None,
            color_attachments: &[Some(wgpu::RenderPassColorAttachment {
                view: &texture_view,
                resolve_target: None,
                ops: wgpu::Operations {
                    load: wgpu::LoadOp::Clear(wgpu::Color::BLACK),
                    store: wgpu::StoreOp::Store,
                },
                depth_slice: None,
            })],
            depth_stencil_attachment: None,
            timestamp_writes: None,
            occlusion_query_set: None,
            ..Default::default()
        });
    }

    viewer.render(&mut encoder, &texture_view);

    let u32_size = std::mem::size_of::<u32>() as u32;
    // bytes_per_row must be a multiple of 256 for CopyBuffer!
    let bytes_per_row = (u32_size * width + 255) & !255; 
    let output_buffer_size = (bytes_per_row * height) as wgpu::BufferAddress;
    
    let output_buffer_desc = wgpu::BufferDescriptor {
        size: output_buffer_size,
        usage: wgpu::BufferUsages::COPY_DST | wgpu::BufferUsages::MAP_READ,
        label: None,
        mapped_at_creation: false,
    };
    let output_buffer = device.create_buffer(&output_buffer_desc);

    encoder.copy_texture_to_buffer(
        wgpu::TexelCopyTextureInfo {
            aspect: wgpu::TextureAspect::All,
            texture: &texture,
            mip_level: 0,
            origin: wgpu::Origin3d::ZERO,
        },
        wgpu::TexelCopyBufferInfo {
            buffer: &output_buffer,
            layout: wgpu::TexelCopyBufferLayout {
                offset: 0,
                bytes_per_row: Some(bytes_per_row),
                rows_per_image: Some(height),
            },
        },
        texture_desc.size,
    );

    queue.submit(Some(encoder.finish()));

    let buffer_slice = output_buffer.slice(..);
    let (tx, rx) = mpsc::channel();
    buffer_slice.map_async(wgpu::MapMode::Read, move |result| {
        tx.send(result).unwrap();
    });
    device.poll(wgpu::PollType::wait_indefinitely());
    rx.recv().unwrap().unwrap();

    let data = buffer_slice.get_mapped_range();
    
    // We need to un-pad the data if bytes_per_row != u32_size * width
    let mut unpadded_data = Vec::with_capacity((width * height * u32_size) as usize);
    let row_len = (width * u32_size) as usize;
    for chunk in data.chunks(bytes_per_row as usize) {
        unpadded_data.extend_from_slice(&chunk[..row_len]);
    }
    
    let num_array = NumericArray::<u8>::from_slice(&unpadded_data);
    drop(data);
    output_buffer.unmap();

    Some(num_array)
}
