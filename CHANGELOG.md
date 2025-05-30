# Changelog

## [0.4.3](https://github.com/GoogleCloudPlatform/terraform-google-regional-lb-http/compare/v0.4.2...v0.4.3) (2025-04-21)


### Bug Fixes

* define capacity_scalar for the backend even when the load balancing scheme is INTERNAL_MANAGED ([#39](https://github.com/GoogleCloudPlatform/terraform-google-regional-lb-http/issues/39)) ([595f91f](https://github.com/GoogleCloudPlatform/terraform-google-regional-lb-http/commit/595f91fa5a98224f98bd97bbfc102ece7294871e))

## [0.4.2](https://github.com/GoogleCloudPlatform/terraform-google-regional-lb-http/compare/v0.4.1...v0.4.2) (2025-03-25)


### Bug Fixes

* added service specific iam roles ([#35](https://github.com/GoogleCloudPlatform/terraform-google-regional-lb-http/issues/35)) ([db322b0](https://github.com/GoogleCloudPlatform/terraform-google-regional-lb-http/commit/db322b0c10173aee6f01e3d185118848fe90e692))

## [0.4.1](https://github.com/GoogleCloudPlatform/terraform-google-regional-lb-http/compare/v0.4.0...v0.4.1) (2025-03-07)


### Bug Fixes

* update description for load_balancing_scheme ([#31](https://github.com/GoogleCloudPlatform/terraform-google-regional-lb-http/issues/31)) ([7b27c82](https://github.com/GoogleCloudPlatform/terraform-google-regional-lb-http/commit/7b27c824beb1cd15f6de5f50c5daab46825f02f7))

## [0.4.0](https://github.com/GoogleCloudPlatform/terraform-google-regional-lb-http/compare/v0.3.2...v0.4.0) (2025-02-25)


### Features

* add support for internal load balancer ([#28](https://github.com/GoogleCloudPlatform/terraform-google-regional-lb-http/issues/28)) ([f221a76](https://github.com/GoogleCloudPlatform/terraform-google-regional-lb-http/commit/f221a76b267928da2e5e3bb945817c6d0d41f3a5))

## [0.3.2](https://github.com/GoogleCloudPlatform/terraform-google-regional-lb-http/compare/v0.3.1...v0.3.2) (2025-02-17)


### Bug Fixes

* add connection metadata for GCE MIG ([#26](https://github.com/GoogleCloudPlatform/terraform-google-regional-lb-http/issues/26)) ([a23367a](https://github.com/GoogleCloudPlatform/terraform-google-regional-lb-http/commit/a23367a21190a22e51ae6bbec7a0f1de74aaa30e))

## [0.3.1](https://github.com/GoogleCloudPlatform/terraform-google-regional-lb-http/compare/v0.3.0...v0.3.1) (2025-02-05)


### Bug Fixes

* fix typo in the description ([#24](https://github.com/GoogleCloudPlatform/terraform-google-regional-lb-http/issues/24)) ([7c9fbfb](https://github.com/GoogleCloudPlatform/terraform-google-regional-lb-http/commit/7c9fbfb1b818ef08c46cf75f6334a9a4328f7dda))

## [0.3.0](https://github.com/GoogleCloudPlatform/terraform-google-regional-lb-http/compare/v0.2.0...v0.3.0) (2025-02-05)


### ⚠ BREAKING CHANGES

* add flag to create REGIONAL_MANAGED_PROXY subnet within modules… ([#21](https://github.com/GoogleCloudPlatform/terraform-google-regional-lb-http/issues/21))

### Features

* add flag to create REGIONAL_MANAGED_PROXY subnet within modules… ([#21](https://github.com/GoogleCloudPlatform/terraform-google-regional-lb-http/issues/21)) ([60e4d9e](https://github.com/GoogleCloudPlatform/terraform-google-regional-lb-http/commit/60e4d9edc357a8b55894b0fdb194dc04b74df45a))

## [0.2.0](https://github.com/GoogleCloudPlatform/terraform-google-regional-lb-http/compare/v0.1.3...v0.2.0) (2025-01-28)


### Features

* add support for ipv6 and test/example for GCE MIG ([#16](https://github.com/GoogleCloudPlatform/terraform-google-regional-lb-http/issues/16)) ([2701087](https://github.com/GoogleCloudPlatform/terraform-google-regional-lb-http/commit/270108739656033430032fc032b153eeeb3fbcba))

## [0.1.3](https://github.com/GoogleCloudPlatform/terraform-google-regional-lb-http/compare/v0.1.2...v0.1.3) (2025-01-16)


### Bug Fixes

* remove alternate default for health_check ([#14](https://github.com/GoogleCloudPlatform/terraform-google-regional-lb-http/issues/14)) ([30f5d96](https://github.com/GoogleCloudPlatform/terraform-google-regional-lb-http/commit/30f5d9690b2ca5472058546eea5799437d5f6b2a))

## [0.1.2](https://github.com/GoogleCloudPlatform/terraform-google-regional-lb-http/compare/v0.1.1...v0.1.2) (2025-01-16)


### Bug Fixes

* update alternate default to have in right format ([#11](https://github.com/GoogleCloudPlatform/terraform-google-regional-lb-http/issues/11)) ([46efbf7](https://github.com/GoogleCloudPlatform/terraform-google-regional-lb-http/commit/46efbf70a8c3ce6d11988a563b460f170f719711))

## [0.1.1](https://github.com/GoogleCloudPlatform/terraform-google-regional-lb-http/compare/v0.1.0...v0.1.1) (2025-01-15)


### Bug Fixes

* update alternate default for health_check ([#9](https://github.com/GoogleCloudPlatform/terraform-google-regional-lb-http/issues/9)) ([44216b7](https://github.com/GoogleCloudPlatform/terraform-google-regional-lb-http/commit/44216b76021ab8e2129e40c5e06ae10e8182a334))

## 0.1.0 (2025-01-10)


### Features

* create proxy-only subnet in modules/frontend and add CI build,  readme and metadata files ([#6](https://github.com/GoogleCloudPlatform/terraform-google-regional-lb-http/issues/6)) ([42ccac7](https://github.com/GoogleCloudPlatform/terraform-google-regional-lb-http/commit/42ccac7cfecfe192696e7149d43e93151818daac))
