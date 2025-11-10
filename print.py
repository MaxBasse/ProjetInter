# Python code to load the uploaded JSON tree and print a readable ASCII visualization.
# This will run here and print the tree to the notebook output for you.
import json
from pathlib import Path

DATA_PATH = Path("arbre.json")

def load_tree(path=DATA_PATH):
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)

def is_leaf(node):
    return ("species" in node and node.get("branches") is None) or ("branches" not in node and "species" in node)

def print_tree(node, name="root", prefix=""):
    """
    Recursively prints the tree using ASCII branch characters.
    - node: dictionary for this node
    - name: label to show for the node (branch id or 'root')
    - prefix: string used to align children
    
    We display for each node:
      name [question: N] (if present)
      species: [..] (if present)
    Then the node's branches
    """
    # Compose the main line for this node
    parts = [str(name)]
    if isinstance(node, dict) and "question" in node:
        parts.append(f"[Q{node['question']}]")
    line = " ".join(parts)
    print(prefix + line)
    
    # Print species if present
    if isinstance(node, dict) and "species" in node:
        print(prefix + "  " + "species: " + json.dumps(node["species"], ensure_ascii=False))

    # If there are branches, iterate and recurse
    if isinstance(node, dict) and "branches" in node and node["branches"]:
        keys = list(node["branches"].keys())
        for i, k in enumerate(keys):
            child = node["branches"][k]
            last = (i == len(keys) - 1)
            branch_char = "└── " if last else "├── "
            next_prefix = prefix + ("    " if last else "│   ")
            # Print the connector and recurse for child
            print(prefix + branch_char + str(k) + (f" [Q{child['question']}]" if isinstance(child, dict) and "question" in child else ""))
            # Print species for child directly under it (if present)
            if isinstance(child, dict) and "species" in child:
                print(prefix + ("    " if last else "│   ") + "species: " + json.dumps(child["species"], ensure_ascii=False))
            # Recurse into deeper branches
            if isinstance(child, dict) and "branches" in child and child["branches"]:
                # For deeper recursion we call a helper that prints children with the correct prefix
                _print_branches(child["branches"], prefix + ("    " if last else "│   "))

def _print_branches(branches_dict, prefix):
    keys = list(branches_dict.keys())
    for i, k in enumerate(keys):
        child = branches_dict[k]
        last = (i == len(keys) - 1)
        branch_char = "└── " if last else "├── "
        print(prefix + branch_char + str(k) + (f" [Q{child['question']}]" if isinstance(child, dict) and "question" in child else ""))
        if isinstance(child, dict) and "species" in child:
            print(prefix + ("    " if last else "│   ") + "species: " + json.dumps(child["species"], ensure_ascii=False))
        if isinstance(child, dict) and "branches" in child and child["branches"]:
            _print_branches(child["branches"], prefix + ("    " if last else "│   "))

# Load and print the whole tree
tree = load_tree()
print("Tree visualization of /mnt/data/arbre.json\n")
print_tree(tree, name="(root)")

