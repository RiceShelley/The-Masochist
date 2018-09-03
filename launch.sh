#!/bin/bash
make
./make_sblob.sh
echo "Starting game..."
sudo xterm -fg green -sl 0 -fullscreen -e ./game
