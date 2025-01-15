#  Analyse des Déterminants du Recours aux Consultations Médicales en Suisse

Ce projet vise à analyser les déterminants du recours aux consultations médicales en Suisse à l'aide de données de panel. Le travail a été réalisé dans le cadre du **Devoir Panel Data** pour le Master II à l'Université de Lille (Décembre 2024). Ce README fournit une description des étapes de l'analyse, des fichiers utilisés et des résultats obtenus.


## Structure du Projet

### Fichiers Principaux

1. **`PSM1016_1860_bal.dta`** : Fichier de données initial contenant les informations sur les consultations médicales et les variables socio-économiques, démographiques et de santé.
2. **`analyse_consultations.log`** : Fichier journal (log) enregistrant toutes les commandes Stata exécutées et leurs résultats.
3. **`health_data_base.dta`** : Fichier de données nettoyé et préparé après la sélection et le renommage des variables.
4. **`base_visit.dta`** : Fichier de données final après nettoyage, transformation et création de nouvelles variables.
5. **`histogram_nbre_consul.png`** : Graphique exporté montrant la distribution du nombre de consultations médicales.


## Étapes de l'Analyse

### 1. Configuration Initiale
- Nettoyage de l'environnement de travail.
- Ouverture d'un fichier journal pour enregistrer les résultats.

### 2. Importation et Préparation des Données
- Importation des données depuis `PSM1016_1860_bal.dta`.
- Sélection et renommage des variables pertinentes.
- Sauvegarde des données préparées dans `health_data_base.dta`.

### 3. Nettoyage et Transformation des Données
- Filtrage des données pour éliminer les valeurs aberrantes.
- Gestion des valeurs manquantes et imputation des valeurs négatives.
- Recodage des variables catégorielles (état civil, satisfaction, etc.).
- Création de nouvelles variables (IMC, quintiles de revenu, etc.).

### 4. Statistiques Descriptives et Graphiques
- Calcul des statistiques descriptives pour les variables clés.
- Génération de graphiques pour visualiser la distribution des consultations médicales et leurs relations avec d'autres variables.

### 5. Modélisation Économétrique
- Estimation de modèles économétriques pour analyser les déterminants des consultations médicales :
  - Modèle pooled binomial négatif robuste.
  - Modèle à effets fixes.
  - Modèle à effets aléatoires.
- Comparaison des modèles à l'aide du test de Hausman.

### 6. Résultats et Diagnostics
- Présentation des résultats des modèles économétriques.
- Diagnostic des résidus et vérification des hypothèses des modèles.

### 7. Conclusion
- Synthèse des résultats et interprétation des déterminants significatifs.
- Recommandations pour les politiques de santé.


## Commandes Stata Clés

### Importation et Préparation des Données
```stata
use "C:\Users\nosty\Desktop\MASTER II\Donnees Panel\TD\DEVOIR PANEL\PSM1016_1860_bal.dta"
xtset IDPERS year
save "health_data_base.dta", replace