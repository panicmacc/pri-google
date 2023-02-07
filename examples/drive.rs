use pri_google::drive;
use std::env;

#[tokio::main]
async fn main() {
    let drive = drive::GDrive::new().await;

    // Get a list of all files available to the Service Account
    if let Ok(Some(files)) = drive.list().await {
        println!("{:#?}", files);
    };

    // Get file id as first cli argument.
    let file_id = env::args().skip(1).next().unwrap_or_default().to_string();

    // Fetch the file with the specified ID.
    // TODO: differentiate "get", "download", and "export". Return File for "get", and bytes for latter two.
    if let Ok(content) = drive.get(&file_id[..]).await {
        use std::fs;
        use std::io::Write; // bring trait into scope

        let mut file = fs::OpenOptions::new()
            .write(true)
            .create(true)
            .open("./test.pdf")
            .unwrap();
        file.write_all(content.as_slice()).unwrap();
    };
}
