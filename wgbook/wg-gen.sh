#!/bin/bash

privkey=$(wg genkey) sh -c 'printf "server_privkey: $privkey\nserver_pubkey: $(echo $privkey | wg pubkey)\n"'

