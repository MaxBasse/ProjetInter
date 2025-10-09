

"""
glouglouton : fonction main de l'algo glouton avec des dictionnaire dedictionnaire (cf pseudo-code en photo)

Arguments :
- df_caract_species (DataFrame) : matrice des espèces (lignes) et de leurs caracteristiques (colonnes) 
avec leur proba
- remaining_species (Vector{Int}) : liste des espèces restantes avant la réponse donnée (sous forme d'identifiant/ encodé)
- accessible_questions (Vector{Int}) : liste des questions accessibles à un certain instant (vecteur d'int(identifiant des questions))
- questions_answers (Vector{Vector{Int}}) : liste des réponses possibles (caractéristiques sous forme d'indentifiant) possible pour chaque question
- question_unlock (Vector{Vector{Int}}) : liste des questions débloquées (sous forme d'indentifiant de question) pour chaque réponse/caractéristique obtenue

Sortie : Retourne notre arbre des questions réponses sous forme de dictionnaire de dictionnaire (à préciser/ pas clair)
"""

function glouglouton(df_caract_species::DataFrame, 
    remaining_species::Vector{Int}, 
    accessible_questions::Vector{Int},
    questions_answers::Vector{Vector{Int}},
    question_unlock::Vector{Vector{Int}} )

    


end
