# Custom Linux ISO Builder
Script for customizing Linux Installation ISO

## build-custom-iso.sh
Builds installation ISO based on configuration file. For examples see `config.sh` files
in subdirectories.
```
Build custom installation ISO

./build-custom-iso.sh [options] [--] configuration-file
options:
  -d, --debug                Enable debug mode
      --help                 Display this help and exit
  -c, --cache=CACHE_DIR      Directory in which the downloaded ISO files are stored
      --                     End of options
```

# License

This program is licensed under the Apache license. See [LICENSE](LICENSE) for the full text.

This product includes software developed by contributors: 
* https://github.com/tests-always-included/mo
