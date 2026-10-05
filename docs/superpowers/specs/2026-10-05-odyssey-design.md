# Odyssey — design

Date : 2026-10-05
Statut : en attente de relecture
Nom : **Odyssey** (sous-titre CurseForge : « Odyssey – XP bar & leveling tracker »)
Commande slash : `/odyssey`

## 1. Intention

**Ce que veut l'auteur·e**
- Un addon de barre d'XP pour le nouveau client **World of Warcraft: Forever** (Classic, beta, version 1.60.1, interface `16001`).
- Une barre **plus jolie** que celle de Blizzard.
- Des infos en plus : XP totale du niveau, déjà faite, restante, `/played`, et d'autres à choisir.
- Publication possible sur **CurseForge**, code sur un dépôt **GitHub public**.

**Critère de réussite** : en jeu, une barre d'XP au style soigné affiche ces infos (texte court sur la barre, détail au survol), sans erreur Lua, et l'addon se package et se publie proprement.

**Hypothèses retenues**
- Pas de dépendance à d'autres addons.
- Tout repose sur l'API Lua standard ; chaque fonction non garantie est vérifiée avant usage (voir §10).
- La publication CurseForge est possible : le client « Forever 1.60.1 » est proposé dans l'app CurseForge.

## 2. Positionnement (différenciant)

Des addons existants font déjà : XP, repos, mobs/kills avant le niveau, temps de session, ETA, XP des quêtes terminées, plusieurs styles (MyXPBar Forever, Easy Experience Bar, ForeverXPBar…). Avoir toutes les infos ne suffit donc pas. Odyssey se distingue par quatre axes :

1. **Historique de leveling** : temps et rythme (XP/h) enregistrés pour chaque niveau, comparés dans le tooltip avec une mini-courbe.
2. **Détail des quêtes** : liste quête par quête de l'XP à rendre, avec le pourcentage de barre de chacune.
3. **Identité visuelle soignée** : peu de styles, très travaillés, thèmes cohérents.
4. **Famille de barres** : l'architecture est générique ; la **réputation** est la prochaine barre (hors version 1).

## 3. Périmètre

**Version 1**
- Barre d'XP (axes 1 à 3 ci-dessus).
- Tooltip complet, réglages, localisation FR/EN, packaging CurseForge.

**Hors version 1 (prévu ensuite)** : barre de réputation (même composant de barre, nouvelle source de données `Sources/Reputation.lua`).

**Non-objectifs** : honneur, XP des familiers, intégrations tierces (LDB, Titan Panel), synchronisation entre comptes.

## 4. Architecture

```
Odyssey/
  Odyssey.toc          ## Interface: 16001, version, SavedVariables: OdysseyDB
  Core.lua             init, dispatch des événements, réglages, commande slash
  Calc.lua             calculs purs, sans API du jeu (XP/h, ETA, kills, formats, comparaisons)
  Sources/XP.lua       source de données XP : écoute les événements, produit un instantané
  History.lua          historique de leveling (enregistrement, comparaison)
  Bar.lua              composant de barre générique (reçoit une source)
  Tooltip.lua          construction du tooltip à partir de l'instantané
  Options.lua          panneau de réglages
  Locales/enUS.lua     Locales/frFR.lua
  Media/               textures propres à l'addon
LICENSE (MIT) · README.md · CHANGELOG.md · .pkgmeta
tests/                 tests de Calc.lua et History.lua (luajit)
```

**Flux** : événement du jeu → la source met à jour son instantané → la barre se rafraîchit ; le tooltip lit le même instantané. La barre ne connaît que l'interface « source » : `Get()` renvoie l'instantané, `Subscribe(fn)` notifie les changements. Ajouter la réputation = écrire une nouvelle source.

## 5. Données (`Sources/XP.lua`, `Calc.lua`)

Instantané fourni par la source XP :
- **XP** : actuelle, maximale, restante, pourcentage ; niveau ; `isMaxLevel`.
- **Repos** : XP de repos et part de la barre qu'il couvre.
- **Session** : XP gagnée depuis la connexion, durée, XP/h, temps estimé avant le level up (affiché seulement après un minimum de données).
- **Kills restants** : XP restante divisée par l'XP du dernier kill. Le dernier gain est mesuré par la variation d'XP, sans lire le texte du chat (indépendant de la langue).
- **`/played`** : `RequestTimePlayed()` à la connexion et à chaque level up ; réponse via `TIME_PLAYED_MSG` ; le compteur avance localement entre deux réponses. Les réponses automatiques n'apparaissent pas dans le chat ; le `/played` manuel s'affiche toujours. Calcul du temps à ce niveau et du temps moyen par niveau.
- **Quêtes à rendre** : liste des quêtes terminées du journal avec la récompense d'XP de chacune ; somme, et pourcentage de barre qu'elle représente.

Événements : changement d'XP, level up, changement du repos, connexion, réponse `/played`, mise à jour du journal de quêtes.

## 6. Historique de leveling (`History.lua`)

- Par personnage (clé royaume-nom), dans `OdysseyDB`.
- À chaque level up, on relève le temps joué total fourni par `/played`. Le temps passé à un niveau = différence entre deux level ups consécutifs. On enregistre : niveau, durée, XP du niveau, XP/h moyen, date.
- L'historique commence à l'installation : les niveaux précédents sont inconnus et ne sont pas inventés.
- Le tooltip affiche : rythme actuel (XP/h) comparé à la moyenne des niveaux déjà enregistrés (« +18 % »), et une mini-courbe des derniers niveaux (barres de hauteur proportionnelle à la durée). Sans historique, le bloc est masqué.
- Option pour effacer l'historique d'un personnage.

## 7. Barre (`Bar.lua`)

- Cadre indépendant, **déplaçable par simple glisser quand il est déverrouillé** (pas de Shift) ; verrouillé, il ne bouge plus. Largeur, hauteur et échelle réglables ; position sauvegardée par personnage ou pour le compte.
- **Trois couches** : XP actuelle, segment de repos (bleu) qui prolonge le remplissage, segment des quêtes à rendre (doré translucide). Étincelle au bout, déplacement fluide du remplissage.
- **Styles** : quelques styles prédéfinis très soignés (par exemple Plat, Dégradé, Brillant) et thèmes de couleur (classe, faction, minimaliste). Textures propres à l'addon, aucun fichier Blizzard copié.
- **Texte sur la barre** : trois emplacements (gauche, centre, droite), chacun au choix parmi : pourcentage, `actuel / max`, restant, repos, XP/h, temps avant level up, kills restants, quêtes à rendre, niveau, rien. Défaut : niveau / `actuel / max (pourcentage)` / repos.
- Au niveau maximum : la barre se masque ou affiche un texte adapté (option).
- Barre Blizzard : masquée par défaut, case pour la réafficher ; masquage sans remplacer les fonctions de Blizzard.
- Clic droit : ouvre les réglages. Survol : tooltip.

## 8. Tooltip (`Tooltip.lua`)

Blocs, chacun masqué si sa donnée est indisponible et désactivable dans les réglages :
- **Niveau** : total, fait (avec %), restant.
- **Repos** : valeur et part de la barre.
- **Quêtes à rendre** : somme et pourcentage, puis les quêtes une par une (les plus rentables d'abord, limitées à un nombre raisonnable avec « … et N autres »).
- **Session** : XP gagnée, durée, XP/h, temps avant level up.
- **Kills restants** : nombre approximatif, avec l'XP du dernier kill.
- **Temps joué** : total, à ce niveau, moyenne par niveau.
- **Historique** : rythme comparé et mini-courbe (§6).

Nombres formatés selon la langue, option de format abrégé (`12,3k`).

## 9. Réglages et sauvegarde (`Options.lua`, `Core.lua`)

- Panneau dans les options des addons, ouvert aussi par clic droit sur la barre et par `/odyssey`.
- Contenu : verrouiller, taille/échelle, style et couleurs, trois emplacements de texte, barre Blizzard, blocs du tooltip, format des nombres, effacer l'historique, réinitialiser la session.
- `OdysseyDB` fusionnée avec les valeurs par défaut au chargement (les nouveaux réglages n'écrasent pas les anciens) ; numéro de version des données pour les migrations futures.
- Position et apparence au choix par personnage ou pour le compte. Les statistiques de session ne sont pas sauvegardées.

## 10. Gestion des erreurs et points à vérifier en jeu

- Toute fonction du jeu non garantie sur ce client est testée avant usage ; si elle manque, la fonctionnalité concernée est désactivée en silence, et `/odyssey debug` en donne la raison.
- Protection contre les divisions par zéro, le niveau maximum et les données pas encore reçues.
- Aucun cadre protégé : pas de taint, aucun risque en combat.

**À vérifier sur le client** (les fichiers de l'interface Blizzard ne sont pas sur le disque, la vérification se fait en jeu) :
- Noms et comportements des API : XP, repos, journal de quêtes (récompense d'XP d'une quête), `RequestTimePlayed`.
- Façon de masquer la barre d'XP native sur ce client.
- API du panneau d'options.
- Format des textures acceptés (TGA/BLP, tailles).

## 11. Tests

- **Hors jeu** : `Calc.lua` et `History.lua` n'utilisent aucune API du jeu et sont testés avec `luajit` (assertions simples), tests écrits avant le code. `luac -p` sur tous les fichiers pour la syntaxe.
- **En jeu** : `/reload` avec les erreurs Lua activées, puis liste de vérifications : XP, repos, level up, quêtes, `/played`, historique, déplacement, réglages, FR/EN.

## 12. Localisation

`enUS` (référence, valeur par défaut) et `frFR`. Toute chaîne visible passe par une table de locale ; une clé manquante retombe sur l'anglais.

## 13. Distribution

- **Dépôt GitHub public** `Odyssey`, licence **MIT**, sans fichier Blizzard (textures ou code de l'interface).
- **`.pkgmeta`** et publication via le packager BigWigs (GitHub Actions) à chaque tag de version, avec l'identifiant de projet CurseForge dans le `.toc`.
- Numéro de version dans le `.toc` géré par le packager.
- La création du dépôt et du projet CurseForge sera faite sur accord explicite, après l'implémentation.
- Page CurseForge : sous-titre « XP bar & leveling tracker », captures d'écran, description FR/EN.
