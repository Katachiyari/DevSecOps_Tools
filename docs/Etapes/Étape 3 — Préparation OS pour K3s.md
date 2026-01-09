# Étape 3 — Préparation OS pour K3s 🛠️🧱

> Objectif : préparer les nœuds (VM) afin d’installer K3s dans de bonnes conditions, de manière **idempotente** (rejoiable sans dérive) et **reproductible**.

---

## Périmètre

Nœuds concernés :
- masters : `master1`, `master2`, `master3`
- worker  : `worker1`

---

## Actions appliquées (automatisées via Ansible)

### 1) Paquets système de base 📦
Installation de paquets nécessaires pour :
- récupération de binaires (curl),
- diagnostics techniques (jq),
- certificats (ca-certificates).

### 2) Swap désactivé 🧠
- Désactivation immédiate du swap.
- Désactivation persistente via `/etc/fstab`.

> swap (définition) : espace disque utilisé comme extension de la RAM ; déconseillé avec Kubernetes.

### 3) Modules noyau chargés 🧩
- Chargement et persistance des modules :
  - `br_netfilter`
  - `overlay`

### 4) Paramètres réseau (sysctl) appliqués 🌐
- Activation du forwarding IPv4.
- Activation du traitement iptables pour le trafic bridgé.

---

## Contrôles de conformité ✅

- Vérification que `swapon --show` ne retourne aucun swap actif.
- Arrêt automatique (échec) si swap encore actif.

---

## Livrables

- Playbook : `infrastructure/ansible/prep-os-k3s.yml`
- Configuration sysctl : `/etc/sysctl.d/99-k8s.conf`
- Modules persistés : `/etc/modules-load.d/k8s.conf`

---

## Prochaine étape

Étape 4 : installation K3s (control plane HA + worker), toujours via Ansible.
