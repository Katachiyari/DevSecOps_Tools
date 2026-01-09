<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# Structuration de la Phase 1 en sprints (2 mois)

Hypothèse : **4 sprints de 2 semaines**.
Objectif Phase 1 : avoir un **socle K3s + SSO + CI/CD + gestion projet + com + Portail MVP** utilisable par l’équipe.

***

## Sprint 1 – Socle d’infra K3s + Ingress + DNS de base

**Objectifs principaux**

- Avoir un **cluster K3s fonctionnel**.
- Poser les bases réseau (namespaces, CNI, Ingress Traefik, cert-manager).
- Exposer une première appli “hello world” derrière Traefik (sans SSO, juste pour valider la chaîne).

**Livrables**

- Cluster K3s installé (3 masters + 1+ worker).
- Namespaces de base :
    - `tools`, `dev`, `test`, `prod`, `monitoring`, `security`.
- Traefik déployé comme Ingress Controller.
- cert-manager installé et **un certificat TLS valide** (Let’s Encrypt ou PKI interne).
- Une simple appli de test (page statique) accessible en HTTPS via Traefik (ex : `https://test.entreprise.local`).

**Tâches majeures**

- Installation K3s (HA minimal) et vérification du cluster.
- Mise en place CNI (Flannel/Calico).
- Création des namespaces.
- Déploiement Traefik + configuration d’un Ingress de test.
- Installation de cert-manager + configuration d’un Issuer/ClusterIssuer.
- Test d’obtention automatique d’un certificat TLS.
- Documentation rapide dans HedgeDoc : “Installation cluster \& Ingress”.

***

## Sprint 2 – SSO (Keycloak + Authelia) et gestion projet (Taiga)

**Objectifs principaux**

- Centraliser l’**authentification** (Keycloak).
- Mettre en place la **2FA** (Authelia) sur au moins un service.
- Offrir un premier outil métier : **Taiga** pour la gestion de projet.

**Livrables**

- Keycloak déployé dans `tools`, accessible en HTTPS.
- Realm “DevSecOps” créé, groupes et rôles de base définis (dev, ops, secops, pm, manager).
- Authelia déployé et relié à Traefik : **2FA opérationnelle** pour au moins une URL.
- Taiga déployé dans `tools`, SSO via Keycloak.
- 1 ou 2 projets Taiga créés pour suivre les tâches de mise en place de la plateforme.

**Tâches majeures**

- Déploiement Keycloak (base de données, stockage persistant).
- Configuration initiale : realm, clients, mappers, groupes, quelques comptes de test.
- Déploiement Authelia + configuration Traefik pour protéger une route de test (ex : `secure-test.entreprise.local`).
- Déploiement Taiga :
    - Base de données
    - Backend + frontend
    - Ingress via Traefik (HTTPS)
    - SSO via Keycloak (OIDC)
- Création des premiers projets/sprints dans Taiga pour la plateforme.
- Documenter : “SSO \& 2FA – Guide utilisateur” dans HedgeDoc.

***

## Sprint 3 – GitLab CE + Runners + Mattermost

**Objectifs principaux**

- Offrir un **Git central** + **CI/CD de base**.
- Ajouter la **communication d’équipe** (Mattermost).
- Intégrer ces outils au SSO.

**Livrables**

- GitLab CE déployé dans `tools`, accessible en HTTPS via Traefik.
- GitLab intégré à Keycloak (SSO).
- Runners GitLab **Kubernetes** opérationnels (au moins 1 runner).
- Mattermost déployé et intégré à Keycloak (SSO).
- Canal Mattermost “plateforme-devsecops” créé, notifications de base (pipelines ou messages de test).

**Tâches majeures**

- Déploiement GitLab (stockage persistant, backup logique prévu même simple).
- Intégration SSO (Keycloak en OIDC).
- Déploiement d’un runner GitLab dans K3s (namespace `tools`).
- Création d’un projet Git “infrastructure” (manifests K8s, docs, etc.).
- Déploiement Mattermost (DB, app) + Ingress Traefik.
- SSO Keycloak pour Mattermost.
- Création des canaux :
    - `#general`, `#plateforme-devsecops`, `#incidents` (même si vide au début).
- Documentation :
    - “Créer un compte/connexion via SSO”
    - “Créer un repo GitLab et un premier pipeline simple” (sans code, juste conceptuellement).

***

## Sprint 4 – Portail unifié MVP (Bulma + Python) + Intégrations minimales

**Objectifs principaux**

- Mettre en place la **première version du portail unifié**.
- Y intégrer les liens essentiels + un premier widget “Mes tâches Taiga”.
- Avoir un parcours utilisateur fluide : **une URL → SSO → accès aux outils clés**.

**Livrables**

- Portail DevSecOps déployé dans `tools` :
    - Backend Python (FastAPI ou Flask) minimal.
    - Frontend avec Bulma (layout propre, responsive).
    - Ingress Traefik (`https://devops.entreprise.local`).
- SSO via Keycloak + 2FA via Authelia pour le portail.
- Page d’accueil avec :
    - Tuiles vers : GitLab, Taiga, Mattermost (au minimum).
    - Widget “Mes tâches Taiga” simple (liste des tâches assignées à l’utilisateur).
- Monitoring de base du portail (métriques + logs intégrés).

**Tâches majeures**

- Concevoir la structure du portail :
    - 1 page principale (dashboard),
    - 1 endpoint API pour récupérer les tâches Taiga.
- Intégration SSO Keycloak côté backend (validation du token).
- Intégration CSS Bulma pour un look moderne (navbar, cards, grille).
- Intégration API Taiga : récupérer tâches de l’utilisateur connecté.
- Déploiement du conteneur Python (base DHI `python:3.12-slim`).
- Exposition via Traefik + protection Authelia (2FA).
- Ajout au Monitoring existant (logs envoyés vers Loki, metrics Prometheus basiques si déjà là, ou au moins readiness/liveness).

***

## En résumé : objectif de fin de Phase 1

À la fin de ces **4 sprints (≈ 2 mois)**, tu dois avoir :

- Un **cluster K3s** stable avec Ingress, TLS, namespaces.
- Un **SSO central** (Keycloak) + **2FA** (Authelia) fonctionnels.
- Les outils de base :
    - GitLab CE + runners K8s,
    - Taiga,
    - Mattermost.
- Un **Portail DevSecOps MVP** :
    - Authentifié via SSO + 2FA,
    - Liens vers les outils,
    - Affichage des tâches Taiga.

C’est un socle très solide pour ensuite ajouter en Phase 2 :

- Harbor, Trivy, Falco, OPA/Kyverno, Prometheus/Grafana, Loki, etc.

Si tu veux, la prochaine étape peut être :

- écrire les **user stories** détaillées de chaque sprint (en français, format Taiga),
- ou transformer ce plan en **roadmap Gantt simplifiée**.

