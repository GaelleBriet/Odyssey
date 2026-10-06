# Odyssey — personnalisation complète (v3 des réglages)

Date : 2026-10-06
Statut : validé en conversation (« tout » + menus déroulants + visibilité au survol)
S'appuie sur : `2026-10-05-odyssey-design.md` et `2026-10-05-odyssey-design-pass.md` (remplace leur §2.1 « styles » et §5 « réglages »)

## 1. Intention

Retour après la passe design : le style Lisse plaît mais sans arrondi ; on ne peut plus choisir le « type de barre » (plat, dégradé…) ; il manque encore des options ; naviguer par clic gauche/droit n'est pas pratique ; il faut pouvoir n'afficher la barre qu'au survol.

**Critère de réussite** : chaque aspect visuel listé ci-dessous se règle indépendamment depuis des listes déroulantes et des cases à cocher, l'effet est immédiat, les réglages v2 sont convertis sans perte, aucune erreur Lua.

**Sonde du 2026-10-06** : `CreateMaskTexture`, `CreateColor`, `LibStub`, `IsShiftKeyDown`, `UISpecialFrames` présents.

## 2. Barre : réglages indépendants

| Réglage | Valeurs |
|---|---|
| `texture` | `flat`, `gradient`, `glossy`, `smooth` (textures d'Odyssey) + noms des textures `statusbar` de LibSharedMedia |
| `corners` | `square`, `rounded` |
| `border` | `none`, `thin` (1 px), `thick` (2 px) |
| `borderColor` | `palette`, `black`, `gold` |
| `bgOpacity` | 0, 0.25, 0.5, 0.75, 0.9, 1 |
| `gloss`, `shadow`, `glow`, `spark` | booléens |
| `ticks` | 0 (aucune), 10 (tous les 10 %), 20 (tous les 5 %) |
| `textPosition` | `inside`, `above`, `below` |
| `visibility` | `always`, `mouseover` |
| `fadedAlpha` | opacité hors survol : 0, 0.15, 0.3, 0.5 |

- **Préréglages** (ex-styles) : `smooth`, `segmented`, `neon`, `thin`. Choisir un préréglage écrit d'un coup texture, coins, bordure, effets, position du texte et hauteur ; on ajuste ensuite. Le préréglage n'est pas mémorisé comme un réglage.
- La texture choisie reçoit le dégradé horizontal de la couleur de remplissage ; une texture introuvable (addon désinstallé) revient à `smooth`.
- **Au survol** : la barre est à `fadedAlpha` et passe à 1 quand la souris la survole, pendant un déplacement et tant que son tooltip est ouvert ; transition courte.

## 3. Couleurs

- La palette (11) donne toutes les couleurs.
- Remplacement par élément : `fill`, `rested`, `quest`, `bg`, `border`, `text`, choisis avec la roue de couleurs du jeu (`ColorPickerFrame`, API moderne `SetupColorPickerAndShow` ou ancienne selon le client). Un remplacement de `fill` donne un dégradé de 75 % à 100 % de la couleur choisie.
- Bouton « Revenir aux couleurs de la palette » : efface tous les remplacements.

## 4. Tooltip

`tooltipBgOpacity` (0.5 → 1), `tooltipScale` (0.8 → 1.3), `tooltipAnchor` (`bar` : au-dessus/au-dessous de la barre ; `cursor` : près de la souris). Le reste (Minimal, Maj, blocs) est inchangé.

## 5. Réglages : panneau à onglets, sans clic gauche/droit

- Onglets : **Barre**, **Couleurs**, **Textes**, **Tooltip** (plus une ligne d'actions : réinitialiser la session, effacer l'historique).
- Toute option à plusieurs valeurs = **liste déroulante** (le composant de la passe design, généralisé : textes simples, polices dans leur police, textures en aperçu) ; toute option on/off = **case à cocher** ; couleurs = **pastille** qui ouvre la roue de couleurs, avec un petit bouton pour revenir à la couleur de la palette.

## 6. Données

`OdysseyDB` version 3 : `style` v2 → réglages du préréglage correspondant (et `style` supprimé) ; nouvelles clés par défaut via la fusion ; `colors = {}` (remplacements). Une valeur v2 de `height` est conservée.

## 7. Tests

Hors jeu : définitions des préréglages et des textures, application d'un préréglage, migration v2 → v3, résolution des textures (Odyssey, LibSharedMedia, inconnue), calcul des couleurs effectives (palette + remplacements), alpha de visibilité (toujours, survol, déplacement, tooltip ouvert), contenu des listes déroulantes. En jeu : panneau à onglets, roue de couleurs, survol, textures LibSharedMedia.

## 8. Hors périmètre

Profils nommés, import/export, barre de réputation.
