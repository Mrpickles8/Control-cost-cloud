# Cost-control-cloud

![CI/CD](https://github.com/Mrpickles8/aws-cost-calculator/actions/workflows/terraform.yml/badge.svg)



Readme projet1 · MD
# aws-cloud-cost-calculator
 
> 🌍 **Choisissez votre langue / Select your language / Sprache wählen**
 
[🇫🇷 Français](#français) ·
[🇬🇧 English](#english) ·
[🇩🇪 Deutsch](#deutsch)
 
---
 
## Français
 
## Objectif
 
Ce projet met en place un système automatique de surveillance et d'alerte sur les coûts AWS. Il déploie une alarme CloudWatch qui envoie une notification email dès qu'un seuil de dépense est dépassé, un dashboard de visualisation des coûts en temps réel, et une fonction Lambda qui génère chaque semaine un rapport HTML stocké sur S3.
 
## Problème résolu
 
Sans surveillance des coûts, une erreur de configuration peut générer une facture AWS de plusieurs centaines d'euros en quelques heures sans que personne ne s'en rende compte. Ce projet crée un filet de sécurité automatique.
 
## Compétences acquises
 
- Surveillance des métriques de facturation AWS avec CloudWatch
- Création d'alarmes et de dashboards CloudWatch
- Déploiement de fonctions Lambda serverless avec Terraform
- Automatisation de tâches planifiées avec EventBridge
- Stockage et gestion de rapports sur S3
- Notification par email via SNS
## Outils utilisés
 
- Terraform (Infrastructure as Code)
- AWS : CloudWatch, CloudWatch Alarms, SNS, S3, Lambda, EventBridge, IAM
## Architecture
 
```
CloudWatch Billing Metric (us-east-1)
    → Alarme si seuil dépassé
        → SNS Topic → Email d'alerte
 
EventBridge (chaque lundi à 8h)
    → Lambda
        → Cost Explorer API
            → Rapport HTML
                → S3 Bucket
```
 
## Étapes
 
### Ref 1 : Provider multi-région
 
Les métriques de facturation AWS ne sont disponibles qu'en `us-east-1`. On crée deux providers — un par défaut en `eu-west-1` et un alias en `us-east-1` pour l'alarme billing.
 
```hcl
provider "aws" {
  region = var.aws_region
}
 
provider "aws" {
  alias  = "us_east"
  region = "us-east-1"
}
```
 
### Ref 2 : SNS Topic et souscription email
 
SNS (Simple Notification Service) est le service d'envoi de notifications. L'alarme publie dans ce topic qui transmet par email à tous les abonnés.
 
```hcl
resource "aws_sns_topic" "cost_alerts" {
  provider = aws.us_east
  name     = "cost-calculator-cost-alerts"
}
 
resource "aws_sns_topic_subscription" "email" {
  provider  = aws.us_east
  topic_arn = aws_sns_topic.cost_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}
```
 
### Ref 3 : Alarme CloudWatch sur les coûts
 
L'alarme surveille la métrique `EstimatedCharges` et se déclenche quand les dépenses mensuelles dépassent le seuil défini. Elle envoie alors un email via SNS.
 
```hcl
resource "aws_cloudwatch_metric_alarm" "billing_alarm" {
  provider            = aws.us_east
  alarm_name          = "cost-calculator-billing-alert"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = 86400
  statistic           = "Maximum"
  threshold           = var.alert_threshold_usd
  alarm_actions       = [aws_sns_topic.cost_alerts.arn]
  dimensions = {
    Currency = "USD"
  }
}
```
 
### Ref 4 : Dashboard CloudWatch
 
Un dashboard regroupe les métriques de coûts en un seul écran visuel, accessible directement depuis la console AWS.
 
```hcl
resource "aws_cloudwatch_dashboard" "cost" {
  dashboard_name = "cost-calculator-dashboard"
 
  dashboard_body = jsonencode({
    widgets = [{
      type = "metric"
      properties = {
        title   = "AWS Monthly Estimated Cost (USD)"
        region  = "us-east-1"
        metrics = [["AWS/Billing", "EstimatedCharges", "Currency", "USD"]]
        period  = 86400
        stat    = "Maximum"
      }
    }]
  })
}
```
 
### Ref 5 : Lambda — rapport hebdomadaire automatique
 
Une fonction Lambda interroge l'API Cost Explorer chaque lundi à 8h, génère un rapport HTML des dépenses par service et le stocke dans S3. EventBridge déclenche cette exécution automatiquement.
 
```hcl
resource "aws_cloudwatch_event_rule" "weekly" {
  name                = "cost-calculator-weekly-trigger"
  schedule_expression = "cron(0 8 ? * MON *)"
}
 
resource "aws_lambda_function" "weekly_reports" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "cost-calculator-weekly-report"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_report.lambda_handler"
  runtime       = "python3.12"
  timeout       = 60
}
```
 
## Déploiement
 
```bash
terraform init
terraform plan
terraform apply
```
 
> ⚠️ Après le déploiement, confirmez la souscription SNS en cliquant sur le lien reçu par email.
 
## Coût estimé
 
| Service | Coût mensuel |
|---|---|
| CloudWatch Alarm | ~$0.10 |
| CloudWatch Dashboard | ~$3.00 |
| SNS + Lambda + S3 | ~$0.00 (Free Tier) |
| **Total** | **~$3.10/mois** |
 
 
[⬆️ Retour au menu](#aws-cloud-cost-calculator)
 
---
 
## English
 
## Objective
 
This project sets up an automatic AWS cost monitoring and alerting system. It deploys a CloudWatch alarm that sends an email notification when a spending threshold is exceeded, a real-time cost visualization dashboard, and a Lambda function that generates a weekly HTML report stored in S3.
 
## Problem Solved
 
Without cost monitoring, a misconfiguration can generate an AWS bill of several hundred euros within hours without anyone noticing. This project creates an automatic safety net.
 
## Skills Learned
 
- Monitoring AWS billing metrics with CloudWatch
- Creating CloudWatch alarms and dashboards
- Deploying serverless Lambda functions with Terraform
- Automating scheduled tasks with EventBridge
- Storing and managing reports in S3
- Email notification via SNS
## Tools Used
 
- Terraform (Infrastructure as Code)
- AWS: CloudWatch, CloudWatch Alarms, SNS, S3, Lambda, EventBridge, IAM
## Architecture
 
```
CloudWatch Billing Metric (us-east-1)
    → Alarm if threshold exceeded
        → SNS Topic → Alert email
 
EventBridge (every Monday at 8am)
    → Lambda
        → Cost Explorer API
            → HTML Report
                → S3 Bucket
```
 
## Steps
 
### Ref 1: Multi-region provider
 
AWS billing metrics are only available in `us-east-1`. Two providers are created — a default one in `eu-west-1` and an alias in `us-east-1` for the billing alarm.
 
```hcl
provider "aws" {
  region = var.aws_region
}
 
provider "aws" {
  alias  = "us_east"
  region = "us-east-1"
}
```
 
### Ref 2: SNS Topic and email subscription
 
SNS (Simple Notification Service) handles notifications. The alarm publishes to this topic, which forwards alerts by email to all subscribers.
 
```hcl
resource "aws_sns_topic" "cost_alerts" {
  provider = aws.us_east
  name     = "cost-calculator-cost-alerts"
}
 
resource "aws_sns_topic_subscription" "email" {
  provider  = aws.us_east
  topic_arn = aws_sns_topic.cost_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}
```
 
### Ref 3: CloudWatch billing alarm
 
The alarm monitors the `EstimatedCharges` metric and triggers when monthly spending exceeds the defined threshold, sending an email via SNS.
 
```hcl
resource "aws_cloudwatch_metric_alarm" "billing_alarm" {
  provider            = aws.us_east
  alarm_name          = "cost-calculator-billing-alert"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = 86400
  statistic           = "Maximum"
  threshold           = var.alert_threshold_usd
  alarm_actions       = [aws_sns_topic.cost_alerts.arn]
  dimensions = {
    Currency = "USD"
  }
}
```
 
### Ref 4: CloudWatch dashboard
 
A dashboard groups cost metrics into a single visual screen, accessible directly from the AWS console.
 
```hcl
resource "aws_cloudwatch_dashboard" "cost" {
  dashboard_name = "cost-calculator-dashboard"
 
  dashboard_body = jsonencode({
    widgets = [{
      type = "metric"
      properties = {
        title   = "AWS Monthly Estimated Cost (USD)"
        region  = "us-east-1"
        metrics = [["AWS/Billing", "EstimatedCharges", "Currency", "USD"]]
        period  = 86400
        stat    = "Maximum"
      }
    }]
  })
}
```
 
### Ref 5: Lambda — automatic weekly report
 
A Lambda function queries the Cost Explorer API every Monday at 8am, generates an HTML spending report by service, and stores it in S3. EventBridge triggers this execution automatically.
 
```hcl
resource "aws_cloudwatch_event_rule" "weekly" {
  name                = "cost-calculator-weekly-trigger"
  schedule_expression = "cron(0 8 ? * MON *)"
}
 
resource "aws_lambda_function" "weekly_reports" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "cost-calculator-weekly-report"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_report.lambda_handler"
  runtime       = "python3.12"
  timeout       = 60
}
```
 
## Deployment
 
```bash
terraform init
terraform plan
terraform apply
```
 
> ⚠️ After deployment, confirm the SNS subscription by clicking the link received by email.
 
## Estimated Cost
 
| Service | Monthly cost |
|---|---|
| CloudWatch Alarm | ~$0.10 |
| CloudWatch Dashboard | ~$3.00 |
| SNS + Lambda + S3 | ~$0.00 (Free Tier) |
| **Total** | **~$3.10/month** |
 
 
[⬆️ Back to menu](#aws-cloud-cost-calculator)
 
---
 
## Deutsch
 
## Ziel
 
Dieses Projekt richtet ein automatisches AWS-Kostenüberwachungs- und Warnsystem ein. Es stellt einen CloudWatch-Alarm bereit, der eine E-Mail-Benachrichtigung sendet, wenn ein Ausgabenschwellenwert überschritten wird, ein Echtzeit-Dashboard zur Kostenvisualisierung sowie eine Lambda-Funktion, die wöchentlich einen HTML-Bericht generiert und in S3 speichert.
 
## Gelöstes Problem
 
Ohne Kostenüberwachung kann eine Fehlkonfiguration innerhalb weniger Stunden eine AWS-Rechnung von mehreren hundert Euro erzeugen, ohne dass es jemand bemerkt. Dieses Projekt schafft ein automatisches Sicherheitsnetz.
 
## Erworbene Kompetenzen
 
- Überwachung von AWS-Abrechnungsmetriken mit CloudWatch
- Erstellen von CloudWatch-Alarmen und -Dashboards
- Bereitstellen serverloser Lambda-Funktionen mit Terraform
- Automatisierung geplanter Aufgaben mit EventBridge
- Speichern und Verwalten von Berichten in S3
- E-Mail-Benachrichtigung über SNS
## Verwendete Werkzeuge
 
- Terraform (Infrastructure as Code)
- AWS: CloudWatch, CloudWatch Alarms, SNS, S3, Lambda, EventBridge, IAM
## Architektur
 
```
CloudWatch Billing Metric (us-east-1)
    → Alarm bei Schwellenwertüberschreitung
        → SNS Topic → Warn-E-Mail
 
EventBridge (jeden Montag um 8 Uhr)
    → Lambda
        → Cost Explorer API
            → HTML-Bericht
                → S3 Bucket
```
 
## Schritte
 
### Ref 1: Multi-Region-Provider
 
AWS-Abrechnungsmetriken sind nur in `us-east-1` verfügbar. Es werden zwei Provider erstellt — ein Standard-Provider in `eu-west-1` und ein Alias in `us-east-1` für den Billing-Alarm.
 
```hcl
provider "aws" {
  region = var.aws_region
}
 
provider "aws" {
  alias  = "us_east"
  region = "us-east-1"
}
```
 
### Ref 2: SNS Topic und E-Mail-Abonnement
 
SNS (Simple Notification Service) verwaltet Benachrichtigungen. Der Alarm veröffentlicht in diesem Topic, das Warnmeldungen per E-Mail an alle Abonnenten weiterleitet.
 
```hcl
resource "aws_sns_topic" "cost_alerts" {
  provider = aws.us_east
  name     = "cost-calculator-cost-alerts"
}
 
resource "aws_sns_topic_subscription" "email" {
  provider  = aws.us_east
  topic_arn = aws_sns_topic.cost_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}
```
 
### Ref 3: CloudWatch-Abrechnungsalarm
 
Der Alarm überwacht die Metrik `EstimatedCharges` und löst aus, wenn die monatlichen Ausgaben den definierten Schwellenwert überschreiten, und sendet dann eine E-Mail über SNS.
 
```hcl
resource "aws_cloudwatch_metric_alarm" "billing_alarm" {
  provider            = aws.us_east
  alarm_name          = "cost-calculator-billing-alert"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = 86400
  statistic           = "Maximum"
  threshold           = var.alert_threshold_usd
  alarm_actions       = [aws_sns_topic.cost_alerts.arn]
  dimensions = {
    Currency = "USD"
  }
}
```
 
### Ref 4: CloudWatch-Dashboard
 
Ein Dashboard fasst Kostenmetriken in einem einzigen visuellen Bildschirm zusammen, der direkt über die AWS-Konsole zugänglich ist.
 
```hcl
resource "aws_cloudwatch_dashboard" "cost" {
  dashboard_name = "cost-calculator-dashboard"
 
  dashboard_body = jsonencode({
    widgets = [{
      type = "metric"
      properties = {
        title   = "AWS Monthly Estimated Cost (USD)"
        region  = "us-east-1"
        metrics = [["AWS/Billing", "EstimatedCharges", "Currency", "USD"]]
        period  = 86400
        stat    = "Maximum"
      }
    }]
  })
}
```
 
### Ref 5: Lambda — automatischer Wochenbericht
 
Eine Lambda-Funktion fragt jeden Montag um 8 Uhr die Cost Explorer API ab, generiert einen HTML-Ausgabenbericht nach Service und speichert ihn in S3. EventBridge löst diese Ausführung automatisch aus.
 
```hcl
resource "aws_cloudwatch_event_rule" "weekly" {
  name                = "cost-calculator-weekly-trigger"
  schedule_expression = "cron(0 8 ? * MON *)"
}
 
resource "aws_lambda_function" "weekly_reports" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "cost-calculator-weekly-report"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_report.lambda_handler"
  runtime       = "python3.12"
  timeout       = 60
}
```
 
## Bereitstellung
 
```bash
terraform init
terraform plan
terraform apply
```
 
> ⚠️ Bestätige nach der Bereitstellung das SNS-Abonnement, indem du auf den per E-Mail erhaltenen Link klickst.
 
## Geschätzte Kosten
 
| Service | Monatliche Kosten |
|---|---|
| CloudWatch Alarm | ~$0.10 |
| CloudWatch Dashboard | ~$3.00 |
| SNS + Lambda + S3 | ~$0.00 (Free Tier) |
| **Gesamt** | **~$3.10/Monat** |
 
 
[⬆️ Zurück zum Menü](#aws-cloud-cost-calculator)
 



