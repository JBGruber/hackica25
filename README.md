

# Material from our HackICA25 group project

## Set up the computational environment

In R:

``` r
c("attachment", "rlang") |> 
    setdiff(installed.packages()[, "Package"]) |> 
    install.packages()

list.files(".", ".r|.R") |> 
  attachment::att_from_rscripts() |> 
  rlang::check_installed()
```

To run [`2._combine.sh`](2._combine.sh), you also need the command-line
tool [jq](https://jqlang.org/).
