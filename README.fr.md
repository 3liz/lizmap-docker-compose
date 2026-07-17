# Lancer la stack Lizmap avec docker-compose

[🇬🇧 Read this in English](README.md)

Lance une stack Lizmap complète avec des données de test.

- Lizmap Web Client
- QGIS Server avec Py-QGIS-Server
- PostgreSQL avec PostGIS
- Redis

**Remarque** : ceci est une configuration d'exemple pour tester le client web Lizmap avec les
fonctionnalités QGIS et WPS.

❗**Si vous souhaitez l'utiliser sur un serveur de production, vous devrez faire des ajustements
pour répondre à vos besoins de production.**

## 🚀 Essayer Lizmap en ligne en un clic (sans installation)

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/3liz/lizmap-docker-compose)

Vous voulez tester Lizmap sans rien installer ? Cliquez sur le badge ci-dessus (un compte GitHub
gratuit suffit). GitHub Codespaces démarre toute la stack pour vous et ouvre Lizmap dans votre
navigateur après quelques minutes — avec deux cartes de démonstration déjà chargées.

- **Identifiant administrateur :** `admin` — **mot de passe :** `admin`
- Gratuit dans la limite du [forfait gratuit de Codespaces](https://github.com/features/codespaces)
  (60 heures/mois). Votre instance vous est privée et conserve son état pendant quelques semaines
  (elle se suspend en cas d'inactivité et reprend à la demande).
- Tout s'exécute dans *votre* Codespace, accessible à l'URL fournie par Codespaces
  (`https://<your-codespace>-8090.app.github.dev`) — il n'y a pas de serveur partagé.

Vous voulez **publier votre propre projet QGIS** (y compris des données stockées dans la base
PostGIS) ? Voir **[PUBLISH.fr.md](PUBLISH.fr.md)**.

Ceci est destiné à l'évaluation/aux tests. Pour la production, utilisez la configuration
`docker compose` ci-dessous.

## Prérequis

- Docker Engine, aussi connu sous le nom de Docker CE
- Le plugin Docker Compose

Nous recommandons d'utiliser le dépôt de Docker https://docs.docker.com/engine/install/

## Démarrage rapide

Exécutez les commandes ci-dessous pour votre système et ouvrez votre navigateur à l'adresse
http://localhost:8090.

### Linux

Dans un shell, configurez l'environnement :
```bash
./configure.sh configure
```
Ou si vous voulez tester une version spécifique (ici la dernière version 3.X.Y) :
```bash
LIZMAP_VERSION_TAG=3.9 ./configure.sh configure
```

Lancez la stack :
```bash
docker compose pull
docker compose up -d
```

Pour rendre Lizmap visible depuis un autre système, préfixez la commande docker par une variable.
Attention ! Ceci sera en HTTP simple sans chiffrement et n'est pas adapté à la production.
```bash
LIZMAP_PORT=EXTERNAL_IP_HERE:80 docker compose up
```

### Windows

Pour utiliser Docker sous Windows, vous pouvez installer
[Docker desktop pour Windows](https://docs.docker.com/desktop/windows/install/)

Si vous avez une distribution installée (Ubuntu, ...) dans WSL, vous pouvez simplement lancer la
commande Linux ci-dessus, une fois dedans.

Ou en PowerShell, exécutez la commande suivante pour mettre en place certains fichiers
```bash
configure.bat
```
Vous pouvez ensuite lancer docker avec
```bash
docker compose --env-file .env.windows up
```
Ou si vous voulez tester une version spécifique, vous pouvez éditer `.env.windows` et changer
(ici la dernière version 3.X.Y) :

```bash
LIZMAP_VERSION_TAG=3.9
```

## Premier lancement

Les commandes précédentes créent un environnement docker-compose et lancent la stack.

Le service Lizmap démarrera deux projets de démonstration que vous devrez configurer dans
l'interface Lizmap.

Consultez la [documentation Lizmap](https://docs.lizmap.com) pour savoir comment configurer
Lizmap au premier lancement.

L'identifiant par défaut est `admin`, le mot de passe `admin`. Il vous sera demandé de le changer
lors de la première connexion.

## Ajouter votre propre projet

Vous devez :
* créer un répertoire dans `lizmap/instances`
* visiter http://localhost:8090/admin.php/admin/maps/
* dans le panneau d'administration Lizmap, ajouter le répertoire que vous avez créé
* ajouter un ou plusieurs projets QGIS avec le fichier CFG Lizmap dans le répertoire

## Module WebDAV

La stack embarque le [module Lizmap WebDAV](https://github.com/3liz/lizmap-webdav-module)
déclaré dans `lizmap.dir/var/lizmap-my-packages/composer.json`, prêt à être installé et activé
sans aucune étape manuelle — mais il est **optionnel** pour une stack locale classique, et
**activé par défaut** pour la démo en ligne "Open in GitHub Codespaces".

- **GitHub Codespaces** : activé automatiquement (voir `LIZMAP_ENABLE_EXTRA_MODULES` dans
  `.devcontainer/docker-compose.codespaces.yml`). Une fois le Codespace lancé, parcourez les
  projets via WebDAV à l'adresse `<your-codespace-url>/dav.php/` (authentification basique, mêmes
  identifiants que le compte administrateur Lizmap).
- **`docker compose up` local** : désactivé par défaut. Pour l'activer, définissez
  `LIZMAP_ENABLE_EXTRA_MODULES=1` avant de démarrer la stack, par exemple en l'ajoutant à
  `lizmap/.env` ou en exécutant :
  ```bash
  LIZMAP_ENABLE_EXTRA_MODULES=1 docker compose up -d
  ```
  Puis parcourez WebDAV à l'adresse `http://localhost:8090/dav.php/`.

En coulisses, le point d'entrée du conteneur `lizmap` est encapsulé par
`lizmap.dir/etc/module-init.sh`. Quand `LIZMAP_ENABLE_EXTRA_MODULES=1`, il exécute
`composer install` sur `var/lizmap-my-packages` et configure tout module nouvellement installé
avant de démarrer Lizmap normalement. Ceci s'exécute à chaque démarrage du conteneur et ne fait
rien une fois que tout est déjà installé/configuré, donc cela n'ajoute aucun surcoût notable après
la première exécution. Quand la variable n'est pas définie, le script ne fait rien et Lizmap
démarre exactement comme avant.

Pour ajouter un autre module de la même manière, ajoutez-le à
`lizmap.dir/var/lizmap-my-packages/composer.json` (et mettez à jour `composer.lock`, par exemple
avec `docker compose exec lizmap composer update --working-dir=/www/lizmap/my-packages`) — il
sera installé et configuré automatiquement au prochain démarrage de la stack avec
`LIZMAP_ENABLE_EXTRA_MODULES=1`.

## Réinitialiser la configuration

En ligne de commande

```bash
./configure.sh  clean
```

Ceci supprimera toute la configuration précédente. Vous devrez ressaisir la configuration dans
Lizmap comme lors du premier lancement.

## Références

Pour plus d'informations, consultez la
[documentation docker-compose](https://docs.docker.com/compose/)

Voir aussi :

- https://github.com/3liz/lizmap-web-client
- https://github.com/3liz/py-qgis-server

Docker sous Windows :

- https://docs.docker.com/desktop/windows/
- https://docs.microsoft.com/fr-fr/windows/dev-environment/docker/overview
