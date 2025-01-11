#!/usr/bin/env bash

echo -n "$(hexdump -n 16 -v -e '32/1 "%02x" "\n"' /dev/urandom)"