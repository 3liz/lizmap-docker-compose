@echo off

:: define some variable
set SCRIPTDIR=%~dp0
set INSTALL_DEST=%SCRIPTDIR%lizmap
set INSTALL_SOURCE=%SCRIPTDIR%
:: ensure it match with .env.windows !
set QGIS_VERSION_TAG=ltr-rc

:: docker run that launch _configure (create service file/lizmapprofile, install plugin, ...)
docker run -it -u 1000:1000 --rm -e INSTALL_SOURCE=/install -e INSTALL_DEST=/lizmap -e "LIZMAP_DIR=%INSTALL_DEST%" -e QGSRV_SERVER_PLUGINPATH=/lizmap/plugins -v "%INSTALL_SOURCE%:/install" -v "%INSTALL_DEST%:/lizmap" -v "%INSTALL_SOURCE%:/src" --entrypoint /src/configure.sh 3liz/qgis-map-server:%QGIS_VERSION_TAG% _configure

:: all ok, next step is to launch docker-compose
echo setup finished, you can run 'docker-compose --env-file=.env.windows up'
 
