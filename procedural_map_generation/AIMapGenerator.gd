# AIMapGenerator.gd
extends Node

const ENDPOINT := "http://127.0.0.1:8000/generate-map"

# Default level plan structure that matches our map generation system
const DEFAULT_LEVEL_PLAN = {
	"surface": {
		"type": "forest",
		"segments": [
			{ "type": "plains", "length": 100 },
			{ "type": "forest", "length": 80 }
		]
	},
	"underground": {
		"type": "caves",
		"tunnels": 1,
		"room_shape": "organic"
	}
}

# Sends a request to the AI service to generate a map based on lore
func generate_map_from_lore(lore: String, http_request: HTTPRequest) -> void:
	var payload := { "lore": lore }
	var headers := ["Content-Type: application/json"]
	var body := JSON.stringify(payload)

	if not http_request.is_inside_tree():
		push_error("❌ HTTPRequest not in tree")
		return

	var result = http_request.request(ENDPOINT, headers, HTTPClient.METHOD_POST, body)
	if result != OK:
		push_error("⚠️ Failed to send request: %s" % result)
	else:
		print("✅ Request sent successfully with lore:\n'%s'" % lore)

# Parses the AI response and returns a level plan
# In AIMapGenerator.gd, add this function:
func get_default_level_plan() -> Dictionary:
	return {
		"surface": {
			"type": "forest",
			"segments": [
				{"type": "plains", "length": 100},
				{"type": "forest", "length": 80}
			]
		},
		"underground": {
			"type": "caves",
			"tunnels": 1,
			"room_shape": "organic"
		}
	}

# Then update parse_ai_response to use it:
func parse_ai_response(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> Dictionary:
	if result != HTTPRequest.RESULT_SUCCESS:
		push_error("HTTP Request failed with code: " + str(response_code))
		return get_default_level_plan()

	var response_body = body.get_string_from_utf8()
	print("📨 Raw server response:\n", response_body)
	
	var json = JSON.new()
	var parse_error = json.parse(response_body)
	
	if parse_error != OK:
		push_error("JSON Parse Error: " + json.get_error_message())
		return get_default_level_plan()

	var response = json.get_data()
	if not response:
		push_error("Empty response from AI")
		return get_default_level_plan()
	
	# Ensure the response has the required structure
	if not response.has("surface") or not response.surface is Dictionary:
		push_error("Invalid response: missing or invalid 'surface'")
		return get_default_level_plan()
	
	if not response.has("underground") or not response.underground is Dictionary:
		push_error("Invalid response: missing or invalid 'underground'")
		return get_default_level_plan()
	
	# Ensure segments exist and is an array
	if not response.surface.has("segments") or not response.surface.segments is Array:
		push_error("Invalid response: missing or invalid 'segments' array")
		return get_default_level_plan()
	
	print("Successfully parsed AI response")
	return response

# Validates and cleans the level plan from the AI
func _validate_level_plan(plan: Dictionary) -> Dictionary:
	var validated = DEFAULT_LEVEL_PLAN.duplicate(true)
	
	# Validate surface
	if plan.has("surface") and plan.surface is Dictionary:
		if plan.surface.has("type") and plan.surface.type is String:
			validated.surface.type = plan.surface.type
			
		if plan.surface.has("segments") and plan.surface.segments is Array:
			validated.surface.segments = []
			for segment in plan.surface.segments:
				if (segment is Dictionary and 
					segment.has("type") and segment.type is String and
					segment.has("length") and (segment.length is int or str(segment.length).is_valid_int())):
					
					validated.surface.segments.append({
						"type": str(segment.type).to_lower(),
						"length": int(segment.length)
					})
	
	# Validate underground
	if plan.has("underground") and plan.underground is Dictionary:
		if plan.underground.has("type") and plan.underground.type is String:
			validated.underground.type = plan.underground.type
			
		if plan.underground.has("tunnels") and (plan.underground.tunnels is int or str(plan.underground.tunnels).is_valid_int()):
			validated.underground.tunnels = clampi(int(plan.underground.tunnels), 0, 5)
			
		if plan.underground.has("room_shape") and plan.underground.room_shape in ["organic", "flat"]:
			validated.underground.room_shape = plan.underground.room_shape
	
	return validated
