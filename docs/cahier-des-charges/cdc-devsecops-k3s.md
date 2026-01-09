# Cahier des charges – Plateforme DevSecOps (K3s) avec portail unifié

## 1. Contexte et objectifs

L’objectif est de mettre en place une **plateforme DevSecOps intégrée**, auto‑hébergée sur **K3s** (Kubernetes léger), pour une entreprise d’environ **20–30 ingénieurs** (développeurs, DevOps, chefs de projet, profils sécurité, management).

La plateforme doit :

- Centraliser le **code**, les **builds**, les **déploiements**, la **supervision**, la **sécurité** et la **collaboration**.
- Offrir un **portail unique d’accès** aux outils (SSO + 2FA).
- Appliquer les principes **DevSecOps** : sécurité intégrée de bout en bout (code, images, pipeline, déploiement, runtime, sauvegardes).
- Rester **pragmatique et raisonnablement simple**, sans “grosse ingénierie” surdimensionnée.

Les choix validés sont :

- Orchestration : **K3s** (Kubernetes allégé) au lieu de Docker Swarm.
- Registry : **GitLab CE + Harbor** (Harbor pour les images et la sécurité, GitLab pour le code/CI/CD, éventuellement registry GitLab si besoin ponctuel).
- Sauvegardes : **Velero** (adapté à Kubernetes) + stockage persistant Longhorn.
- Calendrier : utilisation des fonctionnalités de **Taiga** et des **plugins Mattermost** (pas de FullCalendar dédié).
- Authentification : **Keycloak** pour SSO, **Authelia** pour 2FA.
- Images Docker : uniquement des bases **DHI (Docker Hub Official Images)** comme sources d’images.

---

## 2. Périmètre fonctionnel

### 2.1 Profils utilisateurs

- **Développeurs**
  - Gérer le code source (branches, merge requests) dans GitLab.
  - Lancer et suivre les pipelines CI/CD.
  - Accéder aux logs applicatifs et métriques de leurs applications.
  - Consulter et mettre à jour les tâches dans Taiga.
  - Consulter et enrichir la documentation dans HedgeDoc.

- **DevOps / Ops**
  - Administrer le cluster K3s (nœuds, pods, services, stockage).
  - Superviser les métriques, logs et alertes (Prometheus, Grafana, Loki, Alertmanager, Uptime Kuma).
  - Gérer la configuration de Traefik, cert-manager, DNS, NetworkPolicies.
  - Gérer les secrets (Vault) et les accès techniques.
  - Mettre en œuvre et tester les sauvegardes/restaurations (Velero).
  - Gérer les déploiements GitOps via ArgoCD.

- **SecOps / RSSI**
  - Définir une politique d’images (uniquement DHI, scans Trivy obligatoires).
  - Exiger et vérifier l’activation de la 2FA.
  - Auditer les accès (Keycloak, Authelia, GitLab, Harbor, ArgoCD).
  - Surveiller les alertes **Falco** (sécurité runtime).
  - Valider les policies OPA/Kyverno (admission control) et les NetworkPolicies.

- **Chefs de projet / Product Owners**
  - Gérer backlog, sprints et tâches dans Taiga.
  - Suivre l’avancement des équipes (burndown, Kanban).
  - Voir les documents de référence (HedgeDoc).
  - Avoir une vue synthétique de l’état des projets via le portail.

- **Direction / Management**
  - Accéder en lecture à un tableau de bord synthétique (projets, incidents, disponibilité des services).
  - Accéder aux principaux outils en lecture seule via le portail (GitLab, Taiga, Grafana, docs, status Uptime Kuma).

### 2.2 Use cases clés

- Un développeur pousse une branche dans GitLab → pipeline CI exécute : lint, tests, SAST, scan des secrets, build image (base DHI), scan Trivy, push vers Harbor → ArgoCD déploie automatiquement sur un namespace approprié.
- Un chef de projet ouvre le portail, s’authentifie (SSO + 2FA), voit ses projets Taiga, ses tâches en cours, les prochaines échéances, et dispose de liens directs vers GitLab, Mattermost et la documentation du projet.
- Un DevOps repère une alerte dans Grafana/Alertmanager, consulte les logs dans Loki, vérifie si Falco a détecté un comportement anormal, crée une issue dans GitLab et/ou une tâche dans Taiga, informe l’équipe via Mattermost.
- Un SecOps audite les logs de Keycloak/Authelia, s’assure que tous les comptes ont la 2FA active, vérifie les rapports de scan Harbor/Trivy et les rapports SonarQube.
- Un Ops effectue un test de restauration Velero sur un environnement de test pour valider la bonne récupération des ressources K3s et des volumes Longhorn.

---

## 3. Architecture globale

### 3.1 Vue d’ensemble

Composants principaux :

- **Cluster K3s** multi-nœuds (masters + workers).
- **Traefik** comme Ingress Controller et reverse proxy.
- **cert-manager** pour la gestion automatique des certificats TLS.
- **Keycloak** comme Identity Provider (SSO), **Authelia** pour la 2FA.
- **GitLab CE** pour le code source, la CI/CD et éventuellement un registry local.
- **Harbor** comme registre central des images (avec scan Trivy, RBAC avancé, Helm charts).
- **Taiga** pour la gestion de projet agile.
- **Mattermost** pour la communication d’équipe.
- **HedgeDoc** pour la documentation collaborative.
- **Prometheus / Grafana / Alertmanager / Loki / Uptime Kuma** pour le monitoring, les alertes et les logs.
- **Falco**, **Trivy**, **OPA/Kyverno** pour la sécurité (runtime + admission + images).
- **Portainer** comme interface graphique K8s (usage contrôlé).
- **ArgoCD** pour les déploiements GitOps.
- **SonarQube** pour la qualité et sécurité du code (SAST, dette technique).
- **HashiCorp Vault** pour la gestion centralisée des secrets.
- **Longhorn** pour le stockage distribué.
- **Velero** pour les sauvegardes/restaurations du cluster K3s (ressources + volumes).
- **Portail unifié** pour centraliser l’accès et les informations clés.

### 3.2 Organisation logique

- **Namespaces K8s** recommandés :
  - `dev`, `test`, `prod` pour les applications métiers.
  - `tools` pour les outils (GitLab, Harbor, Taiga, Mattermost, HedgeDoc, SonarQube, ArgoCD, Portainer, etc.).
  - `monitoring` pour Prometheus, Grafana, Alertmanager, Loki, Uptime Kuma.
  - `security` pour Falco, OPA/Kyverno, Vault.

- **Réseau** :
  - CNI (par exemple Flannel ou Calico).
  - **NetworkPolicies** pour limiter la communication entre namespaces et services, notamment :
    - Interdire par défaut le trafic inter‑namespace sauf exceptions explicites.
    - Restreindre l’accès aux bases de données et services critiques.

---

## 4. Exigences détaillées par composant

### 4.1 K3s (orchestration)

- Déployer un cluster **K3s** hautement disponible :
  - Au moins 3 nœuds de contrôle (masters) pour la tolérance aux pannes.
  - 1 à N nœuds workers selon la charge attendue.
- Configurer K3s pour :
  - L’intégration avec le stockage Longhorn.
  - L’intégration avec Traefik comme Ingress Controller (ou Traefik déployé séparément si besoin de configuration avancée).
- Mettre en place des **RBAC** Kubernetes adaptés :
  - Rôles pour devs (accès lecture/écriture limité à leurs namespaces).
  - Rôles pour ops (accès étendu aux namespaces d’infra et de production).
  - Rôles pour secops (lecture logs, accès aux outils de sécurité et au plan de contrôle).

### 4.2 Traefik (Ingress Controller)

- Utiliser Traefik comme **unique point d’entrée HTTP/HTTPS** des services.
- Configurer :
  - Routage basé sur le nom d’hôte (FQDN) et les chemins.
  - Terminaison TLS (en coordination avec cert-manager).
  - Redirection HTTP → HTTPS.
  - Middlewares :
    - Intégration avec Authelia/Keycloak (authentification)
    - Rate limiting basique
    - Ajout d’en‑têtes de sécurité (HSTS, X‑Frame‑Options, etc.).
- Activer les métriques Traefik (export Prometheus).
- Protéger l’accès au dashboard Traefik via SSO + 2FA.

### 4.3 cert-manager (TLS)

- Déployer **cert-manager** pour gérer :
  - Certificats Let’s Encrypt (staging + production) ou PKI interne.
  - Renouvellement automatique des certificats.
- Définir les **ClusterIssuer/Issuer** nécessaires selon les environnements.
- Garantir que toutes les applications exposées via Traefik utilisent des certificats gérés par cert-manager.

### 4.4 Keycloak (SSO) et Authelia (2FA)

- Déployer **Keycloak** dans le namespace `tools`.
- Configurer :
  - Un Realm dédié à la plateforme DevSecOps.
  - Des groupes (devs, ops, secops, pms, managers).
  - Des rôles d’application (GitLab admin, GitLab dev, etc.).
  - Intégration éventuelle avec LDAP/AD d’entreprise si disponible.
- Enregistrer comme **clients OIDC/SAML** :
  - GitLab CE
  - Harbor
  - Taiga
  - Mattermost
  - Grafana
  - HedgeDoc
  - Portainer
  - ArgoCD
  - SonarQube
  - Portail unifié
- Déployer **Authelia** en frontal, intégré avec Traefik :
  - 2FA obligatoire pour tous les comptes humains.
  - Support TOTP et idéalement WebAuthn.
  - Politiques spéciales pour les comptes techniques (CI/CD) : accès restreint par IP et/ou secrets spécifiques.

### 4.5 GitLab CE (code, CI/CD)

- Déployer GitLab CE dans le namespace `tools`.
- Intégrer GitLab à Keycloak pour SSO.
- Configurer les runners GitLab **Kubernetes** pour exécuter les jobs dans le cluster.
- Pipelines type (vision fonctionnelle, sans code) :
  - Lint et tests unitaires.
  - Analyse de code via SonarQube (SAST, qualité, couverture).
  - Scan de secrets (détection de mots de passe/clefs dans le code).
  - Build d’image conteneur basée uniquement sur des **images officielles DHI** depuis Docker Hub.
  - Scan de l’image avec Trivy.
  - Push de l’image vers Harbor.
  - Création/mise à jour des manifests Helm/Kustomize dans un repo GitOps.
  - Notification à ArgoCD pour synchronisation.
- Optionnel : activation du registry GitLab pour des besoins spécifiques ou transitoires.

### 4.6 Harbor (registry avancé)

- Déployer Harbor dans `tools` (ou namespace dédié `harbor`).
- Intégrer Harbor à Keycloak (SSO).
- Configurer :
  - Projets (namespaces logiques) par équipe, application ou environnement.
  - RBAC détaillé (admin, dev, read‑only).
  - Scans Trivy automatiques à chaque push.
  - Politiques de sécurité :
    - Refuser le déploiement d’images contenant des vulnérabilités critiques.
    - Appliquer des labels et des signatures d’images (Notary si pertinent).
  - Miroir/caching de Docker Hub pour les images DHI.
- Politique d’images :
  - Uniquement des images de base **DHI** (Docker Hub Official Images).
  - Interdiction d’images personnelles non contrôlées comme base.

### 4.7 Taiga (gestion de projet agile)

- Déployer Taiga dans `tools`.
- Intégrer à Keycloak pour SSO.
- Utilisations :
  - Backlog produit, sprints, Kanban, gestion des user stories, épics, tâches, bugs.
- Intégrations :
  - Webhooks avec GitLab (lier commits/MR aux issues Taiga).
  - Exposition d’une API pour extraire :
    - Les tâches assignées à un utilisateur.
    - Les prochaines échéances.
  - Ces données serviront aux widgets du portail unifié.

### 4.8 Mattermost (communication)

- Déployer Mattermost dans `tools`.
- Intégrer SSO via Keycloak.
- Organiser des canaux :
  - Par projet.
  - Par équipe.
  - Canaux globaux : `#general`, `#alerts`, `#incidents`.
- Intégrations :
  - Notifications GitLab (pipelines, MR, tags).
  - Alertes Prometheus via Alertmanager.
  - Intégration avec Taiga (création/suivi d’issues ou notifications).
  - Plugin calendrier/extraction des échéances (en lien avec Taiga si possible).

### 4.9 HedgeDoc (documentation)

- Déployer HedgeDoc dans `tools`.
- Intégrer SSO via Keycloak.
- Structurer la documentation :
  - Dossiers ou tags par projet.
  - Runbooks d’exploitation.
  - Guides DevSecOps (bonnes pratiques, politiques, procédures).
- Exiger l’usage de HedgeDoc comme source unique de vérité documentaire (remplacement de wikis dispersés).

### 4.10 Monitoring & logs (Prometheus, Grafana, Alertmanager, Loki, Uptime Kuma)

- Déployer la stack dans le namespace `monitoring`.

- **Prometheus** :
  - Scraper :
    - Le cluster K3s (métriques nœuds et pods).
    - Traefik.
    - Applications exposant des métriques.
    - Longhorn, Harbor, GitLab, etc. si possible.

- **Grafana** :
  - SSO avec Keycloak.
  - Dashboards standard :
    - Santé du cluster (CPU, RAM, storage, pods en erreur).
    - Traefik (latence, erreurs, requêtes par host).
    - GitLab/Harbor/Keycloak (si métriques disponibles).
    - Applications métiers critiques.

- **Alertmanager** :
  - Règles d’alerte (ressources, disponibilité, erreurs).
  - Intégration avec Mattermost sur un canal dédié (#alerts).

- **Loki** :
  - Centralisation des logs des pods.
  - Labelisation : namespace, app, container, niveau de log.
  - Intégration avec Grafana pour corrélation métriques/logs.

- **Uptime Kuma** :
  - Monitoring simple de disponibilité (HTTP, TCP, etc.).
  - Status page interne (ou publique si souhaité) pour les services clés.

### 4.11 Sécurité runtime & policies (Falco, OPA/Kyverno, Trivy)

- **Falco** :
  - Déploiement en DaemonSet.
  - Règles pour détecter :
    - Shell interactif dans un conteneur.
    - Écriture dans des répertoires sensibles.
    - Accès anormal aux sockets système.
  - Envoi d’alertes vers Mattermost.

- **OPA/Kyverno** :
  - Mise en place de politiques d’admission K8s, par exemple :
    - Interdire le déploiement d’images qui ne proviennent pas de Harbor (ou pas DHI en base).
    - Imposer la présence de NetworkPolicies.
    - Interdire les conteneurs privilégiés.
    - Imposer des limites de ressources (CPU/RAM).

- **Trivy** :
  - Intégration à Harbor (scan à chaque push).
  - Intégration à GitLab CI (scan des images et des dépendances).
  - Rapports consultables par SecOps.

### 4.12 Portainer (GUI K8s)

- Déployer Portainer dans `tools`.
- SSO avec Keycloak.
- Restreindre l’accès aux profils Ops/SecOps.
- Objectif :
  - Offrir une vision graphique simple du cluster.
  - Effectuer des opérations de base (logs, redémarrage de pods) sans manipulation directe de kubectl.

### 4.13 ArgoCD (GitOps)

- Déployer ArgoCD dans `tools`.
- SSO avec Keycloak.
- Lier ArgoCD à des repos GitOps dans GitLab :
  - Manifests K8s (YAML bruts, Helm, Kustomize).
  - Stratégies de synchronisation (automatique ou manuelle).
- Utiliser ArgoCD pour :
  - Gérer les déploiements et rollbacks.
  - Voir l’état synchro Git ↔ cluster.

### 4.14 SonarQube (qualité et sécurité du code)

- Déployer SonarQube dans `tools`.
- SSO avec Keycloak.
- Intégrer aux pipelines GitLab :
  - Analyse de code (langages utilisés dans l’entreprise).
  - Règles SAST.
  - Quality Gates pour bloquer les MR si qualité insuffisante.

### 4.15 HashiCorp Vault (secrets)

- Déployer Vault dans `security` (ou `tools` avec restrictions).
- Configurer :
  - Backend de stockage (par ex. PV Longhorn).
  - Secrets engines :
    - KV (clé/valeur).
    - Database (rotation automatique de mots de passe DB).
    - Éventuellement PKI interne.
- Intégrations :
  - GitLab CI (récupération de secrets au runtime).
  - Applications (accès à Vault via tokens/roles spécifiques).
- Appliquer le principe de moindre privilège pour les policies Vault.

### 4.16 Longhorn (stockage)

- Déployer Longhorn comme solution de stockage distribué.
- Fournir un StorageClass par défaut pour les PV.
- Configuration :
  - Réplication des volumes (ex. 3 réplicas).
  - Monitoring de la santé des disques et volumes.
  - Snapshots internes (complément à Velero).

### 4.17 Velero (sauvegardes)

- Déployer Velero dans `monitoring` ou namespace dédié `velero`.
- Configurer :
  - Backend de stockage (S3 compatible ou NAS via passerelle).
  - Sauvegarde des **ressources Kubernetes** (namespaces, deployments, services, etc.).
  - Sauvegarde des **volumes** via intégration Longhorn.
- Plan de sauvegarde :
  - Backups quotidiens des namespaces `prod` et `tools`.
  - Rétention adaptée (ex. 7 quotidiens, 4 hebdomadaires, 6 mensuels).
- Procédures :
  - Tests réguliers de restauration (au moins trimestriels) sur un environnement de test.

### 4.18 Portail unifié

- Application Web légère (statique ou serveur simple) déployée dans `tools`.
- URL : par exemple `https://devops.entreprise.local`.
- Authentification :
  - SSO via Keycloak.
  - 2FA via Authelia.
- Contenu :
  - **Tuiles d’accès** vers : GitLab, Harbor, Taiga, Mattermost, Grafana, Portainer, ArgoCD, SonarQube, HedgeDoc, Uptime Kuma.
  - **Widget “Mes tâches”** :
    - Interroger l’API Taiga pour afficher les tâches/issues assignées à l’utilisateur.
  - **Widget “Prochains rendez-vous / échéances”** :
    - Basé sur les sprints/échéances Taiga ou sur les plugins calendrier Mattermost.
  - **Widget “État des services”** :
    - Interroger l’API Uptime Kuma pour afficher l’état des services critiques.
  - Lien vers la documentation “Bien démarrer” (HedgeDoc).

---

## 5. Exigences de sécurité DevSecOps (transverses)

- **Images Docker** :
  - Uniquement des images de base **DHI (Docker Hub Official Images)** comme fondations pour les Dockerfiles.
  - Scan systématique des images via Trivy (CI + Harbor).
  - Politique de blocage des images avec vulnérabilités critiques.

- **Pipelines CI/CD sécurisés** :
  - Revue de code obligatoire (MR) avant merge sur les branches protégées.
  - SAST (SonarQube), scan de secrets, tests unitaires/intégration.
  - Aucun secret en clair dans les repos ou variables CI (utiliser Vault).

- **Accès et identités** :
  - SSO obligatoire via Keycloak pour tous les outils.
  - 2FA obligatoire pour tous les comptes utilisateurs.
  - Comptes admin limités et audités.

- **Réseau et isolation** :
  - NetworkPolicies restrictives par défaut.
  - Interdiction des pods privilégiés et des hostPath non justifiés.

- **Journalisation et traçabilité** :
  - Centralisation des logs dans Loki.
  - Conservation des logs d’accès (Traefik, Keycloak, Authelia, GitLab, Harbor, ArgoCD) pour une durée déterminée (ex. 6 à 12 mois).

- **Conformité et procédures** :
  - Documentation des politiques et procédures dans HedgeDoc.
  - Processus formalisés pour :
    - Onboarding / offboarding des utilisateurs.
    - Gestion des incidents de sécurité.
    - Validation des changements majeurs (change management).

---

## 6. Exigences non fonctionnelles

- **Simplicité opérationnelle** :
  - Malgré l’usage de K3s/Kubernetes, l’architecture doit rester compréhensible et gérable par une petite équipe DevOps.
  - Utilisation d’outils facilitant l’exploitation (Portainer, ArgoCD, Grafana, Uptime Kuma).

- **Performances** :
  - Temps de réponse acceptable pour les outils principaux (GitLab, Taiga, Mattermost, etc.).
  - Dimensionnement adapté (CPU/RAM/IO) en fonction de la charge cible.

- **Disponibilité** :
  - Objectif de haute disponibilité raisonnable (cluster K3s multi‑nœuds, Longhorn, Velero).

- **Évolutivité** :
  - Possibilité d’ajouter facilement de nouveaux services DevSecOps.
  - Possibilité de séparer certains composants sur des clusters ou des infrastructures dédiées si la charge augmente.

Ce cahier des charges décrit de manière détaillée et pragmatique la plateforme DevSecOps cible, en intégrant GitLab, Harbor, K3s, Velero et l’ensemble des outils de sécurité, de monitoring et de collaboration, avec une forte orientation **DevSecOps** et un portail unifié pour simplifier l’accès aux utilisateurs.