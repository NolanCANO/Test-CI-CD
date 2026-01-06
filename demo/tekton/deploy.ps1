# Script de déploiement du pipeline CI/CD
Write-Host "Deploiement du pipeline CI/CD Spring Boot..." -ForegroundColor Cyan

# 1. Charger les variables depuis config.env
Write-Host "Chargement de la configuration depuis config.env..." -ForegroundColor Yellow
$config = @{}
Get-Content "config.env" | ForEach-Object {
    if ($_ -match '^([^#][^=]+)=(.*)$') {
        $config[$matches[1].Trim()] = $matches[2].Trim()
    }
}

# 2. Générer le pipelinerun.yaml
Write-Host "Generation du pipelinerun.yaml..." -ForegroundColor Yellow
$gitUrl = $config['GIT_URL']
$gitRevision = $config['GIT_REVISION']
$projectDir = $config['PROJECT_DIR']
$mavenArgs = $config['MAVEN_ARGS']
$storageSize = $config['STORAGE_SIZE']

$yaml = "apiVersion: tekton.dev/v1`nkind: PipelineRun`nmetadata:`n  name: springboot-ci-run`nspec:`n  pipelineRef:`n    name: springboot-ci`n  params:`n    - name: GIT_URL`n      value: `"$gitUrl`"`n    - name: GIT_REVISION`n      value: `"$gitRevision`"`n    - name: PROJECT_DIR`n      value: `"$projectDir`"`n    - name: MAVEN_ARGS`n      value: `"$mavenArgs`"`n  workspaces:`n    - name: source`n      volumeClaimTemplate:`n        spec:`n          accessModes:`n            - ReadWriteOnce`n          resources:`n            requests:`n              storage: $storageSize`n    - name: maven-repo`n      emptyDir: {}"

[System.IO.File]::WriteAllText("$PWD\pipelinerun-generated.yaml", $yaml)

# 3. Appliquer les tâches
Write-Host "Application des taches..." -ForegroundColor Yellow
kubectl apply -f tasks/git-clone.yaml
kubectl apply -f tasks/maven-test.yaml

# 4. Appliquer le pipeline
Write-Host "Application du pipeline..." -ForegroundColor Yellow
kubectl apply -f pipeline.yaml

# 5. Supprimer l'ancien run
Write-Host "Nettoyage des anciens runs..." -ForegroundColor Yellow
kubectl delete pipelinerun springboot-ci-run --ignore-not-found=true

# 6. Créer le nouveau run
Write-Host "Lancement du pipeline..." -ForegroundColor Yellow
kubectl apply -f pipelinerun-generated.yaml

# 7. Suivre les logs
Write-Host ""
Write-Host "Pipeline deploye avec succes!" -ForegroundColor Green
Write-Host "Configuration utilisee:" -ForegroundColor Cyan
Write-Host "  - Repository: $gitUrl" -ForegroundColor Gray
Write-Host "  - Branche: $gitRevision" -ForegroundColor Gray
Write-Host "  - Dossier projet: $projectDir" -ForegroundColor Gray
Write-Host ""
Write-Host "Suivi des logs (Ctrl+C pour arreter)..." -ForegroundColor Cyan
Write-Host ""
Start-Sleep -Seconds 2
tkn pipelinerun logs springboot-ci-run -f