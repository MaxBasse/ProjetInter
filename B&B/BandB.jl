"""


lexique :

    Branch and Bound : l'abre d'énumération des clé de determinations (partielles ou totales)

    Arbre ou clé de determination partielles : arbre qui correspond à un noeud du B&Bound

    Qa : ensembles des questions accessible à un moment donné 

    E : ensemble des especes accessibles à un moment donné du code 

Code écrit en francais : 

    initialisation du B&B : le premier sommet correspond à l'ensemble des clés de déterminations possible
    en ayant en parametre Qa et E

    initialisation de la borne sup : on a besoin d'une borne sup réalisable selon un critère (profondeur, largeur, ...)
    Pour cela on on calculera initialement le glouton qui servira de modele de solution realisable en borne sup.

    branchement sur le premier sommet du B&B : on crée autant de noeud fils qu'il y a de questions accessibles. 
    Chaque noed fils correspondra à une clé de determination partielles où Qa sera fixé en première question. 
    Si l'on suppose que Qa est binaire, on a donc deux noeuds fils dans la clé de determination. 
    Chaque noeud fils de la clé de determination aura son propre E et son Qa. 
    On évalue le premier noeud fils du B&B, si la borne inf de ce noeud est moins bonne que la borne sup on élage.
    Sinon on branche.
    On peut remettre à jour la borne sup des que l'on a un nouveau noeud du B&B, 
    en faisant tourner un glouton sur la clé de dtermination partielle qui correspond au noeud.





Pseudo Code : 

ALGORITHME Branch_and_Bound(Qa_initial, E_initial)

    # initialisation de déclarations des variables
    # on attribue les caracteristiques propres à chaque noeud au noeud initial (la racine)
    # les carac : Qa : Questions accessibles, E : ensemble des especes disponibles, clé partielle correspondante, la profondeur du sommet dans le B&B
    créer la racine :
        racine.Qa = Qa_initial
        racine.E = E_initial
        racine.cle_partielle = ∅
        racine.cle_partielle.feuille
        racine.cle_partielle.feuille.question_accessibles # tout un tas de caracterisitque sur la clé partielle associée à un noeud
        racine.profondeur = 0

    # Calcul initial de la borne supérieure (solution réalisable)
    (borne_sup, sol_glouton) = Glouton(Qa_initial, E_initial)
    meilleure_solution = sol_glouton

    # Initialisation de la liste des noeuds à explorer
    ListeNoeuds = racine

    TANT QUE ListeNoeuds n’est pas vide :

        1. Sélection d’un noeud à explorer selon un critère de parcours en largeur ou profondeur
        noeud = selection_noeud(ListeNoeuds)

        2. evaluation de la borne inf de ce noeud (selon le critère de E/2 par exemple)
        borne_inf = Evaluer_Borne_Inf(noeud)

        3. Peut on élager ce noeud tels des gaziers bucherons 
        SI borne_inf ≥ borne_sup :
            Supprimer(noeud)    
            CONTINUER
        FIN SI

        4. Test si le noeud correspond à une clé de determination totale
        SI Est_une_cle_determination_totale(noeud) :
            coût_solution = Evaluer(noeud)

            SI coût_solution < borne_sup : (on MAJ la borne sup)
                borne_sup = coût_solution
                meilleure_solution = noeud.cle_partielle (qui est en vrai une clé totale ici)
            FIN SI

        SINON
            5. Branchement on crée les possibilités fils 
            POUR chaque question q DANS noeud.Qa FAIRE
                créer noued :
                    _nouveau_noeud = branchement(noeud)
                    # on enleve celle que l'on vient de poser et ajoute celles que l'on vient de débloquer
                    # adapter les especes disponibles suite à la questions posée
                    # creer une nouvelle clé de determination ou l'on a ajouté le split du à la question posée
                    Ajouter NOEUD à ListeNoeuds

            FIN POUR

            # mise à jour de la borne sup sur la nouvelle cle partrielle 
            (borne_sup_locale, sol_locale) ← Glouton(noeud.Qa, noeud.E)
            SI borne_sup_locale < borne_sup ALORS
                borne_sup = borne_sup_locale
                meilleure_solution = sol_locale
            FIN SI

        FIN SI

        Supprimer(noeud)  # On a exploré ce noeud

    FIN TANT QUE

    RETOURNER (meilleure_solution, borne_sup)
FIN ALGORITHMEE4

    """
include("GloutonPartiel.jl")
include("../Glouton/glouton.jl")

# Structure d’un noeud B&B #
 

struct Noeud
    cle_partielle::Dict{Symbol, Any}           # Clé de détermination partielle
    borne_inf::Int              # bonr einf associée à chaque noeud du B&B 
end

#   Algorithme Branch & Bound    #

function Branch_and_Bound(Qa_initial, E_initial, df_caract_species, question_unlock, questions_answers)

      
    # 1. Initialisation du noeud racine et des variables B&B  #
      
    sol_glouton = glouglouton(df_caract_species, E_initial, Qa_initial, questions_answers, question_unlock)

    # Calcul initial de la borne supérieure via le glouton
    borne_sup = profondeur_arbre(sol_glouton)
    meilleure_solution = sol_glouton
    racine = Noeud(
        Dict(
        :profondeur => 0,
        :questions_accessibles => copy(Qa_initial),
        :questions_posees => Int[],
        :especes_restantes => copy(E_initial),
        :question => -1,
        :branches => Dict{Int, Any}()
    ), 
        0
    )


    # Liste des noeuds à explorer, soit une file pour largeur soit une pile pour profondeur
    ListeNoeuds = [racine]


     
    # 2. Boucle principale du B&B     

    while !isempty(ListeNoeuds)

    
        # 2.1 Sélection d’un noeud selon une stratégie (profondeur, largeur ?) #
          
        noeud = pop!(liste_noeuds)  


          
        # 2.2 Calcul de la borne inférieure   #
          
        borne_inf = evaluation(noeud)


          
        # 2.3 Test afin de savoir si on peut élaguer tels des bucherons gaziers
          
        if borne_inf >= borne_sup
            # badaboum on élague (en gros on fait R)
            continue
        end


          
        # 2.4 Test si la clé partielle s'avère plutot etre une clé totalement définie (chaque feuille est vide ou une espece) #
          
        if Est_une_cle_determination_totale(noeud)

            cout_solution = Evaluer(noeud)

            # Mise à jour de la borne supérieure si amélioration
            if cout_solution < borne_sup
                borne_sup = cout_solution
                meilleure_solution = noeud.cle_partielle
            end

        else

               
            # 2.5 Branchement : création des noeuds fils          #
               
            noeud_inter=branchement(Noeud.Qa)
            liste_noeud=append!(liste_noeud, noeud_inter)


            
            # 2.6 Mise à jour de la borne sup via glouton sur clé partielle (pas sur de MAJ a chaque fois mais on laisse comme cela pour l'instant)
            borne_sup_locale, sol_locale = glouton_borne_inf(Noeud, df_caract_species, questions_answers, question_unlock)

            if borne_sup_locale < borne_sup
                borne_sup = borne_sup_locale
                meilleure_solution = sol_locale
            end
        end

        # Fin du traitement du noeud -> il est sorti de la liste via selection_noeud!
    end



    return meilleure_solution, borne_sup
end


function Est_une_cle_determination_totale(Noeud)
    # fonction qui prend un noeud du B&B en parametre et qui vérifie si sa clé de determination associée est totale ou bien partielle 
    cle=Noeud.cle_partielle
    return cle_totale_recursive(cle)
end

function cle_totale_recursive(cle::Dict{Symbol,Any})::Bool

    branches = cle[:branches]

    # Si on est sur une feuille, on vérifie le nombre d'espece restante
    if isempty(branches)
        nb = length(cle[:especes_restantes])
        return nb <= 1
    end

    # Sinon, on fait de la recursivité sur les autres branches
    for (_, souscle) in branches
        if !cle_totale_recursive(souscle)
            return false
        end
    end
    # c'est que une fois que l'on a parcouru toutes les feuilles sans retourner false que l'on peut enfin retrouner true.
    return true
end


cle_totale = Dict(
    :profondeur => 0,
    :especes_restantes => [1,2,3],
    :branches => Dict(
        10 => Dict(
            :profondeur => 1,
            :especes_restantes => [1],
            :branches => Dict()
        ),
        20 => Dict(
            :profondeur => 1,
            :especes_restantes => [2],
            :branches => Dict()
        ),
        30 => Dict(
            :profondeur => 1,
            :especes_restantes => [3,1],
            :branches => Dict()
        )
    )
)

print(cle_totale_recursive(cle_totale))