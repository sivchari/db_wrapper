# Package

version       = "0.1.0"
author        = "sivchari"
description   = "this libraly able to use database/sql of Go"
license       = "MIT"
srcDir        = "src"
skipDir       = @["database-resource", "db", "docker", "examples", "tests", "testresults"]
skipFiles     = @["Makefile", "docker-compose.yml"]


# Dependencies

requires "nim >= 1.4.6"
