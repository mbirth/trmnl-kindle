#!/bin/sh
# The framework job sends a SIGTERM on stop, trap it so we don't get killed if we were launched by KUAL
trap "" TERM
/usr/bin/lua TRMNL.lua
