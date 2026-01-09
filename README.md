# 🏗️ Plateforme DevSecOps K3s

## Vue d'ensemble
Plateforme auto-hébergée pour 20-30 ingénieurs.
- K3s (Kubernetes allégé)
- Keycloak (SSO) + Authelia (2FA)
- GitLab (CI/CD) + Taiga (gestion projet) + Mattermost (chat)
- Portail DevSecOps (Bulma + Python)

## Phases
- **Phase 1 (2 mois)** : MVP (K3s, SSO, CI/CD, portail)
- **Phase 2 (1 mois)** : Sécurité (Harbor, Falco, OPA)
- **Phase 3 (1 mois)** : Monitoring & Backup (Prometheus, Loki, Velero)

## Démarrer
```bash
make help

## Conventions (FR/EN)

- Tout fichier d'automatisation (Vagrantfile, Ansible, scripts) doit être commenté en **FR + EN**.
- Commentaires :
  - Impersonnels (aucun “je/nous”).
  - Techniques et synthétiques (objectif, prérequis, effet).
- Toute étape validée doit mettre à jour la documentation dans `docs/guides/`.
- Les images conteneurs devront utiliser **Docker Hardened Images (DHI)** comme bases lorsque des Dockerfiles seront introduits. [page:0]
