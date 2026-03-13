#!/usr/bin/env python3
"""
Script para conectarse a Trello y mostrar tableros, listas y tarjetas.
Uso: python trello_fetch.py
"""

import os
import json
import urllib.request
import urllib.parse

TRELLO_API_KEY = os.environ.get("TRELLO_API_KEY", "")
TRELLO_TOKEN = os.environ.get("TRELLO_TOKEN", "")
BASE_URL = "https://api.trello.com/1"


def trello_get(path, params=None):
    p = {"key": TRELLO_API_KEY, "token": TRELLO_TOKEN}
    if params:
        p.update(params)
    url = f"{BASE_URL}{path}?{urllib.parse.urlencode(p)}"
    with urllib.request.urlopen(url) as r:
        return json.loads(r.read())


def main():
    if not TRELLO_API_KEY or not TRELLO_TOKEN:
        print("Error: definí las variables de entorno TRELLO_API_KEY y TRELLO_TOKEN")
        print()
        print("  export TRELLO_API_KEY='tu_api_key'")
        print("  export TRELLO_TOKEN='tu_token'")
        return

    print("=== TABLEROS ===\n")
    boards = trello_get("/members/me/boards", {"fields": "name,id,url"})

    for i, board in enumerate(boards):
        print(f"[{i+1}] {board['name']}")
        print(f"    ID: {board['id']}")
        print(f"    URL: {board['url']}")
        print()

    if not boards:
        print("No se encontraron tableros.")
        return

    print("\nIngresá el número del tablero que querés explorar (o Enter para salir): ", end="")
    choice = input().strip()
    if not choice:
        return

    try:
        board = boards[int(choice) - 1]
    except (ValueError, IndexError):
        print("Opción inválida.")
        return

    print(f"\n=== TABLERO: {board['name']} ===\n")

    lists = trello_get(f"/boards/{board['id']}/lists", {"fields": "name,id"})
    cards = trello_get(f"/boards/{board['id']}/cards", {"fields": "name,idList,desc,due,labels"})

    cards_by_list = {}
    for card in cards:
        cards_by_list.setdefault(card["idList"], []).append(card)

    for lst in lists:
        print(f"--- {lst['name']} ---")
        for card in cards_by_list.get(lst["id"], []):
            due = f" [vence: {card['due'][:10]}]" if card.get("due") else ""
            labels = ", ".join(l["name"] for l in card.get("labels", []) if l.get("name"))
            label_str = f" ({labels})" if labels else ""
            print(f"  • {card['name']}{due}{label_str}")
            if card.get("desc"):
                desc_preview = card["desc"][:100].replace("\n", " ")
                print(f"    ↳ {desc_preview}{'...' if len(card['desc']) > 100 else ''}")
        print()


if __name__ == "__main__":
    main()
