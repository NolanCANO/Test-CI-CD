# 🚀 Pipeline CI/CD Spring Boot avec fichier .env

## 📋 Nouvelle approche simplifiée

Modifiez uniquement le fichier **`config.env`** et lancez le script de déploiement !

## ⚙️ Configuration en 2 étapes

### 1️⃣ Modifier `config.env`

Éditez le fichier `config.env` avec les valeurs de votre projet :

```bash
# Repository Git
GIT_URL=https://github.com/VotreUser/VotreProjet.git
GIT_REVISION=main

# Structure du projet
PROJECT_DIR=.

# Stockage
STORAGE_SIZE=1Gi

# Arguments Maven
MAVEN_ARGS=-DskipTests=false
```

### 2️⃣ Lancer le déploiement

**Windows (PowerShell)** :
```powershell
cd tekton
./deploy.ps1
```

**Linux/Mac** :
```bash
cd tekton
chmod +x deploy.sh
./deploy.sh
```

## ✨ Ce que fait le script

1. 📝 Charge les variables depuis `config.env`
2. 🔧 Génère automatiquement le `pipelinerun-generated.yaml`
3. ⚙️ Applique les tâches et le pipeline
4. 🗑️ Nettoie les anciens runs
5. 🚀 Lance le nouveau pipeline
6. 📊 Affiche les logs en temps réel

## 📁 Structure des fichiers

```
tekton/
├── config.env                 # ⚠️ À MODIFIER : Configuration du projet
├── deploy.ps1                 # Script de déploiement Windows
├── deploy.sh                  # Script de déploiement Linux/Mac
├── pipeline.yaml              # NE PAS MODIFIER
├── pipelinerun.yaml           # NE PAS MODIFIER (ancien système)
├── pipelinerun-generated.yaml # Généré automatiquement par le script
└── tasks/
    ├── git-clone.yaml         # NE PAS MODIFIER
    └── maven-test.yaml        # NE PAS MODIFIER
```

## 🔄 Pour un nouveau projet

1. Copiez le dossier `tekton/` dans votre nouveau projet
2. Modifiez **uniquement** `config.env`
3. Lancez `./deploy.ps1` (Windows) ou `./deploy.sh` (Linux/Mac)

## 📝 Exemples de configuration

### Projet à la racine
```bash
PROJECT_DIR=.
GIT_URL=https://github.com/user/monapp.git
```

### Projet dans un sous-dossier
```bash
PROJECT_DIR=backend
GIT_URL=https://github.com/user/monapp.git
```

### Sauter les tests
```bash
MAVEN_ARGS=-DskipTests=true
```

### Profil Spring spécifique
```bash
MAVEN_ARGS=-Dspring.profiles.active=test
```

## 🎯 Commandes utiles

```powershell
# Voir l'état du pipeline
tkn pipelinerun list

# Voir les détails
tkn pipelinerun describe springboot-ci-run

# Relancer le pipeline
./deploy.ps1

# Voir uniquement les logs d'une tâche
tkn pipelinerun logs springboot-ci-run -t clone
tkn pipelinerun logs springboot-ci-run -t test
```

## 🐛 Dépannage

### Erreur "permission denied" sur Linux/Mac
```bash
chmod +x deploy.sh
```

### Le script ne trouve pas config.env
Assurez-vous d'être dans le dossier `tekton/` :
```bash
cd tekton
./deploy.sh
```

---

**🎉 C'est tout ! Plus besoin de modifier des fichiers YAML complexes.**
