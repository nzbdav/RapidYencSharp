# Security Policy

## Supported versions

Security fixes are provided for the latest released version. Upgrade to the
newest package before reporting an issue that may already be resolved.

## Reporting a vulnerability

Do not open a public issue for a suspected vulnerability.

Use GitHub's
[private vulnerability reporting](https://github.com/nzbdav/RapidYencSharp/security/advisories/new)
to send a description, reproduction steps, affected versions, and any proposed
mitigation. You should receive an acknowledgement within seven days. We will
coordinate validation, remediation, and disclosure through the private
advisory.

If private reporting is unavailable, open a discussion that asks a maintainer
for a private contact channel without including vulnerability details.

## Security expectations

RapidYencSharp processes untrusted binary input through native code. Keep the
managed and native packages current, validate input and destination sizes, and
report crashes or memory-safety concerns privately.
