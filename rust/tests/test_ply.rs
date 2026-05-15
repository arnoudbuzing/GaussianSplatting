// Standalone test for release-mode behavior
use wgpu_3dgs_core::PlyGaussians;

#[test]
fn test_release_behavior() {
    let path = concat!(
        env!("CARGO_MANIFEST_DIR"),
        "/../tests/fixtures/small.ply"
    );
    let file = std::fs::File::open(path).expect("test fixture not found");
    let mut reader = std::io::BufReader::new(file);

    let header = PlyGaussians::read_header(&mut reader)
        .expect("read_header failed");

    let count_opt = header.count();
    println!("count_opt = {:?}", count_opt);

    // Simulate exactly what wl_ply_gaussian_count does
    if let Some(count) = count_opt {
        println!("Fast path: count = {count}");
        assert_eq!(count, 5);
        return;
    }

    // Should not reach here for Inria format
    panic!("Reached slow path unexpectedly");
}
