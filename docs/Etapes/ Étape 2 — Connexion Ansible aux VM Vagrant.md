# Étape 2 — Connexion Ansible aux VM Vagrant 🔐🧩

> Objectif : permettre à **Ansible** (outil d’automatisation) d’exécuter des actions sur les VM Vagrant de manière **répétable** (reproductible) et **idempotente** (idempotent = rejouable plusieurs fois, résultat final identique).

---

## ✅ Pré-requis

- Un environnement **Vagrant** opérationnel.
- Les VM suivantes démarrées : `master1`, `master2`, `master3`, `worker1`.

---

## 1) Génération de la configuration SSH Vagrant 🗝️

Vagrant expose les paramètres SSH exacts (port, clé privée, options).  
Cette configuration est exportée dans un fichier local dédié :

- Commande :
  - `vagrant ssh-config > .vagrant/ssh-config`

🎯 Résultat attendu :
- Un fichier `.vagrant/ssh-config` présent à la racine du projet.

---

## 2) Création de l’inventaire Ansible 📒

Un **inventaire** (inventory = liste des machines cibles) est créé pour décrire le cluster :

- Fichier : `infrastructure/ansible/inventory_vagrant.ini`

Groupes définis :
- `masters` : nœuds de contrôle (control plane = nœuds qui gèrent Kubernetes)
- `workers` : nœuds d’exécution (worker = nœuds qui exécutent les workloads)

Variables importantes :
- `ansible_user=vagrant` : utilisateur SSH par défaut dans les VM Vagrant.
- `ansible_ssh_common_args=-F .vagrant/ssh-config` : Ansible réutilise la configuration SSH exportée par Vagrant.
- `ansible_python_interpreter=/usr/bin/python3` : stabilise l’interpréteur Python pour assurer la reproductibilité.

---

## 3) Test de connectivité (contrôle) 🧪

Un test est exécuté sur toutes les VM :

- Commande :
  - `ansible all -i infrastructure/ansible/inventory_vagrant.ini -m ping`

🎯 Résultat attendu :
- `SUCCESS` sur `master1`, `master2`, `master3`, `worker1`.

---

## 🔒 Note DevSecOps (sécurité dès le début) 🛡️

Cette étape permet :
- de **centraliser** et **tracer** les actions d’administration via Ansible (meilleure gouvernance),
- d’éviter des configurations “à la main” non reproductibles,
- de préparer les prochaines étapes (installation K3s, durcissement, déploiements).

---

## ⏭️ Prochaine étape

**Étape 3 : Préparation système + installation K3s** de manière idempotente, avec exécution Ansible contrôlée (sans actions irréversibles non documentées).
