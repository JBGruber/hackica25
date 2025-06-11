# small script to use the decompress function from the original GitHub
curl::curl_download(
  "https://raw.githubusercontent.com/leonardo-blas/usc-tg-24-us-election/refs/heads/main/decompress.py",
  "1._decompress.py"
)
library(reticulate)
source_python("1._decompress.py")
dir.create("data_decompressed", showWarnings = FALSE)

channel_files <- list.files("data", ".db$", full.names = TRUE)
for (f in channel_files) {
  message("decompressing ", f, " (", which(f == channel_files), " of ", length(channel_files), ")")
  py$decompress_db(
    f,
    file.path("data_decompressed", basename(f))
  )
}

