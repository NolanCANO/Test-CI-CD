# Architecture CI/CD - Pipeline Tekton avec GitHub Actions

## 📐 Vue d'ensemble de l'architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            DÉVELOPPEUR                                       │
│                                                                              │
│  1. Push code sur GitHub                                                    │
│  2. Crée une Pull Request                                                   │
│  3. Clique sur "Run workflow" (déclenchement manuel)                        │
└────────────────────────────┬────────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                          GITHUB REPOSITORY                                   │
│  ┌────────────────────────────────────────────────────────────────────┐    │
│  │ Repository: NolanCANO/Test-CI-CD                                    │    │
│  │                                                                     │    │
│  │  📁 .github/workflows/                                              │    │
│  │      └── tekton-ci.yml       ← GitHub Actions Workflow             │    │
│  │                                                                     │    │
│  │  📁 demo/                                                           │    │
│  │      ├── src/                ← Code source Spring Boot             │    │
│  │      ├── pom.xml             ← Configuration Maven                 │    │
│  │      └── tekton/             ← Définitions Tekton                  │    │
│  │          ├── pipeline.yaml                                          │    │
│  │          ├── tasks/                                                 │    │
│  │          │   ├── git-clone.yaml                                     │    │
│  │          │   └── maven-test.yaml                                    │    │
│  │          └── config.env      ← Configuration (pour local)          │    │
│  └────────────────────────────────────────────────────────────────────┘    │
└────────────────────────────┬────────────────────────────────────────────────┘
                             │
                             │ ⚡ Déclenchement automatique
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        GITHUB ACTIONS RUNNER                                 │
│  ┌────────────────────────────────────────────────────────────────────┐    │
│  │ Job: tekton-pipeline                                                │    │
│  │                                                                     │    │
│  │ Steps:                                                              │    │
│  │  1. ✓ Checkout code                                                │    │
│  │  2. ✓ Configuration kubectl                                        │    │
│  │  3. ✓ Connexion au cluster Kubernetes                              │    │
│  │  4. ✓ Appliquer Tasks Tekton (git-clone, maven-test)              │    │
│  │  5. ✓ Appliquer Pipeline Tekton                                    │    │
│  │  6. ✓ Créer PipelineRun avec paramètres                           │    │
│  │  7. ✓ Surveiller l'exécution                                       │    │
│  │  8. ✓ Afficher les résultats                                       │    │
│  └────────────────────────────────────────────────────────────────────┘    │
└────────────────────────────┬────────────────────────────────────────────────┘
                             │
                             │ kubectl apply
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                      KUBERNETES CLUSTER                                      │
│  ┌────────────────────────────────────────────────────────────────────┐    │
│  │ Namespace: default (ou tekton)                                      │    │
│  │                                                                     │    │
│  │ ┌─────────────────────────────────────────────────────────────┐   │    │
│  │ │ TEKTON PIPELINES (Control Plane)                            │   │    │
│  │ │  - Pipeline Controller                                       │   │    │
│  │ │  - Webhook                                                   │   │    │
│  │ └─────────────────────────────────────────────────────────────┘   │    │
│  │                                                                     │    │
│  │ ┌─────────────────────────────────────────────────────────────┐   │    │
│  │ │ PIPELINE RESOURCES                                           │   │    │
│  │ │                                                              │   │    │
│  │ │  Task: git-clone                                             │   │    │
│  │ │   ↓                                                          │   │    │
│  │ │  Task: maven-test                                            │   │    │
│  │ │                                                              │   │    │
│  │ │  Pipeline: spring-boot-test-pipeline                         │   │    │
│  │ │   └─ Références les Tasks ci-dessus                          │   │    │
│  │ │                                                              │   │    │
│  │ │  PipelineRun: spring-boot-pipeline-run-{timestamp}           │   │    │
│  │ │   └─ Instance d'exécution avec paramètres                    │   │    │
│  │ └─────────────────────────────────────────────────────────────┘   │    │
│  │                                                                     │    │
│  │ ┌─────────────────────────────────────────────────────────────┐   │    │
│  │ │ WORKSPACE (Stockage partagé)                                 │   │    │
│  │ │  PersistentVolumeClaim: 1Gi                                  │   │    │
│  │ │   └─ Partagé entre toutes les Tasks du PipelineRun           │   │    │
│  │ └─────────────────────────────────────────────────────────────┘   │    │
│  └────────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                    EXÉCUTION DU PIPELINERUN                                  │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  Pod: spring-boot-pipeline-run-{timestamp}-clone-pod                │   │
│  │                                                                      │   │
│  │  Container: git-clone                                                │   │
│  │   └─ Image: gcr.io/tekton-releases/github.com/tektoncd/...         │   │
│  │   └─ Clone le repo GitHub dans /workspace/source                    │   │
│  │   └─ Résultat: Code source dans le PVC                              │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                             │                                                │
│                             ▼                                                │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  Pod: spring-boot-pipeline-run-{timestamp}-test-pod                 │   │
│  │                                                                      │   │
│  │  Container: maven-test                                               │   │
│  │   └─ Image: maven:3.9.9-eclipse-temurin-17                          │   │
│  │   └─ cd /workspace/source/demo                                       │   │
│  │   └─ mvn clean test                                                  │   │
│  │   └─ Résultat: Tests exécutés, rapport généré                       │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└────────────────────────────┬────────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         RÉSULTATS & LOGS                                     │
│                                                                              │
│  ✅ GitHub Actions affiche:                                                  │
│     - Status du PipelineRun (Succeeded/Failed)                               │
│     - Logs de chaque Task                                                    │
│     - Résultats des tests Maven                                              │
│     - Badge de status dans le README                                         │
│                                                                              │
│  📊 Kubernetes Dashboard affiche:                                            │
│     - Historique des PipelineRuns                                            │
│     - Métriques d'exécution                                                  │
│     - Logs détaillés                                                         │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 🔄 Flux de données détaillé

### Phase 1: Déclenchement
```
Développeur → GitHub (push/PR/manual) → GitHub Actions Webhook
```

### Phase 2: Configuration
```
GitHub Actions Runner
  ├─ Clone le repository
  ├─ Configure kubectl avec credentials K8s
  ├─ Applique les Tasks Tekton
  ├─ Applique le Pipeline Tekton
  └─ Crée le PipelineRun avec paramètres dynamiques
```

### Phase 3: Exécution Tekton
```
PipelineRun Controller
  ├─ Crée un PVC pour le workspace
  │
  ├─ Exécute Task 1: git-clone
  │   ├─ Lance un Pod avec container git-clone
  │   ├─ Clone le code dans /workspace/source
  │   └─ Termine et libère le Pod
  │
  └─ Exécute Task 2: maven-test
      ├─ Lance un Pod avec container Maven
      ├─ Lit le code depuis /workspace/source/demo
      ├─ Exécute mvn clean test
      ├─ Génère les rapports de tests
      └─ Termine et libère le Pod
```

### Phase 4: Reporting
```
PipelineRun Status → GitHub Actions → GitHub UI
  ├─ Logs dans l'onglet "Actions"
  ├─ Status badge (✅/❌)
  └─ Notifications (email, Slack, etc.)
```

## 🎯 Modes de déclenchement

### 1. Push automatique (CI continue)
```yaml
on:
  push:
    branches: [main, develop]
```
**Cas d'usage**: À chaque commit poussé sur `main` ou `develop`

### 2. Pull Request (CI de validation)
```yaml
on:
  pull_request:
    branches: [main]
```
**Cas d'usage**: Valider le code avant merge

### 3. Déclenchement manuel (workflow_dispatch)
```yaml
on:
  workflow_dispatch:
    inputs:
      git_revision:
        description: 'Branch/Tag/Commit à tester'
```
**Cas d'usage**: Tester une branche spécifique ou un ancien commit

## 🛠️ Composants techniques

### GitHub Actions (Orchestrateur)
- **Rôle**: Déclenchement et surveillance
- **Responsabilités**:
  - Écouter les événements Git
  - Configurer la connexion au cluster K8s
  - Appliquer les ressources Tekton
  - Monitorer l'exécution
  - Afficher les résultats

### Tekton Pipeline (Moteur d'exécution)
- **Rôle**: Exécution des tâches CI/CD
- **Responsabilités**:
  - Orchestrer les Tasks
  - Gérer le workspace partagé
  - Isoler l'exécution (Pods)
  - Fournir les logs et status

### Kubernetes (Infrastructure)
- **Rôle**: Plateforme d'exécution
- **Responsabilités**:
  - Provisionner les Pods
  - Gérer le stockage (PVC)
  - Isoler les environnements
  - Gérer les ressources (CPU, RAM)

## 📊 Paramètres configurables

| Paramètre | Source | Valeur par défaut | Description |
|-----------|--------|-------------------|-------------|
| `repo-url` | GitHub Actions | `${{ github.server_url }}/${{ github.repository }}` | URL du repository |
| `revision` | GitHub Actions | `main` / `${{ github.ref_name }}` | Branche/Tag/Commit |
| `project-dir` | Workflow | `demo` | Chemin du projet dans le repo |
| `maven-args` | Workflow | `clean test` | Arguments Maven |
| `storage-size` | Workflow | `1Gi` | Taille du PVC workspace |

## 🔐 Sécurité et secrets

### Secrets GitHub requis (pour cluster externe)
```yaml
secrets:
  KUBE_CONFIG: <contenu du kubeconfig en base64>
  # Ou pour des services cloud:
  AZURE_CREDENTIALS: <JSON credentials pour AKS>
  AWS_ACCESS_KEY_ID: <pour EKS>
  GCP_SA_KEY: <pour GKE>
```

### Configuration dans GitHub:
1. Settings → Secrets and variables → Actions
2. New repository secret
3. Ajouter `KUBE_CONFIG` avec le contenu de `~/.kube/config` encodé en base64

## 🚀 Évolutions possibles

### Phase 2: Build et Registry
```
Task: maven-package → Build le JAR
Task: docker-build → Créer l'image Docker
Task: docker-push → Pousser vers Docker Hub/ACR/ECR
```

### Phase 3: Déploiement
```
Task: deploy-staging → Déployer en staging
Task: integration-tests → Tests d'intégration
Task: deploy-production → Déployer en production (avec approbation)
```

### Phase 4: Monitoring
```
Task: performance-test → Tests de performance
Task: security-scan → Scan de sécurité (Trivy, Snyk)
Task: notify → Notifications (Slack, Teams, Email)
```

## 📝 Avantages de cette architecture

✅ **Automatisation complète**: Du push Git à l'exécution des tests
✅ **Reproductibilité**: Même environnement à chaque exécution
✅ **Scalabilité**: Kubernetes gère les ressources automatiquement
✅ **Traçabilité**: Logs et historique dans GitHub et K8s
✅ **Flexibilité**: Déclenchement manuel ou automatique
✅ **Isolation**: Chaque exécution dans son propre namespace
✅ **Cloud-native**: Compatible avec tous les clusters K8s

## 🎮 Comment utiliser

### Déclenchement automatique (push)
```bash
git add .
git commit -m "feat: nouvelle fonctionnalité"
git push origin main
# ➜ GitHub Actions lance automatiquement la pipeline
```

### Déclenchement manuel (bouton GitHub)
1. Aller sur GitHub → Actions
2. Cliquer sur "Tekton CI/CD Pipeline"
3. Cliquer sur "Run workflow"
4. Choisir la branche (optionnel)
5. Cliquer sur "Run workflow" (bouton vert)

### Surveillance
- Logs en temps réel dans l'onglet "Actions" de GitHub
- Détails dans Kubernetes: `kubectl get pipelineruns`
- Logs Tekton: `tkn pipelinerun logs <nom>`

## 🔗 Liens vers la documentation

- [GitHub Actions Workflow](.github/workflows/tekton-ci.yml)
- [Pipeline Tekton](demo/tekton/pipeline.yaml)
- [Tasks Tekton](demo/tekton/tasks/)
- [Configuration locale](demo/tekton/config.env)
