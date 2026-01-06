#!/bin/bash
# ========================================
# 🚀 Script de déploiement du pipeline CI/CD
# ========================================

set -e

echo "📦 Déploiement du pipeline CI/CD Spring Boot..."

# 1. Charger les variables depuis config.env
echo "📝 Chargement de la configuration depuis config.env..."
source config.env

# 2. Générer le pipelinerun.yaml depuis le template
echo "🔧 Génération du pipelinerun.yaml..."
cat > pipelinerun-generated.yaml <<EOF
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  name: springboot-ci-run
spec:
  pipelineRef:
    name: springboot-ci
  params:
    - name: GIT_URL
      value: "$GIT_URL"
    - name: GIT_REVISION
      value: "$GIT_REVISION"
    - name: PROJECT_DIR
      value: "$PROJECT_DIR"
    - name: MAVEN_ARGS
      value: "$MAVEN_ARGS"
  workspaces:
    - name: source
      volumeClaimTemplate:
        spec:
          accessModes:
            - ReadWriteOnce
          resources:
            requests:
              storage: $STORAGE_SIZE
    - name: maven-repo
      emptyDir: {}
EOF

# 3. Appliquer les tâches
echo "⚙️  Application des tâches..."
kubectl apply -f tasks/git-clone.yaml
kubectl apply -f tasks/maven-test.yaml

# 4. Appliquer le pipeline
echo "🔧 Application du pipeline..."
kubectl apply -f pipeline.yaml

# 5. Supprimer l'ancien run s'il existe
echo "🗑️  Nettoyage des anciens runs..."
kubectl delete pipelinerun springboot-ci-run --ignore-not-found=true

# 6. Créer le nouveau run
echo "🚀 Lancement du pipeline..."
kubectl apply -f pipelinerun-generated.yaml

# 7. Suivre les logs
echo ""
echo "✅ Pipeline déployé avec succès !"
echo "📊 Configuration utilisée:"
echo "   - Repository: $GIT_URL"
echo "   - Branche: $GIT_REVISION"
echo "   - Dossier projet: $PROJECT_DIR"
echo ""
echo "📊 Suivi des logs (Ctrl+C pour arrêter)..."
echo ""
sleep 2
tkn pipelinerun logs springboot-ci-run -f
