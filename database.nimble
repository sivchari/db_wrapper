# Package

version       = "0.1.0"
author        = "sivchari"
description   = "this libraly able to use database/sql of Go"
license       = "MIT"
srcDir        = "src"
backend       = "c"
bin           = @["database/database"]
binDir        = "src/bin"
skipDirs      = @["database-resource", "db", "docker", "examples", "tests", "testresults"]
skipFiles     = @["README.md", "docker-compose.yml"]


# Dependencies

requires "nim >= 1.0.0"
