# sample-docker-makecert

## Description

Create SSL certificate file in docker.
Support Windows and Linux.

## Require

* docker
* docker-compose

## Usage

```
    Usage:
      makecert <ACTION> <option...>

      Create CA certificate.            ca <CA_NAME>
      Create server certificate.        server <CA_NAME> <CERT_NAME> [COMMON_NAME]
      Create self sigin certificate.    self <CA_NAME> <CERT_NAME> [COMMON_NAME]
      Show certificate file.            show <CA_NAME> [CERT_NAME]

    Example:
      makecert ca example_com_ca
      makecert server example_com_ca example.com.local *.example.com.local
      makecert show example_com_ca example.com.local
```

```
    Option:
      makecert --build          Build docker image.
      makecert --help           Show help.
      makecert bash             Run bash shell.
```

```
    Windows Console:
      makecert.bat --help
    Windows Powershell:
      .\makecert --help
    Linux:
      ./makecert --help
```


## Test cert
curl --verbose https://example.com.local

## Import certificate to system

### fodora
```
sudo cp <CA_CERT_NAME> /usr/share/pki/ca-trust-source/anchors/
sudo update-ca-trust extract

cat /etc/pki/tls/certs/ca-bundle.crt | grep <CA_CERT_NAME>
```

## Import certificate to browser

### Chrome

chrome://flags/#allow-insecure-localhost
change true

## Licence
MIT License
Copyright (c) 2021 betarium
