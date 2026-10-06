# Odyssey — passe design (barre, palettes, polices, tooltip)

Date : 2026-10-05
Statut : en attente de relecture
S'appuie sur : `docs/superpowers/specs/2026-10-05-odyssey-design.md` (v1 fonctionnelle, inchangée sauf mention contraire)

## 1. Intention

**Retour de l'utilisatrice après essai en jeu de la v1**
- La barre « n'est pas assez belle » ; il faut plus de choix de couleurs et de polices.
- Le tooltip a trop le style de base de Blizzard et est « un peu chargé à lire ».

**Choix faits pendant la conception** (maquettes validées dans le navigateur)
- Couleurs : des palettes prêtes à l'emploi (pas de sélecteur libre) — les 11 proposées sont toutes retenues.
- Styles de barre : Lisse arrondie, Segmentée, Néon, Ligne fine (le style « Ornée » est écarté).
- Polices : celles du jeu + quelques polices libres intégrées + celles des autres addons via LibSharedMedia.
- Tooltip : style « Minimal » (B), cadre propre à Odyssey, détail sur Maj.

**Critère de réussite** : en jeu, chaque style et chaque palette s'appliquent immédiatement depuis les réglages ; on peut choisir la police de la barre et celle du tooltip parmi toutes les polices disponibles ; le tooltip par défaut tient en trois groupes lisibles, le détail apparaît avec Maj ; aucune erreur Lua.

## 2. Barre

### 2.1 Styles (remplacent Plat, Dégradé, Brillant)

| Clé | Nom | Description |
|---|---|---|
| `smooth` | Lisse arrondie | Coins arrondis, reflet doux sur la moitié haute, ombre portée. |
| `segmented` | Segmentée | Graduations sombres tous les 10 %, bords droits. |
| `neon` | Néon | Barre fine (hauteur par défaut réduite), halo lumineux autour du remplissage. |
| `thin` | Ligne fine | Barre de 4 px ; les trois textes sont placés au-dessus de la barre. |

- Style par défaut : `smooth`. Un ancien réglage (`flat`, `gradient`, `glossy`) est converti en `smooth` au chargement.
- Chaque style déclare : textures (remplissage, fond), masque/coins, présence du reflet, des graduations, du halo, épaisseur de bordure, position des textes (`inside` ou `above`), hauteur conseillée.
- Les trois couches existantes (XP, repos, quêtes à rendre) et l'étincelle restent ; l'étincelle est désactivée pour `thin`.
- Textures générées par `tools/make_textures.py` (TGA 32 bits, puissances de 2), aucune texture Blizzard copiée.

### 2.2 Palettes (remplacent les 4 thèmes)

11 palettes : Arcane (défaut, l'actuelle), Or royal, Émeraude, Givre, Braise, Rose crépuscule, Nuit étoilée, Gangrène, Monochrome, Couleur de classe, Faction.

- Chaque palette définit : `fill` (début et fin du dégradé), `rested`, `quest`, `bg`, `border`, `accent`, `text`.
- Couleur de classe : `fill` = couleur de la classe du personnage. Faction : rouge Horde / bleu Alliance.
- Un ancien thème est converti : `classic` → `arcane`, `class` → `class`, `faction` → `faction`, `minimal` → `monochrome`.

## 3. Polices

- Sources, dans cet ordre dans la liste :
  1. Polices du jeu : Friz Quadrata, Arial Narrow, Skurri, Morpheus.
  2. Polices intégrées à l'addon (licence SIL OFL, fichier de licence inclus dans `Media/Fonts/`) : Nunito, Barlow Condensed, Cinzel, Inter.
  3. Polices de LibSharedMedia-3.0 **si une bibliothèque est déjà chargée par un autre addon** (`LibStub("LibSharedMedia-3.0", true)`). Odyssey n'embarque pas la bibliothèque et n'en dépend pas ; si elle est présente, Odyssey y enregistre aussi ses polices intégrées.
- Réglages séparés pour la barre et pour le tooltip : police, taille, contour (aucun, fin, épais).
- La police est enregistrée par son **nom** ; si elle n'existe plus (addon désinstallé), retour silencieux à la police par défaut.
- Toutes les polices proposées doivent afficher les accents français.

## 4. Tooltip « Minimal »

- Cadre propre à Odyssey (plus `GameTooltip`) : fond sombre semi-opaque, filet vertical à gauche dans la couleur `accent` de la palette, marges internes, libellés en couleur atténuée et valeurs en gras à droite.
- **Vue par défaut**, trois groupes séparés par un trait fin :
  1. Progression (%), Restant, Repos, Quêtes à rendre (somme).
  2. XP par heure, Level up dans.
  3. Temps joué.
- **Maj enfoncé** : la vue détaillée ajoute la liste des quêtes (avec XP), les kills restants et le dernier gain, la session (XP gagnée, durée), le temps à ce niveau et la moyenne par niveau, l'historique (rythme comparé, une barre par niveau).
- Une ligne sans donnée n'est pas affichée ; un groupe vide n'est pas affiché (ni son séparateur).
- Les cases « Tooltip : … » des réglages restent valables et s'appliquent aux deux vues.
- Le tooltip suit la souris au-dessus/au-dessous de la barre selon la place à l'écran, se met à jour chaque seconde, et réagit à l'appui/relâche de Maj.
- Le contenu (liste ordonnée de groupes et de lignes) est produit par une fonction pure testée hors du jeu ; le dessin du cadre est séparé.

## 5. Réglages

- Nouveau contrôle **liste déroulante maison** (pas de modèle Blizzard) : un bouton affiche la valeur ; un clic ouvre une petite fenêtre avec une liste défilante ; chaque police y est écrite dans sa propre police ; Échap ou clic ailleurs ferme.
- Utilisé pour : style, palette, police de la barre, police du tooltip. Les autres réglages restent des boutons à valeurs cycliques.
- Nouveaux réglages : police/taille/contour de la barre, police/taille/contour du tooltip.

## 6. Données sauvegardées

- `OdysseyDB` version 2 : migration des anciennes clés de style et de thème (§2) ; nouvelles clés avec valeurs par défaut via la fusion existante.

## 7. Tests

- Hors jeu (luajit) : définitions des styles et palettes complètes, conversions des anciennes valeurs, résolution des polices (nom connu, inconnu, source LibSharedMedia absente ou présente via un faux `LibStub`), contenu du tooltip par groupes (vue par défaut, vue détaillée, lignes et groupes vides masqués, cases désactivées).
- En jeu : chaque style × quelques palettes, polices du jeu / intégrées / LibSharedMedia, tooltip normal et avec Maj, liste déroulante.

## 8. Hors périmètre

Sélecteur de couleur libre, style « Ornée », barre de réputation (prochaine étape), animations supplémentaires.
