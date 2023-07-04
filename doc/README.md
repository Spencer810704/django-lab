
目錄
- [Introduction](#introduction)
- [Architecture](#architecture)
- [Prerequisite](#prerequisite)
- [Installation](#installation)


# Introduction
該專案目前用於自學如何使用 Jenkins pipeline 透過 Helm3 部署 Kubernetes Application


# Architecture


![](Architecture.jpg)
說明:
1. 開發人員 Push Code 至 Gitlab
2. 建立各環境 Jenkins Job (SIT / STG / PROD)
3. 各環境 Jenkins Job 會使用不同的 Kubeconfig 管理對應環境的namespace
4. 

![](Architecture1.jpg)
說明:
1. 由
2. 


# Prerequisite
- Jenkins ( Use Jenkins pipeline )
- PostgreSQL
- Helm 3
- Kubernetes Cluster
- Docker hub account


# Installation