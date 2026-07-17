# Publier votre propre projet QGIS sur votre Lizmap en ligne

[🇬🇧 Read this in English](PUBLISH.md)

Ce guide concerne l'instance de test [GitHub Codespaces](README.fr.md#-essayer-lizmap-en-ligne-en-un-clic-sans-installation)
en un clic. Il explique comment créer un projet QGIS sur votre ordinateur et le publier sur
*votre* Lizmap en ligne, y compris dans le cas où vos données se trouvent dans la base PostGIS
embarquée.

Votre Codespace embarque un dépôt **My projects** vide, prêt à recevoir votre projet.

## Prérequis (sur votre ordinateur)

- [QGIS Desktop](https://qgis.org) avec le plugin **Lizmap** installé.
- [VS Code Desktop](https://code.visualstudio.com/download) (gratuit). Une fois votre Codespace
  ouvert dans le navigateur, cliquez sur **Open in VS Code Desktop** (menu en haut à gauche, ou le
  bouton vert « Code » sur le dépôt). Connectez-vous avec votre compte GitHub lorsque demandé —
  pas de mot de passe séparé, pas de ligne de commande.

  *Vous préférez le terminal ?* Tout ce qui suit (envoi de fichiers, accès à PostGIS) fonctionne
  également avec la [CLI GitHub](https://cli.github.com) (`gh`) à la place de VS Code Desktop —
  voir les astuces à la fin de chaque étape.

## Étape 1 — Rendre vos données accessibles au serveur

### Option A — données basées sur des fichiers (le plus simple)
Si vos couches sont dans un **GeoPackage** (ou un Shapefile…), conservez simplement le fichier de
données dans le **même dossier** que votre `.qgs` et utilisez des **chemins relatifs** dans QGIS.
Rien d'autre à faire — QGIS Server lit le fichier directement. Passez à l'étape 2.

### Option B — données dans PostGIS
La stack exécute déjà une base PostGIS ; QGIS Server la lit via le pg_service nommé
**`lizmap_local`**. L'astuce consiste à utiliser ce **même nom de service** sur votre poste, afin
que le `.qgs` exact fonctionne sur votre machine *et* sur le serveur sans aucune modification.

1. **Ouvrez un tunnel** vers la base de données du Codespace. Dans VS Code Desktop, ouvrez l'onglet
   **Ports** (panneau du bas) → **Forward a Port** → tapez `8093` → Entrée. PostGIS est maintenant
   accessible sur `localhost:8093` sur votre machine — pas de popup, pas d'installation
   supplémentaire, ça fonctionne simplement car VS Code Desktop redirige les ports vers votre vrai
   `localhost`.

   > 💡 Les connexions brutes à la base de données ne fonctionnent que via un outil de bureau (VS
   > Code Desktop ci-dessus, ou `gh codespace ports forward 8093:8093` dans un terminal — le
   > format est `<port-distant>:<port-local>`, donc les deux côtés doivent être `8093` pour
   > correspondre au `pg_service.conf` ci-dessous) — l'URL publique du port
   > `https://...app.github.dev` ne fait que du proxy HTTP(S) et ne peut pas transporter le
   > protocole Postgres.

2. **Déclarez le service `lizmap_local`** sur votre ordinateur. Ajoutez ceci à votre fichier
   pg_service (`~/.pg_service.conf` sur Linux/macOS, `%APPDATA%\postgresql\.pg_service.conf` sur
   Windows) :
   ```ini
   [lizmap_local]
   host=localhost
   port=8093
   dbname=lizmap
   user=lizmap
   password=lizmap1234!
   ```

3. Dans QGIS → **Gestionnaire de sources de données → PostgreSQL → Nouvelle**, réglez
   **Service = `lizmap_local`** (laissez Hôte/Port vides) et *testez la connexion*. Utiliser le
   champ Service est ce qui fait écrire à QGIS `service='lizmap_local'` dans le projet plutôt
   qu'un hôte codé en dur — essentiel pour que le projet se résolve sur le serveur.

4. **Chargez vos données** dans la base (schéma `lizmap`, ou créez le vôtre). Par exemple avec le
   *Gestionnaire de base de données* de QGIS (Importer une couche), ou depuis un terminal :
   ```bash
   ogr2ogr -f PostgreSQL "PG:service=lizmap_local" my_data.gpkg -lco SCHEMA=lizmap
   ```

5. Construisez votre carte dans QGIS à partir de ces couches PostGIS. Vérifiez (couche →
   Propriétés → Source) que la source de données commence bien par `service='lizmap_local'`.

## Étape 2 — Configurer la carte avec le plugin Lizmap

Dans QGIS, ouvrez le plugin **Lizmap**, configurez votre carte (couches de fond, popups,
outils…), et cliquez sur **Enregistrer**. Cela écrit un fichier `monprojet.qgs.cfg` à côté de
votre `monprojet.qgs`.

## Étape 3 — Envoyer le projet à votre Codespace

Copiez les fichiers du projet (et les fichiers GeoPackage / de données si vous avez utilisé
l'option A) dans le dossier du dépôt **My projects** du Codespace :
`lizmap/instances/myprojects/`.

Dans VS Code Desktop (ou l'éditeur du navigateur), ouvrez l'**Explorateur**, trouvez ce dossier,
et soit **glissez-déposez** vos fichiers dessus, soit faites un clic droit dessus →
**Upload...** et choisissez les fichiers. Aucun outil supplémentaire nécessaire.

> 💡 Alternative en terminal : `gh codespace cp ./monprojet.qgs ./monprojet.qgs.cfg
> 'remote:/workspaces/lizmap-docker-compose/lizmap/instances/myprojects/'`

## Étape 4 — Ouvrir le projet

Allez sur votre URL Lizmap — le dépôt **My projects** liste maintenant `monprojet`. 🎉

---

### Remarques et dépannage
- **Projet non listé / erreur « repository path »** : le fichier doit être directement sous
  `lizmap/instances/myprojects/` et nommé `*.qgs` avec son `*.qgs.cfg` à côté.
- **Les couches ne se chargent pas sur le serveur mais fonctionnent en local** : la source de
  données est probablement codée en dur avec `localhost:8093` au lieu de
  `service='lizmap_local'`. Recréez la connexion PostGIS en utilisant le champ **Service**
  (étape 1B.3) et réenregistrez le projet.
- **Visibilité** : *My projects* est visible par les visiteurs anonymes par défaut (comme les
  démos), vous pouvez donc partager le lien de la carte. Changez cela dans **Admin → Maps** si
  vous préférez qu'il reste privé.
- **Durée de vie** : tout (fichiers et données PostGIS) réside dans votre Codespace et est
  supprimé quand le Codespace est supprimé. Cette instance est destinée à l'évaluation, pas à la
  production.
