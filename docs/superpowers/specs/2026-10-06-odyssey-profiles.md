# Odyssey — profils

Date : 2026-10-06 · Statut : validé en conversation (profils « vivants »)

- `OdysseyDB` v4 : `profiles = { [nom] = réglages complets (XP + réputation) }`, `profileKeys = { [personnage] = nom }`, `defaultProfile`.
- Chaque personnage utilise un profil (par défaut « Défaut ») ; les réglages modifient le profil actif.
- Migration v3 → v4 : `account` devient « Défaut » ; si « réglages par personnage » était actif, chaque personnage ayant ses réglages reçoit le profil « Personnage - Royaume » et l'utilise ; la case disparaît.
- Actions : choisir le profil actif, créer (depuis l'actuel ou les valeurs par défaut), copier depuis un autre profil, renommer, réinitialiser, supprimer un autre profil.
- Garde-fous : pas de suppression du profil actif ni du dernier ; les personnages d'un profil supprimé repassent sur le profil par défaut ; nom vide ou déjà pris refusé.
- Fenêtre : section « Profils » (profil actif ; gérer) avec champ de saisie et confirmation en deux clics pour supprimer et réinitialiser.
