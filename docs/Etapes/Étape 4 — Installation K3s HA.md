# Étape 4 — Installation K3s (HA) 🧱⚙️

> Objectif : installer un cluster **K3s** en **haute disponibilité** (HA = tolérance à la panne via plusieurs serveurs). [web:104]

---

## Périmètre

- Masters (serveurs control plane) : `master1`, `master2`, `master3`
- Worker (agent) : `worker1`

---

## Choix d’implémentation (reproductibilité)

- Version K3s **figée** (pinned = version verrouillée).
- Configuration via fichier `/etc/rancher/k3s/config.yaml` (config.yaml = fichier de configuration K3s). [web:97]
- Mode HA “embedded etcd” : initialisation sur le 1er master via `--cluster-init` puis jonction des autres masters. [web:104]

---

## Fichiers du projet

- Config K3s serveurs : `infrastructure/k3s/k3s-server-config.yaml`
- Playbook Ansible : `infrastructure/ansible/setup-k3s-ha.yml`

---

## Exécution (commande unique)

```bash
ansible-playbook -i infrastructure/ansible/inventory_vagrant.ini infrastructure/ansible/setup-k3s-ha.yml
