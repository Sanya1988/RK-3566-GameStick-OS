#!/bin/sh
set -eu

if [ -x /usr/bin/gamestick-shutdown-screen ]; then
	/usr/bin/gamestick-shutdown-screen mark-poweroff
fi
