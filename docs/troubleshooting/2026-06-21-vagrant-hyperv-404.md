# 2026-06-21: Vagrant Hyper-V Provider 404/Not Found Errors

## Symptom
Attempts to run `vagrant up --provider=hyperv` resulted in `404 Not Found` errors or "Box does not support provider" errors when using standard registry boxes like `bento/ubuntu-24.04`.

## Investigation
- Verified that most official boxes are built for VirtualBox/VMware, not Hyper-V.
- Confirmed that Hyper-V provider in Vagrant requires specific box metadata that is rarely published by community maintainers.
- Local attempts to force provider matching via command-line flags did not resolve the registry 404s.

## Resolution
- Abandoned the "Box Registry" strategy for Hyper-V.
- Decided to transition to HashiCorp Packer to build images natively for Hyper-V.
- This bypasses the need for the Vagrant Cloud registry entirely.

## Impact
- Shifted project focus from "Configure" to "Build."
- This is a positive impact for the long-term maintainability of the lab's infrastructure.
