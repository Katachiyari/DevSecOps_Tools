# Quand tu valides une version du CDC
git tag -a v1.0 -m "Cahier des charges initial validé"

# Quand tu ajoutes le portail Bulma
git tag -a v1.1 -m "CDC avec portail Bulma + Python"

# Pour revenir à une version
git checkout v1.0

# Tester une nouvelle version du portail
git checkout -b feature/portail-v2-bulma

# Si ça marche, merge dans main
git checkout main
git merge feature/portail-v2-bulma
git tag v1.2

