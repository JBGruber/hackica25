# small script to use the decompress function from the original GitHub
curl::curl_download(
  "https://raw.githubusercontent.com/leonardo-blas/usc-tg-24-us-election/refs/heads/main/decompress.py",
  "1._decompress.py"
)
library(reticulate)
source_python("1._decompress.py")
dir.create("data_decompressed", showWarnings = FALSE)
py$decompress_db("data/channel_1000154686.db", "data_decompressed/channel_1000154686.db")
