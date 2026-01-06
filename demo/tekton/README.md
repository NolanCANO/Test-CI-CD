# 🚀 Pipeline CI/CD Spring Boot pour Tekton

Pipeline CI/CD générique et réutilisable pour n'importe quel projet Java Spring Boot.

## 🎯 Modes d'utilisation

### 🚀 Mode Production : GitHub Actions (Recommandé)
**Déclenchement automatique depuis GitHub avec un simple push ou clic !**

➜ **[📖 Guide de configuration GitHub Actions](GITHUB-ACTIONS-SETUP.md)**
- ✅ Déclenchement automatique sur push/PR
- ✅ Bouton "Run workflow" dans GitHub
- ✅ Logs et historique dans l'interface GitHub
- ✅ Compatible avec tous les clusters Kubernetes (AKS, EKS, GKE, Docker Desktop)

➜ **[📐 Architecture détaillée](ARCHITECTURE.md)** - Diagrammes et flux complets

### 💻 Mode Développement : Local
**Exécution manuelle depuis votre machine pour tester rapidement.**

➜ **Guide d'utilisation locale** (voir section [Utilisation](#-utilisation-rapide-mode-local) ci-dessous)
- ✅ Exécution rapide avec `deploy.ps1` ou `deploy.sh`
- ✅ Configuration via fichier `config.env`
- ✅ Parfait pour tester les modifications

---

## 📋 Prérequis

- Cluster Kubernetes avec Tekton Pipelines installé
- `kubectl` configuré
- `tkn` CLI (optionnel mais recommandé)
- Pour GitHub Actions : voir [GITHUB-ACTIONS-SETUP.md](GITHUB-ACTIONS-SETUP.md)

## 🎯 Architecture du Pipeline

```
┌─────────────┐      ┌──────────────┐
│  git-clone  │ ───> │  maven-test  │
└─────────────┘      └──────────────┘
```

### Étapes :
1. **git-clone** : Clone le repository Git
2. **maven-test** : Compile et exécute les tests Maven

## 📁 Structure des fichiers

```
tekton/
├── README.md              # Ce fichier
├── pipeline.yaml          # Définition du pipeline (NE PAS MODIFIER)
├── pipelinerun.yaml       # Configuration du projet (À MODIFIER)
└── tasks/
    ├── git-clone.yaml     # Tâche de clonage Git (NE PAS MODIFIER)
    └── maven-test.yaml    # Tâche de test Maven (NE PAS MODIFIER)
```

## ⚙️ Configuration pour un nouveau projet

### 1️⃣ Copier les fichiers Tekton

Copiez le dossier `tekton/` dans votre nouveau projet Spring Boot :

```bash
cp -r tekton/ /chemin/vers/nouveau-projet/
```

### 2️⃣ Modifier uniquement `pipelinerun.yaml`

Ouvrez `tekton/pipelinerun.yaml` et modifiez les variables suivantes :

| Variable | Description | Exemple |
|----------|-------------|---------|
| `metadata.name` | Nom unique du pipeline run | `mon-app-ci-run` |
| `GIT_URL` | URL de votre repository Git | `https://github.com/user/mon-projet.git` |
| `GIT_REVISION` | Branche à utiliser | `main`, `develop`, `feature/xyz` |
| `PROJECT_DIR` | Chemin vers le dossier contenant pom.xml | `.` (racine) ou `backend`, `api`, etc. |
| `storage` | Taille du volume de stockage | `1Gi`, `2Gi`, `5Gi` |

**Exemple de configuration :**

```yaml
# Pour un projet avec pom.xml à la racine
PROJECT_DIR: "."
GIT_URL: https://github.com/monUser/monApp.git

# Pour un projet multi-modules avec pom.xml dans un sous-dossier
PROJECT_DIR: "backend"
GIT_URL: https://github.com/monUser/monApp.git
```

### 3️⃣ (Optionnel) Paramètres Maven avancés

Si vous avez besoin de passer des arguments Maven spécifiques, décommentez et modifiez :

```yaml
params:
  - name: MAVEN_ARGS
    value: "-DskipTests=false -Dspring.profiles.active=test"
```

Exemples d'arguments utiles :
- `-DskipTests=true` : Sauter les tests
- `-Dmaven.test.skip=true` : Sauter compilation et tests
- `-Dspring.profiles.active=test` : Activer un profil Spring spécifique
- `-X` : Mode debug Maven

## 🚀 Déploiement et exécution

### Installation du pipeline

```bash
# Appliquer les tâches
kubectl apply -f tekton/tasks/git-clone.yaml
kubectl apply -f tekton/tasks/maven-test.yaml

# Appliquer le pipeline
kubectl apply -f tekton/pipeline.yaml
```

### Lancer le pipeline

```bash
# Créer et lancer un pipeline run
kubectl apply -f tekton/pipelinerun.yaml

# Suivre les logs en temps réel
tkn pipelinerun logs springboot-ci-run -f
```

### Relancer le pipeline

```bash
# Supprimer l'ancien run
kubectl delete pipelinerun springboot-ci-run

# Créer un nouveau run
kubectl apply -f tekton/pipelinerun.yaml
tkn pipelinerun logs springboot-ci-run -f
```

## 📊 Vérifier l'état du pipeline

```bash
# Lister tous les pipeline runs
tkn pipelinerun list

# Voir les détails d'un run spécifique
tkn pipelinerun describe springboot-ci-run

# Voir les logs d'une tâche spécifique
tkn pipelinerun logs springboot-ci-run -t clone
tkn pipelinerun logs springboot-ci-run -t test
```

## 🔧 Personnalisation avancée

### Ajouter une nouvelle tâche

Si vous voulez ajouter une étape (build, deploy, etc.) :

1. Créez une nouvelle tâche dans `tasks/` (ex: `maven-build.yaml`)
2. Ajoutez-la dans `pipeline.yaml` :

```yaml
- name: build
  runAfter: [test]
  taskRef:
    name: maven-build
  workspaces:
    - name: source
      workspace: source
```

3. Réappliquez le pipeline :

```bash
kubectl apply -f tekton/tasks/maven-build.yaml
kubectl apply -f tekton/pipeline.yaml
```

### Utiliser un PersistentVolumeClaim existant

Au lieu de créer un volume à chaque fois, vous pouvez utiliser un PVC existant :

```yaml
workspaces:
  - name: source
    persistentVolumeClaim:
      claimName: mon-pvc-existant
```

## 🐛 Dépannage

### Le pipeline ne trouve pas le pom.xml

Vérifiez que `PROJECT_DIR` pointe vers le bon dossier :

```bash
# Voir la structure du repo après clonage
tkn pipelinerun logs springboot-ci-run -t clone
```

### Erreur "volumeClaimTemplate not found"

Votre cluster doit supporter les PersistentVolumeClaims dynamiques. Alternative :

1. Créez un PVC manuellement
2. Utilisez-le dans `pipelinerun.yaml` (voir section précédente)

### Les tests échouent

Vérifiez les logs détaillés :

```bash
tkn pipelinerun logs springboot-ci-run -t test
```

## 📚 Ressources

- [Documentation Tekton](https://tekton.dev/docs/)
- [Tekton Hub - Tasks réutilisables](https://hub.tekton.dev/)
- [Guide Spring Boot](https://spring.io/guides)

## 📝 Checklist de migration

- [ ] Copier le dossier `tekton/` dans le nouveau projet
- [ ] Modifier `metadata.name` dans `pipelinerun.yaml`
- [ ] Modifier `GIT_URL` avec l'URL de votre repo
- [ ] Ajuster `PROJECT_DIR` si le pom.xml n'est pas à la racine
- [ ] Ajuster la taille du `storage` si nécessaire
- [ ] Appliquer les tasks : `kubectl apply -f tekton/tasks/`
- [ ] Appliquer le pipeline : `kubectl apply -f tekton/pipeline.yaml`
- [ ] Lancer le pipeline : `kubectl apply -f tekton/pipelinerun.yaml`
- [ ] Vérifier les logs : `tkn pipelinerun logs springboot-ci-run -f`

---

**🎉 Voilà ! Votre pipeline CI/CD est maintenant réutilisable pour n'importe quel projet Spring Boot !**
