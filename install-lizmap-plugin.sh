#!/bin/bash

# 
# Install lizmap plugin 
# This has to be run inside the qgis server container:
#
qgis-plugin-manager init
qgis-plugin-manager update
qgis-plugin-manager install "Lizmap server"
