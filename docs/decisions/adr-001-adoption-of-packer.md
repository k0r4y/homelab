# ADR-001: Adoption of Packer for Golden Image Creation

## Status
Accepted

## Context
Initial attempts to provision lab VMs used Vagrant with third-party boxes (bento/ubuntu). This approach suffered from provider incompatibility (Hyper-V vs VirtualBox images) and lack of transparency regarding the OS configuration, presenting a supply-chain security risk for a security-focused lab.

## Decision
Adopt HashiCorp Packer to build custom "Golden Images" locally from official Ubuntu ISOs. 

## Consequences
- Pros: Guaranteed clean OS, full control over hardening scripts (auditd/security settings), no dependency on third-party registry availability.
- Cons: Increased build time and complexity; requires initial setup of Packer HCL templates.
- Risks: Maintaining image build scripts requires ongoing effort; requires additional disk space for local ISOs and built images.
