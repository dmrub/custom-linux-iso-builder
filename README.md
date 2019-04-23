# Custom Linux ISO Builder
Script for customizing Linux Installation ISO 9660 images

## build-custom-iso.sh
Builds installation ISO based on configuration file. For examples see `config.sh` files
in subdirectories.
```
Build custom installation ISO 9660 image

./build-custom-iso.sh [options] [--] configuration-file [configuration-file ...]
options:
  -o, --output=OUTPUT_FILE   Specify the output file for the the ISO9660 filesystem image.
                             (default: install.iso)
  -c, --cache=CACHE_DIR      Directory in which the downloaded ISO files are stored
                             (default: /home/rubinste/Kubernetes/custom-linux-iso-builder/cache)
  -e,--eval=EXPR             Evaluate expression after all configuration files are loaded
  -d, --debug                Enable debug mode
      --help                 Display this help and exit
      --                     End of options
```

# License

This program is licensed under the Apache license. See [LICENSE](LICENSE) for the full text.

This product includes software developed by contributors:
* https://github.com/tests-always-included/mo
