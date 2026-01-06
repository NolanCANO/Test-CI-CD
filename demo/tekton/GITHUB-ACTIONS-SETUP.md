# 🚀 Guide de configuration CI/CD avec GitHub Actions

Ce guide vous explique comment configurer votre cluster Kubernetes pour être utilisé par GitHub Actions.

## 🎯 Objectif

Permettre à GitHub Actions de déclencher automatiquement votre pipeline Tekton lors des push/PR sur GitHub.

## 📋 Prérequis

- ✅ Cluster Kubernetes opérationnel
- ✅ Tekton Pipelines installé
- ✅ Accès administrateur au cluster
- ✅ Accès administrateur au repository GitHub

## 🔧 Configuration du cluster Kubernetes

### Option 1: Docker Desktop (Local)

Si vous utilisez Docker Desktop, le contexte est déjà configuré localement. Pour GitHub Actions, vous devez exposer votre cluster ou utiliser un self-hosted runner.

#### Configuration Self-Hosted Runner (Recommandé pour local)

1. **Installer GitHub Actions Runner sur votre machine**
```bash
# Télécharger le runner
mkdir actions-runner && cd actions-runner
# Windows
curl -O https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-win-x64-2.311.0.zip
Expand-Archive -Path actions-runner-win-x64-2.311.0.zip -DestinationPath .

# Configurer le runner
./config.cmd --url https://github.com/VOTRE_USERNAME/Test-CI-CD --token VOTRE_TOKEN
```

2. **Obtenir le token d'enregistrement**
- Aller sur GitHub → Settings → Actions → Runners
- Cliquer sur "New self-hosted runner"
- Suivre les instructions

3. **Démarrer le runner**
```bash
./run.cmd
```

4. **Modifier le workflow GitHub Actions**
Remplacer `runs-on: ubuntu-latest` par `runs-on: self-hosted` dans `.github/workflows/tekton-ci.yml`

### Option 2: Cluster Cloud (AKS, EKS, GKE)

#### Pour Azure Kubernetes Service (AKS)

1. **Obtenir les credentials du cluster**
```bash
az aks get-credentials --resource-group VOTRE_RG --name VOTRE_CLUSTER
```

2. **Créer un Service Account pour GitHub Actions**
```bash
kubectl create serviceaccount github-actions -n default
```

3. **Créer un ClusterRoleBinding**
```bash
kubectl create clusterrolebinding github-actions-admin \
  --clusterrole=cluster-admin \
  --serviceaccount=default:github-actions
```

4. **Obtenir le token du Service Account**
```bash
# Pour Kubernetes < 1.24
kubectl get secret $(kubectl get serviceaccount github-actions -o jsonpath='{.secrets[0].name}') -o jsonpath='{.data.token}' | base64 --decode

# Pour Kubernetes >= 1.24
kubectl create token github-actions --duration=87600h
```

5. **Créer le kubeconfig pour GitHub Actions**
```bash
# Récupérer les infos du cluster
CLUSTER_NAME=$(kubectl config view --minify -o jsonpath='{.clusters[0].name}')
CLUSTER_SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
CLUSTER_CA=$(kubectl config view --minify --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')
TOKEN="<token-récupéré-ci-dessus>"

# Créer le kubeconfig
cat <<EOF > github-kubeconfig.yaml
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: ${CLUSTER_CA}
    server: ${CLUSTER_SERVER}
  name: ${CLUSTER_NAME}
contexts:
- context:
    cluster: ${CLUSTER_NAME}
    user: github-actions
  name: github-actions-context
current-context: github-actions-context
users:
- name: github-actions
  user:
    token: ${TOKEN}
EOF

# Encoder en base64
cat github-kubeconfig.yaml | base64 -w 0 > github-kubeconfig-b64.txt
```

#### Pour Amazon EKS

1. **Créer un IAM User pour GitHub Actions**
```bash
aws iam create-user --user-name github-actions-eks
aws iam attach-user-policy --user-name github-actions-eks \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy
```

2. **Générer les credentials**
```bash
aws iam create-access-key --user-name github-actions-eks
```

3. **Configurer kubectl pour EKS**
```bash
aws eks update-kubeconfig --region VOTRE_REGION --name VOTRE_CLUSTER
```

#### Pour Google Kubernetes Engine (GKE)

1. **Créer un Service Account GCP**
```bash
gcloud iam service-accounts create github-actions-gke \
  --display-name="GitHub Actions GKE"
```

2. **Accorder les permissions**
```bash
gcloud projects add-iam-policy-binding VOTRE_PROJECT \
  --member="serviceAccount:github-actions-gke@VOTRE_PROJECT.iam.gserviceaccount.com" \
  --role="roles/container.developer"
```

3. **Créer et télécharger la clé**
```bash
gcloud iam service-accounts keys create github-actions-key.json \
  --iam-account=github-actions-gke@VOTRE_PROJECT.iam.gserviceaccount.com

cat github-actions-key.json | base64 -w 0 > github-actions-key-b64.txt
```

## 🔐 Configuration des secrets GitHub

### 1. Accéder aux secrets
- Aller sur GitHub → Settings → Secrets and variables → Actions

### 2. Ajouter les secrets nécessaires

#### Pour AKS/GKE (avec kubeconfig)
- Cliquer sur "New repository secret"
- Name: `KUBE_CONFIG`
- Value: Contenu de `github-kubeconfig-b64.txt` (base64 encodé)

#### Pour EKS (avec AWS credentials)
- Secret 1:
  - Name: `AWS_ACCESS_KEY_ID`
  - Value: Access Key ID généré
- Secret 2:
  - Name: `AWS_SECRET_ACCESS_KEY`
  - Value: Secret Access Key généré
- Secret 3:
  - Name: `AWS_REGION`
  - Value: Région du cluster (ex: `eu-west-1`)

#### Pour GKE (avec Service Account)
- Secret 1:
  - Name: `GCP_SA_KEY`
  - Value: Contenu de `github-actions-key-b64.txt` (base64 encodé)
- Secret 2:
  - Name: `GCP_PROJECT`
  - Value: ID du projet GCP

## ⚙️ Adapter le workflow GitHub Actions

### Pour AKS/GKE (kubeconfig)

Modifier la section "Configuration du contexte Kubernetes" dans `.github/workflows/tekton-ci.yml`:

```yaml
- name: Configuration du contexte Kubernetes
  run: |
    mkdir -p $HOME/.kube
    echo "${{ secrets.KUBE_CONFIG }}" | base64 -d > $HOME/.kube/config
    chmod 600 $HOME/.kube/config
    kubectl version --client
    kubectl cluster-info
```

### Pour EKS (AWS credentials)

```yaml
- name: Configuration AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    aws-region: ${{ secrets.AWS_REGION }}

- name: Configuration kubectl pour EKS
  run: |
    aws eks update-kubeconfig --region ${{ secrets.AWS_REGION }} --name VOTRE_CLUSTER_NAME
    kubectl version --client
    kubectl cluster-info
```

### Pour GKE (Service Account)

```yaml
- name: Configuration GCP credentials
  uses: google-github-actions/auth@v2
  with:
    credentials_json: '${{ secrets.GCP_SA_KEY }}'

- name: Configuration kubectl pour GKE
  uses: google-github-actions/get-gke-credentials@v2
  with:
    cluster_name: VOTRE_CLUSTER_NAME
    location: VOTRE_ZONE  # ex: europe-west1-b
    project_id: ${{ secrets.GCP_PROJECT }}
```

### Pour Self-Hosted Runner (Docker Desktop)

```yaml
jobs:
  tekton-pipeline:
    name: Exécuter Pipeline Tekton
    runs-on: self-hosted  # ← Changement ici
    
    steps:
      # ... reste du workflow inchangé
      
      - name: Configuration du contexte Kubernetes
        run: |
          # Utilise le contexte Docker Desktop existant
          kubectl config use-context docker-desktop
          kubectl version --client
          kubectl cluster-info
```

## ✅ Vérification de la configuration

### Test de connexion local
```bash
# Test du kubeconfig créé
KUBECONFIG=github-kubeconfig.yaml kubectl get nodes
KUBECONFIG=github-kubeconfig.yaml kubectl get pods -n tekton-pipelines
```

### Test dans GitHub Actions
1. Push un commit ou déclencher manuellement le workflow
2. Aller sur GitHub → Actions
3. Vérifier que le workflow démarre
4. Vérifier les logs de l'étape "Configuration du contexte Kubernetes"

## 🎯 Déclenchement de la pipeline

### 1. Automatique (Push)
```bash
git add .
git commit -m "feat: ajout nouvelle fonctionnalité"
git push origin main
```
➜ La pipeline se lance automatiquement

### 2. Automatique (Pull Request)
1. Créer une branche
2. Faire des modifications
3. Créer une Pull Request
➜ La pipeline se lance pour valider le code

### 3. Manuel (Bouton GitHub)
1. Aller sur GitHub → Actions
2. Sélectionner "Tekton CI/CD Pipeline"
3. Cliquer sur "Run workflow"
4. Choisir la branche (optionnel)
5. Cliquer sur "Run workflow" vert
➜ La pipeline se lance immédiatement

## 🔍 Surveillance et debugging

### Voir les logs GitHub Actions
- GitHub → Actions → Cliquer sur le workflow en cours
- Voir les logs de chaque step

### Voir les logs Tekton
```bash
# Lister les PipelineRuns
kubectl get pipelineruns

# Voir les logs d'un PipelineRun
kubectl logs -f <pipelinerun-pod-name>

# Avec tkn CLI
tkn pipelinerun logs <pipelinerun-name> -f
```

### Voir le status du PipelineRun
```bash
kubectl get pipelinerun <pipelinerun-name> -o yaml
```

## 🛠️ Troubleshooting

### Erreur: "Unable to connect to the cluster"
- Vérifier que le secret `KUBE_CONFIG` est correctement configuré
- Vérifier que le kubeconfig est encodé en base64
- Vérifier que le cluster est accessible depuis internet (pour hosted runner)

### Erreur: "Forbidden: User cannot create resource"
- Vérifier les permissions du Service Account
- Ajouter le ClusterRoleBinding avec cluster-admin

### Erreur: "Context not found"
- Vérifier le nom du context dans le kubeconfig
- Utiliser `kubectl config get-contexts` pour lister les contexts

### Pipeline timeout
- Augmenter le timeout dans le workflow (par défaut 10 minutes)
- Vérifier les ressources du cluster (CPU, RAM)

## 📚 Ressources additionnelles

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Tekton Documentation](https://tekton.dev/docs/)
- [Kubernetes RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [Self-hosted Runners](https://docs.github.com/en/actions/hosting-your-own-runners)

## 🔗 Fichiers de configuration

- Workflow GitHub Actions: [.github/workflows/tekton-ci.yml](../../.github/workflows/tekton-ci.yml)
- Architecture détaillée: [ARCHITECTURE.md](ARCHITECTURE.md)
- Configuration locale: [config.env](config.env)
