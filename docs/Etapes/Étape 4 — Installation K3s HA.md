# Étape 4 — Installation K3s (HA) 🧱⚙️

> Objectif : disposer d’un cluster **K3s** (Kubernetes léger) en **haute disponibilité** (HA = tolérance à la panne) comme socle du Sprint 1. [web:104]

---

## 1) Pourquoi cette étape (WHY) 🎯

### Finalité Sprint 1
Cette étape valide le **socle d’infrastructure** :
- exécuter des workloads Kubernetes,
- préparer l’Ingress et le TLS (Traefik + cert-manager) à l’étape suivante,
- garantir une base stable avant l’ajout des outils (SSO, GitLab, etc.).  

### Choix HA (3 masters)
Le mode HA utilise un datastore **embedded etcd** (etcd = base de données distribuée du cluster) avec un nombre impair de serveurs (3) pour la tolérance de panne. [web:104]

---

## 2) Ce qui a été mis en place (WHAT) 🧩

### Topologie
- Masters (control plane + etcd) : `master1`, `master2`, `master3`
- Worker (agent) : `worker1`

### Réseau
- Réseau privé Vagrant (host-only) : `192.168.56.101-104`
- Réseau pods (overlay) : `10.42.0.0/16` observé via les IP des pods système.

### Pré-requis OS
- swap désactivé,
- `net.ipv4.ip_forward=1`,
- `net.bridge.bridge-nf-call-iptables=1`,
- `net.bridge.bridge-nf-call-ip6tables=1`. [web:82]

---

## 3) Comment c’est déployé (HOW) 🛠️

### Fichiers du projet
- Playbook Ansible : `infrastructure/ansible/setup-k3s-ha.yml`
- Configuration K3s : `infrastructure/ansible/files/k3s-server-config.yaml` (copiée vers `/etc/rancher/k3s/config.yaml` sur les masters)

### Principe d’exécution
- `master1` initialise le cluster (`--cluster-init`).
- `master2` et `master3` rejoignent le cluster en tant que serveurs.
- `worker1` rejoint le cluster en tant qu’agent. [web:104]

### Reproductibilité / Idempotence
- Version K3s figée (pinned = verrouillée) dans le playbook.
- Les tâches d’installation sont protégées par des contrôles d’existence (`creates:`) afin d’éviter une réinstallation involontaire.

---

## 4) Résultats de validation (contrôles) ✅

### 4.1 Nœuds
Commande :
```bash
sudo kubectl get nodes -o wide

---

## Contrôles complémentaires (qualité) ✅

### Contrôle CNI (réseau pods)
Commande :
```bash
vagrant ssh master1 -c "sudo kubectl -n kube-system get ds,deploy -o wide"
