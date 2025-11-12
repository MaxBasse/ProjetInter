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
FIN ALGORITHME

    """

