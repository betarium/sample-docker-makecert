# sample-docker-makecert

## licence
MIT License
Copyright (c) 2021 betarium

## Usage

```
    Usage:
      makecert <CA_NAME> <ACTION> <CERT_NAME> [option...]

      Create CA Cert.           <CA_NAME> ca
      Create server cert.       <CA_NAME> server <CERT_NAME> [COMMON_NAME]
      Show cert file.           <CA_NAME> show [CERT_NAME]

    example:
      example_com_ca ca
      example_com_ca server example.com *.example.com
      example_com_ca show example.com
```
