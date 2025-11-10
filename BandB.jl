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