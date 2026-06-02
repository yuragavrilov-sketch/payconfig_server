# Corporate CA certificates (vendored, pinned)

Drop the corporate **root CA** certificate (PEM) here so the image trusts the corp git server
(`git.tkbbank.ru`) and JGit can clone the config-repo over HTTPS with TLS verification ON.

- File name: anything ending in `.crt` or `.pem`, e.g. `tkbbank-root.crt`.
- Format: PEM (`-----BEGIN CERTIFICATE-----`).
- This is a **public** CA certificate — safe to commit. Do NOT put private keys here.
- The `Dockerfile` `COPY`s this directory and `keytool -importcert`s every `*.crt`/`*.pem`
  into the JRE truststore (`cacerts`).

## How to obtain the corp root CA (one-time)

- From corp PKI / IT portal, or
- Export from a browser: open `https://git.tkbbank.ru` → certificate → view the chain →
  export the **root** (top) CA as Base-64 (PEM), or
- From a trusted machine already configured for the corp network:
  `openssl s_client -connect git.tkbbank.ru:443 -showcerts` and save the **root** cert
  (verify its fingerprint against the corp PKI out-of-band before committing).

After committing the CA here, set `CONFIG_GIT_SKIP_SSL: "false"` in `helm/values-test.yaml`.
