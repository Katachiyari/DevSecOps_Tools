# Étape 4.1 — K3s HA : installation & fonctionnement (vulgarisé) 🧱🎓

> Objectif : expliquer **ce qui a été installé**, **pourquoi**, et **comment ça fonctionne**, afin de consolider des bases Kubernetes avec K3s (Kubernetes “léger”). [web:273]

---

## 1) Contexte : pourquoi K3s ? 🎯

K3s est une distribution Kubernetes **simplifiée** :
- un binaire principal,
- moins de dépendances,
- des composants “packagés” (packaged components = addons fournis et gérés par K3s). [web:265]

Dans ce projet, K3s sert de **socle** pour une plateforme DevSecOps (outils + SSO + sécurité), donc le cluster doit être :
- stable,
- reproductible,
- suffisamment HA pour un environnement “sérieux” (même en lab). [web:104]

---

## 2) Architecture installée : HA avec embedded etcd 🧠🗄️

### Rôles des nœuds
- **Masters** (control plane) : `master1`, `master2`, `master3`
  - hébergent l’API Kubernetes (API server = point d’entrée du cluster),
  - hébergent aussi **etcd** (base de données distribuée du cluster). [web:104]
- **Worker** : `worker1`
  - exécute principalement les applications (pods). [web:104]

### Pourquoi 3 masters ?
Le mode HA “embedded etcd” repose sur etcd qui fonctionne mieux avec un nombre impair de nœuds (quorum = majorité nécessaire pour valider des écritures). [web:104]

---

## 3) Ce que “kubectl get nodes” prouve ✅

La commande `kubectl get nodes -o wide` montre :
- `STATUS Ready` : le nœud est joignable et fonctionne correctement.
- `ROLES control-plane,etcd` sur les masters : HA control plane + datastore etcd actifs. [web:104]
- `INTERNAL-IP 192.168.56.101-104` : les nœuds communiquent sur le réseau privé Vagrant (host-only), donc stable et prévisible.

---

## 4) Réseau Kubernetes : pourquoi les pods ont des IP en 10.42.0.x 🌐

Les pods reçoivent des IP “internes cluster” (overlay = réseau virtuel au-dessus du réseau des VM).
Dans ton cas :
- pods en `10.42.0.x` (ex: CoreDNS `10.42.0.4`)  
Cela confirme que le réseau pods est fonctionnel (les pods peuvent se parler via ce réseau). [web:251]

> Note : K3s utilise souvent Flannel comme CNI (CNI = plugin réseau Kubernetes). Selon la configuration, tous les composants ne s’observent pas toujours sous forme de pods dédiés, mais le fait que CoreDNS tourne et a une IP pods est un indicateur clé. [web:251][web:252]

---

## 5) Les composants système observés (kube-system) 🧩

Les pods “kube-system” sont des briques de base.

### 5.1 CoreDNS (DNS du cluster) 📡
- Rôle : résoudre des noms de services/pods à l’intérieur du cluster.
- Preuve : `kube-dns` a des endpoints (`kubectl get endpoints -n kube-system`). [web:251]

Sans DNS interne, beaucoup d’applications Kubernetes “ne tiennent pas” (services qui ne se trouvent pas).

### 5.2 local-path-provisioner (stockage simple) 💾
- Rôle : fournir des volumes persistants simples pour un lab.
- Utilité : permet à une application de stocker des données sans système de stockage distribué.

> Plus tard dans le projet : Longhorn remplacera ce modèle pour du stockage distribué (Phase 2). (stockage distribué = volumes répliqués sur plusieurs nœuds)

### 5.3 metrics-server (métriques Kubernetes) 📊
- Rôle : fournir des métriques de base (CPU/RAM) aux API Kubernetes.
- Utilité : nécessaire pour `kubectl top`, et utile pour la supervision (plus tard Prometheus/Grafana). [web:265]

---

## 6) Pourquoi Traefik n’apparaît pas (c’est voulu) 🚦
K3s peut fournir Traefik “packagé” par défaut, mais dans ce projet Traefik a été **désactivé** dans la configuration K3s. [web:265]

But :
- garder le contrôle sur l’Ingress (Ingress controller = point d’entrée HTTP/HTTPS),
- installer Traefik ensuite avec une configuration propre (TLS, middlewares, sécurité) à l’Étape 5.

La commande :
```bash
kubectl -n kube-system get pods | egrep -i 'traefik|helm|svclb'
