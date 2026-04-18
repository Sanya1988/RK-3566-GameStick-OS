#!/bin/sh

if command -v gamestick-input-refresh >/dev/null 2>&1; then
	gamestick-input-refresh --once >/dev/null 2>&1 || true
fi
