#!/bin/bash
scanimage --device-name=pixma --source "ADF Duplex" --mode Gray --resolution 300 --format pnm --batch=%04d.pnm
