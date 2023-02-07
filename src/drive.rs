use drive3::{
    api::{DriveHub, File},
    hyper::{self, body::HttpBody, client::HttpConnector},
    hyper_rustls::{self, HttpsConnector},
    oauth2, Error,
};
use google_drive3 as drive3;
use std::env;

pub struct GDrive {
    hub: DriveHub<HttpsConnector<HttpConnector>>,
}

impl GDrive {
    pub async fn new() -> Self {
        let sa_creds_filename = env::var("GOOGLE_SA_PATH").unwrap_or_default();
        println!("Got SA creds path: {}", sa_creds_filename);

        let secret: oauth2::ServiceAccountKey = oauth2::read_service_account_key(sa_creds_filename)
            .await
            .expect("client secret could not be read");
        let sa = oauth2::ServiceAccountAuthenticator::builder(secret)
            .build()
            .await
            .unwrap();

        let hub = DriveHub::new(
            hyper::Client::builder().build(
                hyper_rustls::HttpsConnectorBuilder::new()
                    .with_native_roots()
                    .https_or_http()
                    .enable_http1()
                    .enable_http2()
                    .build(),
            ),
            sa,
        );

        Self { hub }
    }

    pub async fn list(&self) -> Result<Option<Vec<File>>, Error> {
        let result = self.hub.files().list().doit().await;

        match result {
            Err(e) => match e {
                // The Error enum provides details about what exactly happened.
                // You can also just use its `Debug`, `Display` or `Error` traits
                Error::HttpError(_)
                | Error::Io(_)
                | Error::MissingAPIKey
                | Error::MissingToken(_)
                | Error::Cancelled
                | Error::UploadSizeLimitExceeded(_, _)
                | Error::Failure(_)
                | Error::BadRequest(_)
                | Error::FieldClash(_)
                | Error::JsonDecodeError(_, _) => Err(e),
            },
            Ok(res) => Ok(res.1.files),
        }
    }

    // TODO: Split out get, download, and export
    pub async fn get(&self, file_id: &str) -> Result<Vec<u8>, Error> {
        let result = self
            .hub
            .files()
            .get(file_id)
            .param("alt", "media")
            // .acknowledge_abuse(true)
            .supports_all_drives(true)
            .add_scope("https://www.googleapis.com/auth/drive")
            .doit()
            .await;

        match result {
            Err(e) => match e {
                // The Error enum provides details about what exactly happened.
                // You can also just use its `Debug`, `Display` or `Error` traits
                Error::HttpError(_)
                | Error::Io(_)
                | Error::MissingAPIKey
                | Error::MissingToken(_)
                | Error::Cancelled
                | Error::UploadSizeLimitExceeded(_, _)
                | Error::Failure(_)
                | Error::BadRequest(_)
                | Error::FieldClash(_)
                | Error::JsonDecodeError(_, _) => Err(e),
            },
            Ok(res) => {
                let res = res.0;
                let mut body = res.into_body();

                let mut content = Vec::<u8>::default();
                while let Some(Ok(data)) = body.data().await {
                    let mut data = (*data).to_vec();
                    content.append(&mut data);
                }

                Ok(content)
            }
        }
    }
}
