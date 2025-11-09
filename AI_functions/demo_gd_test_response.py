import json
from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route("/generate-map", methods=["POST"])
def generate_map():
    # Return a plausible test map response
    response = {
        "surface": {
            "type": "forest",
            "segments": [
                {"type": "plains", "length": 100},
                {"type": "city", "length": 100},
                {"type": "mountains", "length": 80}
            ]
        },
        "underground": {
            "type": "caves",
            "tunnels": 1,
            "room_shape": "organic"
        }
    }
    return jsonify(response)

@app.route("/generate-quest", methods=["POST"])
def generate_quest():
    """Generate quest data based on context (lore, NPC type, etc.)"""
    print("\n=== /generate-quest endpoint called ===")
    print(f"Request headers: {dict(request.headers)}")
    print(f"Request data: {request.get_data(as_text=True)}")
    
    try:
        data = request.get_json(force=True)
        print(f"Parsed JSON: {data}")
    except Exception as e:
        print(f"Error parsing JSON: {e}")
        data = {}
    
    context = data.get("context", "") if data else ""
    npc_type = data.get("npc_type", "generic") if data else "generic"
    
    # Placeholder quest data
    response = {
        "quest_id": "quest_demo_collect",
        "quest_name": "Collect Slime Gel",
        "quest_description": "Gather 3 Slime Gels for the alchemist.",
        "objectives": [
            {
                "id": "obj_collect_gel",
                "description": "Collect 3 Slime Gel",
                "objective_type": "collection",
                "target_name": "Slime Gel",
                "required_quantity": 3
            }
        ],
        "rewards": [
            {
                "reward_type": "coins",
                "reward_amount": 75
            }
        ]
    }
    return jsonify(response)

@app.route("/generate-npc", methods=["POST"])
def generate_npc():
    """Generate NPC data including identity, dialog, and behavior"""
    print("\n=== /generate-npc endpoint called ===")
    print(f"Request headers: {dict(request.headers)}")
    print(f"Request data: {request.get_data(as_text=True)}")
    
    try:
        data = request.get_json(force=True)
        print(f"Parsed JSON: {data}")
    except Exception as e:
        print(f"Error parsing JSON: {e}")
        data = {}
    
    context = data.get("context", "") if data else ""
    location = data.get("location", "unknown") if data else "unknown"
    
    # Placeholder NPC data
    response = {
        "npc_id": "npc_demo_alchemist",
        "npc_name": "Alchemist",
        "npc_type": "quest_giver",
        "dialog_trees": [
            {
                "branch_id": "npc_default",
                "dialogs": [
                    {
                        "state": "start",
                        "text": "Greetings! Care to help the alchemist?",
                        "options": {
                            "Sure": "offer_quests",
                            "No": "exit"
                        }
                    },
                    {
                        "state": "offer_quests",
                        "text": "Bring me 3 Slime Gels.",
                        "options": {
                            "Okay": "exit"
                        }
                    }
                ]
            }
        ]
    }
    return jsonify(response)

@app.route("/generate-item", methods=["POST"])
def generate_item():
    """Generate item data for quest objectives"""
    print("\n=== /generate-item endpoint called ===")
    print(f"Request headers: {dict(request.headers)}")
    print(f"Request data: {request.get_data(as_text=True)}")
    
    try:
        data = request.get_json(force=True)
        print(f"Parsed JSON: {data}")
    except Exception as e:
        print(f"Error parsing JSON: {e}")
        data = {}
    
    item_name = data.get("item_name", "Unknown Item") if data else "Unknown Item"
    context = data.get("context", "") if data else ""
    
    # Placeholder item data - could use AI to generate creative items
    response = {
        "item_name": "Slime Gel",
        "item_type": "quest_item",
        "item_effect": "none",
        "item_texture_path": "res://textures/slime_gel.png",
        "spawn_count": 5,  # Number to spawn on map
        "drop_rate": 0.8,  # 80% chance to drop from slimes
        "description": "A sticky gel extracted from slimes. Used in various alchemical recipes."
    }
    print(f"Returning response: {response}")
    return jsonify(response)

@app.route("/place-npc", methods=["POST"])
def place_npc():
    """Determine NPC placement position based on map data"""
    print("\n=== /place-npc endpoint called ===")
    print(f"Request headers: {dict(request.headers)}")
    print(f"Request data: {request.get_data(as_text=True)}")
    
    try:
        data = request.get_json(force=True)
        print(f"Parsed JSON: {data}")
    except Exception as e:
        print(f"Error parsing JSON: {e}")
        data = {}
    
    map_width = data.get("map_width", 0) if data else 0
    map_height = data.get("map_height", 0) if data else 0
    surface_tiles = data.get("surface_tiles", []) if data else []
    npc_type = data.get("npc_type", "generic") if data else "generic"
    
    # Placeholder placement data
    # For demo, place at x=200 if available
    placement_x = 200
    if map_width > 0:
        # Could use AI to determine best placement based on terrain
        placement_x = min(200, map_width - 50)
    
    response = {
        "placement_x": placement_x,
        "placement_strategy": "surface_spawn",
        "reasoning": "Placed near starting area for easy access"
    }
    print(f"Returning response: {response}")
    return jsonify(response)

if __name__ == "__main__":
    print("Starting Flask server on http://127.0.0.1:8000")
    print("Available endpoints:")
    print("  - POST /generate-map")
    print("  - POST /generate-quest")
    print("  - POST /generate-npc")
    print("  - POST /generate-item")
    print("  - POST /place-npc")
    app.run(host="127.0.0.1", port=8000, debug=True)

