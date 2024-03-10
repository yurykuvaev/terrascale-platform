# Account-level configuration shared across environments deployed in the
# same AWS account. Override on a per-environment basis by introducing a
# nested account.hcl, but typically each env lives in its own account.

locals {
  account_id   = "123456789012" # placeholder; replace before bootstrap
  account_name = "terrascale"
}
