require 'spec_helper'

module ChefAPI
  describe Resource::Client do
    describe '.initialize' do
      it 'converts an x509 certificate to a public key' do
        certificate = <<-EOH.gsub(/^ {10}/, '')
          -----BEGIN CERTIFICATE-----
          MIIDOjCCAqOgAwIBAgIEkT9umDANBgkqhkiG9w0BAQUFADCBnjELMAkGA1UEBhMC
          VVMxEzARBgNVBAgMCldhc2hpbmd0b24xEDAOBgNVBAcMB1NlYXR0bGUxFjAUBgNV
          BAoMDU9wc2NvZGUsIEluYy4xHDAaBgNVBAsME0NlcnRpZmljYXRlIFNlcnZpY2Ux
          MjAwBgNVBAMMKW9wc2NvZGUuY29tL2VtYWlsQWRkcmVzcz1hdXRoQG9wc2NvZGUu
          Y29tMCAXDTEzMDYwNzE3NDcxNloYDzIxMDIwNzIyMTc0NzE2WjCBnTEQMA4GA1UE
          BxMHU2VhdHRsZTETMBEGA1UECBMKV2FzaGluZ3RvbjELMAkGA1UEBhMCVVMxHDAa
          BgNVBAsTE0NlcnRpZmljYXRlIFNlcnZpY2UxFjAUBgNVBAoTDU9wc2NvZGUsIElu
          Yy4xMTAvBgNVBAMUKFVSSTpodHRwOi8vb3BzY29kZS5jb20vR1VJRFMvY2xpZW50
          X2d1aWQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCko42znqDzryvE
          aB1DBHLFpjLZ7aWrTJQJJUvQhMFTE/1nisa+1bw8MvOYnGDSp2j6V7XJsJgZFsAW
          7w5TTBHrYRAz0Boi+uaQ3idqfGI5na/dRt2MqFnwJYqvm7z+LeeYbGlXFNnhUInt
          OjZD6AtrvuTGAEVdyIznsOMsLun/KWy9zG0+C+6vCnxGga+Z+xZ56JrBvWoWeIjG
          kO0J6E3uqyzAC8FwN6xnyaHNlvODE+40MuioVJ52oLikTwaVe3T+vSJQoCu1lz7c
          AbdszAhDW2p+GVvBBjAXLNi/w27heDQKBQOS+6tHJAX3WeFj0xgE5Bryae67E0q8
          hM4WPL6PAgMBAAEwDQYJKoZIhvcNAQEFBQADgYEAWlBQBu8kzhSA4TuHJNyngRAJ
          WXHus2brJZHaaZYMbzZMq+lklMbdw8NZBay+qVqN/latgQ7fjY9RSSdhCTeSITyw
          gn8s3zeFS7C6nwrzYNAQXTRJZoSgn32hgZoD1H0LjW5vcoqiYZOHvX3EOySboS09
          bAELUrq85D+uVns9C5A=
          -----END CERTIFICATE-----
        EOH

        instance = described_class.new(certificate: certificate)
        expect(instance.public_key).to eq <<-EOH.gsub(/^ {10}/, '')
          -----BEGIN PUBLIC KEY-----
          MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEApKONs56g868rxGgdQwRy
          xaYy2e2lq0yUCSVL0ITBUxP9Z4rGvtW8PDLzmJxg0qdo+le1ybCYGRbAFu8OU0wR
          62EQM9AaIvrmkN4nanxiOZ2v3UbdjKhZ8CWKr5u8/i3nmGxpVxTZ4VCJ7To2Q+gL
          a77kxgBFXciM57DjLC7p/ylsvcxtPgvurwp8RoGvmfsWeeiawb1qFniIxpDtCehN
          7qsswAvBcDesZ8mhzZbzgxPuNDLoqFSedqC4pE8GlXt0/r0iUKArtZc+3AG3bMwI
          Q1tqfhlbwQYwFyzYv8Nu4Xg0CgUDkvurRyQF91nhY9MYBOQa8mnuuxNKvITOFjy+
          jwIDAQAB
          -----END PUBLIC KEY-----
        EOH
      end
    end

    describe '#regenerate_keys' do
      it 'raises an error if the client is not persisted to the server' do
        expect {
          described_class.new.regenerate_keys
        }.to raise_error(Error::CannotRegenerateKey)
      end
    end
  end
end
