#!/bin/bash
# See README.md
pip install --no-index --find-links=/mnt/wheelhouse -r /mnt/idu/requirements.txt
pip install --no-cache-dir -r /mnt/idu/requirements.txt
pip install --no-cache-dir -r https://raw.githubusercontent.com/odoo/odoo/10.0/requirements.txt
pip install --no-cache-dir -r https://raw.githubusercontent.com/it-projects-llc/misc-addons/10.0/requirements.txt
apt-get autoclean & apt-get clean & apt-get autoremove
# pip freeze > /mnt/wheelhouse/requirements.txt
# pip wheel --wheel-dir=/mnt/wheelhouse -r /mnt/wheelhouse/requirements.txt
# pip install --no-index --find-links=/mnt/wheelhouse -r /mnt/wheelhouse/requirements.txt
