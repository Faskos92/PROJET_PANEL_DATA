********************************************************
* DEVOIR PANEL DATA DEC 2024 U Lille                  **
* Sujet 1 : Déterminants du recours aux consultations **
* médicales en Suisse                                 **
********************************************** *********

******************************************************** 
* 1. Configuration initiale                          
********************************************************
clear all 
set more off 
capture log close 
log using "analyse_consultations.log", replace 

******************************************************* 
* 2. Importation et préparation des données 
******************************************************* 
* Importation des données 
use "C:\Users\nosty\Desktop\MASTER II\Donnees Panel\TD\DEVOIR PANEL\PSM1016_1860_bal.dta"


* description 
describe

xtset IDPERS year
xtdescribe

* Sélection et renommage des variables pertinentes 
keep IDPERS year PxxC15 PxxC01 CIVSTAxx EDYEARxx PxxC19A PxxC06A  PxxI01 WSTATxx SEXxx AGExx PxxD160 REGIONxx HxxH27  PxxC44  PxxN34   PxxA05  IxxPTOTN  PxxW29 PxxC45 PxxC46 HxxH20  PxxW93 PxxC02 PxxF02 PxxF03  

* Sauvegarder la base
save "health_data_base.dta", replace 


* Renommer les  variables 
rename PxxC15 nbre_consul
rename REGIONxx region 
rename SEXxx sexe 
rename AGExx age 
rename IxxPTOTN income_p
rename PxxC01 etat_sante 
rename CIVSTAxx etat_civil 
rename EDYEARxx annee_etude 
rename PxxC19A mldie_chroniq  
rename PxxC06A pblme_sommeil  
rename PxxD160 nssance_suisse 
rename HxxH27 polution 
rename PxxW93 condition_travail 
rename PxxC45 taille_cm 
rename PxxC46 poids_kg 
rename HxxH20 nbre_piece_logmt  
rename PxxC02 satisfaction_sante 
rename PxxF02 satisfait_vivre_ensble 
rename PxxF03 satisfait_vivre_seul 
rename PxxA05 satisfaction_temps_libre 
rename PxxI01 satisfaction_finance 
rename PxxC44 satisfaction_vie 
rename WSTATxx statut_pro 
rename PxxN34 p_club_ou_groupe 
rename PxxW29 type_emploi 

****************************************************** 
* 3. Nettoyage et transformation des données 
****************************************************** 
* Filtrage des données 

keep if nbre_consul >= 0 & nbre_consul< 101 & nssance_suisse >= 0 & income_p >= -5 & income_p != -3



* Vérification des modalités 
tab sexe  
tab satisfait_vivre_ensble  // Trop de Non applicable
tab satisfaction_sante      // A recoder (0-10), 
tab  satisfait_vivre_seul   // A recoder (0-10), -2, -1
tab etat_sante              // Bon état de santé
tab etat_civil              // A recode (1-7)
tab mldie_chroniq           // Gestion de (-2, -1)
tab pblme_sommeil           // Gestion de (-1)
tab satisfaction_finance    // A recoder (0-10),(-2, -1)
tab polution                // Gestion de (-1), -3()
tab satisfaction_vie        // A recoder (0-10),(-1)
tab p_club_ou_groupe        // Gestion de (-1), -3(1)
tab satisfaction_temps_libre // Gestion de (-1,-2),-3(1)
tab type_emploi            // Gestion de (-1,-2),-3(928)
tab condition_travail      // Gestion de -3 Tot (931)
tab nbre_piece_logmt       // Gestion de -3 Total (931)


* Remplacement des valeurs manquantes -3(Non applicable)

foreach var of varlist * { 
    replace `var' = . if `var' == -3 
} 

* Imputation des valeurs negatives  sauf income par le mode si nombre inf 1%
** Calculer le mode en excluant les valeurs -1 et -2
** Remplacer les valeurs -1 et -2 par le mode
** Supprimer la variable temporaire contenant le mode

foreach var in  pblme_sommeil satisfaction_finance  polution  p_club_ou_groupe satisfaction_temps_libre  type_emploi  mldie_chroniq satisfait_vivre_seul satisfait_vivre_ensble  satisfaction_vie {
    egen mode_`var' = mode(`var') if `var' != -1 & `var' != -2
   
    replace `var' = mode_`var' if `var' == -1 | `var' == -2

    drop mode_`var'
}

* Pour le revenu personnel: Remplacer les valeur négatives par NA puis les imputers par la moyenne de l'année

replace income_p = . if income_p < 0

egen mean_income_p = mean(income_p), by(year)
replace income_p = mean_income_p if missing(income_p)


* Calculer la mean  de taille_cm en excluant les valeurs négatives et remplacer ces val par la moyenne
egen mean_taille = mean(taille_cm) if taille_cm >= 0
replace taille_cm = mean_taille if taille_cm < 0

* Calculer la moyenne de poids_kg en excluant les valeurs négatives et remplacer ces val par la moyenne
egen mean_poids = mean(poids_kg) if poids_kg >= 0
replace poids_kg = mean_poids if poids_kg < 0



**************************************************************
* Création de categorie manquantes pour certaines variables
**************************************************************
* 1- Type d'emploi: 0= manquant
replace type_emploi = 0 if missing(type_emploi)

* Condition de travail: condition_travail: 11 = Manquant
replace condition_travail = 11 if missing(condition_travail)

* Satisfaction vivre ensemble satisfait_vivre_ensble: 11= Manquant
replace satisfait_vivre_ensble = 11 if missing(satisfait_vivre_ensble)


***********************************************************
* * Regrouper les variables : Satisfaction
***********************************************************

foreach var of varlist satisfaction_sante satisfait_vivre_ensble satisfait_vivre_seul satisfaction_temps_libre satisfaction_finance satisfaction_vie condition_travail {
    quietly summarize `var'
    local max = r(max)
    if `max' == 10 {
        recode `var' (0/4=1) (5/6=2) (7/8=3) (9/10=4) (missing=5), generate(`var'_cat)
    }
    else if `max' == 11 {
        recode `var' (0/4=1) (5/6=2) (7/8=3) (9/10=4) (11=5) (missing=5), generate(`var'_cat)
    }
    else {
        display "Échelle non reconnue pour la variable `var'. Valeur max = `max'"
        continue
    }
    drop `var'
    rename `var'_cat `var'
}


label define satisfaction_labels 1 "Très insatisfait" 2 "Plutôt insatisfait" 3 "Plutôt satisfait" 4 "Très satisfait" 5 "Manquant"

label values satisfaction_sante satisfaction_labels


* Regrouper état civil 
gen etat_civil_r = .
replace etat_civil_r = 1 if etat_civil == 1 // Célibataire

replace etat_civil_r = 2 if inlist(etat_civil, 2, 6) // Marié ou en partenariat

replace etat_civil_r = 3 if inlist(etat_civil, 3, 4, 7) // Séparé, divorcé, partenariat dissous

replace etat_civil_r = 4 if etat_civil == 5 // Veuf/veuve

label define etat_civil_lbl 1 "Célibataire" 2 "Marié ou en partenariat" 3 "Séparé, divorcé, partenariat dissous" 4 "Veuf/veuve"
label values etat_civil_r etat_civil_lbl
* Valeurs Non applicable (NA)
misstable summarize

*******************************************************
* Création de nouvelles variables
******************************************************

* Création d'une var synth pour la satisfaction : ACM 
mca satisfaction_sante satisfait_vivre_ensble satisfait_vivre_seul satisfaction_temps_libre satisfaction_finance satisfaction_vie, dim(2)


* Visualiser le graphique
mca, plot

* Création de la variable:
predict satisfaction_dim1 satisfaction_dim2

generate satisfaction = (satisfaction_dim1 + satisfaction_dim2) / 2


* Création de nouvelles variables  age^2 et imc ,log_income_p sd_annee_etude

gen age2 = age^2 

* Créer une nouvelle variable pour les quintiles de income_p
xtile income_quintile = income_p, nq(5)
label define income_lbl 1 "Très pauvre" ///
                      2 "Pauvre" ///
                      3 "Classe moyenne" ///
                      4 "Riche" ///
                      5 "Très Riche"

label values income_quintile income_lbl


*Imc 
gen imc = poids_kg / ((taille_cm/100)^2) 

* Regrouper les types d'emploi
gen emploi_regroupe = .
replace emploi_regroupe = 1 if type_emploi == 5 | type_emploi == 1  // Salarié ou Contrat court
replace emploi_regroupe = 2 if type_emploi == 0 | type_emploi == 4  // Non salarié ou Indépendant
replace emploi_regroupe = 3 if type_emploi == 2  // Temps partiel
replace emploi_regroupe = 4 if type_emploi == 3  // Temps plein

label define emploi_lbl 1 "Emploi salarié" 2 "Emploi non salarié" 3 "Temps partiel" 4 "Temps plein"
label values emploi_regroupe emploi_lbl


* Viz données manquantes
misstable summarize

* Sauvegarde des données nettoyées 
save "base_visit.dta", replace 


* Suppression des Non applicable: Car moins de 5% des données

foreach var of varlist * {
    drop if missing(`var')
}

* Retenir que le nombre de consultations < 100: pour plus de clartée
summarize nbre_consul


********************************************** 
* 5. Statistiques descriptives et graphiques 
********************************************** 
xtset IDPERS year
xtdescribe 

* Statistiques descriptives 
* Gblobal unvariée
sum nbre_consul age  annee_etude  nbre_piece_logmt imc

tab sexe
tab income_quintile 
tab region 
tab nssance_suisse 
tab mldie_chroniq  
tab condition_travail
tab polution
tab region

asdoc clear
local variables "sexe income_quintile mldie_chroniq condition_travail nssance_suisse polution etat_civil_r pblme_sommeil type_emploi region"
foreach var in `variables' {
    asdoc tabulate `var', replace
}



histogram nbre_consul , normal width(1) title("Distribution des consultations")

* Exporter le graphique 
graph export "histogram_nbre_consul.png", replace 

* Bivariées

*Temporelle
bysort year : sum nbre_consul annee_etude

graph bar (mean) nbre_consul , over(year)

* Graphique: evolution des consultation selon l'age
twoway (scatter nbre_consul age) (lfit nbre_consul age), ///
    title("Relation entre le nombre de consultations et l'âge") ///
    xlabel(, grid) ylabel(, grid)

* Graphique: Distribution selon l'existance ou non de maladie chronique
graph box nbre_consul, over(mldie_chroniq) ///
    title("Boxplot des consultations par maladie chronique") ///
    asyvars ///
    box(1, fcolor(blue%50)) ///
    box(2, fcolor(red%50)) ///
    legend(on) ///
    ytitle("Nombre de consultations")


* Table: Moyenne de groupe

* Calculer les statistiques descriptives par sexe
tabstat nbre_consul, by(sexe) statistics(N mean sd min max)

* Calculer les statistiques descriptives par région
tabstat nbre_consul, by(region) statistics(N mean sd min max)

* Moyenne des consultations par tranche de revenu 
tabstat nbre_consul, by(income_quintile) statistics(N mean sd min max)


* Comparaison avec conditions de travail
tabstat nbre_consul, by(condition_travail) statistics(N mean sd min max)

* Comparaison avec problèmes de sommeil
tabstat nbre_consul, by(pblme_sommeil) statistics(N mean sd min max)

* Comparaison avec etat_civil
tabstat nbre_consul, by(etat_civil_r) statistics(N mean sd min max)

* Comparaison avec emploi_regroupe
tabstat nbre_consul, by(emploi_regroupe) statistics(N mean sd min max)

* Comparaison avec naissance en suisse
tabstat nbre_consul, by(nssance_suisse) statistics(N mean sd min max)

* Comparaison avec etat de santé 
tabstat nbre_consul, by(etat_sante) statistics(N mean sd min max)

* Tests statistiques

* Corrélations 
pwcorr nbre_consul nbre_piece_logmt age annee_etude satisfaction imc  

* ANOVA 
oneway nbre_consul sexe 
oneway nbre_consul region 
oneway nbre_consul income_quintile
oneway nbre_consul condition_travail
oneway nbre_consul pblme_sommeil
oneway nbre_consul etat_civil_r
oneway nbre_consul emploi_regroupe
oneway nbre_consul nssance_suisse
oneway nbre_consul etat_sante



********************************************** 
* 6. Modélisation économétrique 
********************************************** 

* Vérification de la surdispersion 
tabstat nbre_consul, statistics(mean var) 

*===> Surdispersion. Cela est il lié a un excès de zéros ?

* Vérification de l'excès de zéros : 
poisson nbre_consul 
predict yhat 
gen zero_obs = (nbre_consul == 0) 
gen zero_pred = exp(-yhat) 

* Table 
tabstat zero_obs zero_pred, statistics(mean) columns(statistics) 

* ==> Pas d'excès de zéros

** Procédure:

* Essai poisson 
* Modèles vides et test du rapport de vraisemblance avec un BN
eststo poisson_vide: poisson nbre_consul 


eststo nbreg_vide: nbreg nbre_consul 

estimates table poisson_vide  nbreg_vide, b(%9.4f) stats(N) star

estimates table poisson_vide nbreg_vide, stats(aic bic)  star
*lrtest poisson_vide nbreg_vide 


***************************************************
* 6-1 Modèle pooled binomial négatif robuste 
***************************************************


* Modèle avec que les années
nbreg nbre_consul i.year, vce(robust)

* Modèle pooled
eststo nbreg_pooled:  nbreg nbre_consul  c.age c.age2 i.sexe  c.annee_etude i.etat_sante i.mldie_chroniq i.region  i.income_quintile  c.satisfaction c.imc i.etat_civil_r  , vce(robust) 

** Verif des hypothèses
predict resid, score
* Vérification de la normalité des résidus avec sktest
sktest resid  // Test de normalité de Skewness et Kurtosis 

* Q-Q plot pour les résidus
qnorm resid  


***************************************************
* 6-2 Modèles à effets fixes et aléatoires 
***************************************************

xtset IDPERS year

* Modèle a effets fixes
eststo nbreg_FE:  xtnbreg nbre_consul  c.age c.age2 i.sexe  c.annee_etude i.etat_sante i.mldie_chroniq i.region  i.income_quintile  c.satisfaction c.imc i.etat_civil_r ,fe 



* Modèle a effets aléatoires

eststo nbreg_RE:  xtnbreg nbre_consul  c.age c.age2 i.sexe  c.annee_etude i.etat_sante i.mldie_chroniq i.region  i.income_quintile  c.satisfaction c.imc i.etat_civil_r ,re 



* Test de Hausman 
hausman nbreg_FE nbreg_RE

** Preference pour le modele a effets fixes 



********************************************** 
* 7. Résultats et diagnostics 
********************************************** 
estimates table nbreg_pooled nbreg_FE nbreg_RE, stats(N ll aic bic) b(%9.5f) star(0.1 0.05 0.01)


********************************************** 
* 8. Conclusion et nettoyage 
********************************************** 


log close






