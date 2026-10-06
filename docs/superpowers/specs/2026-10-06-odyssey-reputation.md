# Odyssey — barre de réputation

Date : 2026-10-06 · Statut : validé en conversation

- Deuxième barre **indépendante** (position, taille, textes, visibilité, apparence), même composant de barre que l'XP, nouvelle source de données « réputation ».
- Faction suivie = celle cochée « Afficher comme barre d'expérience » dans le jeu (API classique `GetWatchedFactionInfo` ou moderne `C_Reputation.GetWatchedFactionData`, testées à l'exécution, ajoutées à la sonde).
- Données : faction, palier (nom traduit par le jeu), actuel / max du palier, %, restant avant le palier suivant, restant avant Exalté ; session : réputation gagnée, par heure, temps avant le palier suivant, dernier gain.
- Textes au choix : faction, palier, actuel / max, actuel / max (%), %, restant, restant avant Exalté, réputation / heure, aucun.
- Tooltip Minimal : par défaut faction, palier, progression, restant ; avec Maj : avant Exalté, session, par heure, temps avant le palier, dernier gain.
- Sans faction suivie : masquée ou « Aucune faction suivie » (réglage). Case « Afficher la barre de réputation ».
- Couleur du remplissage : couleur du palier (défaut, couleurs du jeu `FACTION_BAR_COLORS`) ou palette.
- Réglages indépendants rangés sous `settings.rep`, valeurs par défaut = celles de l'XP (position sous la barre d'XP). Case « Même style que la barre d'XP » : cochée, l'apparence (texture, coins, bordure, effets, polices, palette, couleurs, tooltip) suit la barre d'XP en direct et ses réglages sont grisés ; décochée, elle repart du style de l'XP puis se règle librement.
- Fenêtre Odyssey : sélecteur « Barre d'XP / Barre de réputation » en haut ; les sections s'appliquent à la barre choisie ; l'aperçu montre cette barre.
- Tests hors jeu : source avec fausse API, textes, tooltip, réglages liés, migration ; en jeu : barre, fenêtre.
