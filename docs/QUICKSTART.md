<!--
Copyright © 2025 Devin B. Royal. All Rights Reserved.
Project: M3hl@n! Unified Build System (Original IP).
SPDX-License-Identifier: LicenseRef-M3hlan-Enterprise
--># M3hl@n! QUICKSTART

1. Run `./core/build.sh init`
2. Attach language projects and call adapters in `manifests/adapters/`:
   - cargo_adapter.sh /path/to/rust/project
   - maven_adapter.sh /path/to/java/project
   - gradle_adapter.sh /path/to/gradle/project
   - npm_adapter.sh /path/to/node/project
   - yarn_adapter.sh /path/to/node/project
   - go_adapter.sh /path/to/go/module
   - cmake_adapter.sh /path/to/c-cpp/project
   - pip_adapter.sh /path/to/python/project
   - poetry_adapter.sh /path/to/python/project
   - swift_adapter.sh /path/to/swift/project
   - dotnet_adapter.sh /path/to/dotnet/solution
3. Run `make -C core build`
4. If successful: **GOT UM.**


# Copyright © 2025 Devin B. Royal. All Rights Reserved.