#!/bin/sh
# NVIDIA GPU for polybar: load, temperature and video memory in use (one line per GPU).
nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,memory.used --format=csv,noheader,nounits |
    awk -F', ' '{ printf "%d%% %d°C %.1fG\n", $1, $2, $3 / 1024 }'
