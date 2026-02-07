import json
import time
from random import randrange
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from typing import Dict, Any, List

app = FastAPI()

# In-memory storage for games (for demo purposes)
games: Dict[str, Dict[str, Any]] = {}

@app.post("/level/generate")
async def generate_map(request: Request):
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
            "tunnels": 3,
            "room_shape": "organic"
        }
    }
    return JSONResponse(content=response)

#test comment
@app.post("/content/quest")
async def generate_quest(request: Request):
    """Generate quest data based on context (lore, NPC type, etc.)"""
    print("\n=== /generate-quest endpoint called ===")
    
    try:
        data = await request.json()
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
    return JSONResponse(content=response)

@app.post("/content/npc")
async def generate_npc(request: Request):
    """Generate NPC data including identity, dialog, and behavior"""
    print("\n=== /generate-npc endpoint called ===")
    
    try:
        data = await request.json()
        print(f"Parsed JSON: {data}")
    except Exception as e:
        print(f"Error parsing JSON: {e}")
        data = {}
    
    context = data.get("context", "") if data else ""
    location = data.get("location", "unknown") if data else "unknown"
    
    # Placeholder NPC data with enhanced dialog branches
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
            },
            {
                "branch_id": "quest_in_progress",
                "dialogs": [
                    {
                        "state": "start",
                        "text": "Hello again! Have you collected those 3 Slime Gels yet?",
                        "options": {
                            "Still working on it": "exit",
                            "Where can I find them?": "exit"
                        }
                    }
                ]
            },
            {
                "branch_id": "post_quest_completion",
                "dialogs": [
                    {
                        "state": "start",
                        "text": "Thank you so much for the slime gel! Your reward has been delivered.",
                        "options": {
                            "You're welcome": "exit"
                        }
                    }
                ]
            }
        ]
    }
    return JSONResponse(content=response)

@app.post("/content/item")
async def generate_item(request: Request):
    """Generate item data for quest objectives"""
    print("\n=== /generate-item endpoint called ===")
    
    try:
        data = await request.json()
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
        "spawn_count": 25,  # Number to spawn on map
        "drop_rate": 0.8,  # 80% chance to drop from slimes
        "description": "A sticky gel extracted from slimes. Used in various alchemical recipes."
    }
    print(f"Returning response: {response}")
    return JSONResponse(content=response)

@app.post("/place-npc")
async def place_npc(request: Request):
    """Determine NPC placement position based on map data"""
    print("\n=== /place-npc endpoint called ===")
    
    try:
        data = await request.json()
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
    placement_x = 5
    if map_width > 0:
        # Could use AI to determine best placement based on terrain
        placement_x = min(5, map_width - 50)
    
    response = {
        "placement_x": placement_x,
        "placement_strategy": "surface_spawn",
        "reasoning": "Placed near starting area for easy access"
    }
    print(f"Returning response: {response}")
    return JSONResponse(content=response)

@app.post("/game/new")
async def create_new_game(request: Request):
    """Create a new game with initial data"""
    print("\n=== /game/new endpoint called ===")
    try:
        data = await request.json()
        slot_number = data.get("slot_number", 1)
        
        # Generate initial game data
        response = {
            "game_id": slot_number,
            "slot_number": slot_number,
            "timestamp": data.get("timestamp", 0),
            "player_level": 1,
            "location": "Starting Area",
            "map_data": {
                "seed": randrange(10000, 99999),
                "width": 800,
                "height": 600,
                "biome": "forest"
            },
            "npc_data": {},
            "quest_data": {},
            "player_stats": {
                "health": 100,
                "max_health": 100,
                "mana": 50,
                "max_mana": 50,
                "coins": 0
            }
        }
        
        # Store in memory for demo purposes
        games[str(slot_number)] = response
        
        print(f"Created new game for slot {slot_number}")
        return JSONResponse(content=response)
        
    except Exception as e:
        print(f"Error creating new game: {e}")
        return JSONResponse(content={"error": str(e)}, status_code=500)

@app.get("/game/{game_id}/load")
async def load_game(game_id: int):
    """Load existing game data"""
    print(f"\n=== /game/{game_id}/load endpoint called ===")
    
    try:
        # Check if game exists in memory
        game_key = str(game_id)
        if game_key in games:
            response = games[game_key]
        else:
            # In a real implementation, you'd load this from a database
            # For now, return sample saved game data
            response = {
                "game_id": game_id,
                "timestamp": int(time.time()) - 86400,  # Yesterday
                "player_level": 5,
                "location": "Forest Area",
                "map_data": {
                    "seed": 12345,
                    "width": 800,
                    "height": 600,
                    "biome": "forest",
                    "surface_tiles": [[i, 100 + randrange(-10, 10)] for i in range(800)]
                },
                "npc_data": {
                    "alchemist": {
                        "npc_id": "npc_demo_alchemist",
                        "npc_name": "Alchemist",
                        "position": [200, 150]
                    }
                },
                "quest_data": {
                    "active_quests": ["collect_slime_gel"],
                    "completed_quests": []
                },
                "player_stats": {
                    "health": 85,
                    "max_health": 100,
                    "mana": 30,
                    "max_mana": 50,
                    "coins": 150
                }
            }
        
        print(f"Loaded game {game_id}")
        return JSONResponse(content=response)
        
    except Exception as e:
        print(f"Error loading game {game_id}: {e}")
        return JSONResponse(content={"error": str(e)}, status_code=500)

@app.post("/game/{game_id}/save")
async def save_game(game_id: int, request: Request):
    """Save current game data"""
    print(f"\n=== /game/{game_id}/save endpoint called ===")
    
    try:
        game_data = await request.json()
        
        # Store in memory for demo purposes
        games[str(game_id)] = game_data
        
        # In a real implementation, you'd save this to a database
        # For now, just acknowledge the save
        response = {
            "success": True,
            "game_id": game_id,
            "timestamp": game_data.get("timestamp", int(time.time())),
            "saved_data": game_data
        }
        
        print(f"Saved game {game_id}")
        return JSONResponse(content=response)
        
    except Exception as e:
        print(f"Error saving game {game_id}: {e}")
        return JSONResponse(content={"error": str(e)}, status_code=500)

@app.delete("/game/{game_id}")
async def delete_game(game_id: int):
    """Delete a saved game and its vector DB"""
    print(f"\n=== /game/{game_id} DELETE endpoint called ===")
    
    try:
        game_key = str(game_id)
        
        if game_key in games:
            del games[game_key]
            return {
                "success": True,
                "message": f"Game {game_id} deleted successfully."
            }
        else:
            return {
                "success": False,
                "error": f"No save found for game_id {game_id}."
            }
            
    except Exception as e:
        return {
            "success": False,
            "error": str(e)
        }

@app.get("/games")
async def list_games():
    """List all saved games"""
    games_list = list(games.values())
    return {
        "success": True,
        "games": games_list,
        "total_games": len(games_list)
    }

if __name__ == "__main__":
    import uvicorn
    print("Starting FastAPI server on http://127.0.0.1:8000")
    print("Available endpoints:")
    print("  - POST /level/generate")
    print("  - POST /content/quest")
    print("  - POST /content/npc")
    print("  - POST /content/item")
    print("  - POST /place-npc")
    print("  - POST /game/new")
    print("  - GET /game/{game_id}/load")
    print("  - POST /game/{game_id}/save")
    print("  - DELETE /game/{game_id}")
    print("  - GET /games")
    uvicorn.run(app, host="127.0.0.1", port=8000)

