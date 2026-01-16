# AI-Integrated Dynamic Gameplay System

A comprehensive AI-powered content generation system for Godot 2D games that creates unique, personalized gameplay experiences by tracking player behavior and dynamically generating levels, NPCs, dialogs, and game content.

## Overview

This system analyzes player actions and play patterns to build a behavioral profile, then uses AI (local or cloud-based LLMs) to generate content that adapts to each player's unique style. Every playthrough feels distinct and tailored to how you play.

**Key Features:**
- 🎮 **Player Behavior Tracking**: Monitors combat style, dialog choices, exploration patterns, and interactions
- 🧠 **AI-Powered Generation**: Uses LLMs to create dynamic levels, NPCs, and dialogs
- 🎯 **Personalized Content**: Adapts to your playstyle (combat-focused, exploration, story-driven, etc.)
- ⚡ **Performance-First**: Optimized for low-spec hardware with aggressive caching and background processing
- 🔄 **Graceful Degradation**: Falls back to rule-based generation when AI is unavailable
- 🎨 **Seamless Integration**: Works with existing Godot systems (inventory, quests, combat, UI)

## Architecture

The system is built in layers:

```
Game Layer (GDScript)
    ↓
AI Integration Layer (Tracking, Profiling, Content Management)
    ↓
Generation Layer (Level, NPC, Dialog Generators)
    ↓
AI Service Layer (Local LLM, Cloud LLM, Rule-Based Fallback)
```

### Core Components

1. **Player Action Tracker**: Records all player actions (combat, dialog, exploration, interactions)
2. **Behavior Profiler**: Analyzes action history to compute behavioral profiles
3. **Content Manager**: Coordinates all AI generation requests with threading and caching
4. **Level Generator**: Creates dynamic levels influenced by player behavior
5. **NPC Story Engine**: Generates unique NPC personalities, backstories, and quest hooks
6. **Dialog Generator**: Creates contextual conversations that reference player history
7. **AI Service Router**: Routes requests to appropriate AI services with fallback logic
8. **Content Validator**: Validates and sanitizes all AI-generated content

## Getting Started

### Prerequisites

- Godot 4.x
- GDScript knowledge
- (Optional) API keys for cloud LLM services (OpenAI, Anthropic)
- (Optional) Local LLM setup (llama.cpp, GGUF models)

### Installation

1. Clone this repository into your Godot project:
   ```bash
   git clone https://github.com/sujeeth66/AI-game.git
   ```

2. Enable the plugin in Godot:
   - Project → Project Settings → Plugins
   - Enable "AI Integrated Gameplay"

3. Configure AI services:
   - Copy `res://addons/ai_gameplay/config.example.json` to `config.json`
   - Add your API keys or configure local model paths

### Basic Usage

```gdscript
# In your game script
extends Node

var action_tracker: PlayerActionTracker
var content_manager: ContentManager

func _ready():
    # Initialize the AI system
    action_tracker = PlayerActionTracker.new()
    content_manager = ContentManager.new()
    
    # Connect signals
    content_manager.generation_complete.connect(_on_content_generated)
    
    # Track player actions
    action_tracker.record_combat_action("aggressive", enemy, "victory")
    action_tracker.record_dialog_choice(npc_id, "I'll help you", "diplomatic")
    
    # Request AI-generated content
    var context = GenerationContext.new()
    context.behavior_profile = profiler.get_current_profile()
    content_manager.request_level_generation(context)

func _on_content_generated(request_id: int, content: Variant):
    # Use the generated content
    if content is LevelData:
        apply_level(content)
```

## Features in Detail

### Player Behavior Tracking

The system tracks:
- **Combat**: Aggressive, defensive, stealth, magic-focused styles
- **Dialog**: Aggressive, diplomatic, curious, deceptive choices
- **Exploration**: Thorough, speedrun, treasure-hunting, story-focused patterns
- **Interactions**: Helpful, hostile, neutral, transactional approaches

Actions are weighted by recency using a temporal decay function, so recent behavior has more influence than old patterns.

### Dynamic Level Generation

Levels adapt to your playstyle:
- **Combat-focused players**: Higher enemy density, tactical positions, challenging encounters
- **Exploration-focused players**: More secret areas, branching paths, hidden treasures
- **Story-focused players**: More NPCs, environmental storytelling, narrative locations

### Dynamic NPC Generation

Each NPC gets:
- **Unique personality**: Traits that complement or contrast with your behavior
- **Contextual backstory**: References your actions and game lore
- **Quest hooks**: 2-3 potential quest lines tailored to your interests
- **Dialog style**: Formal, casual, cryptic, etc.

### Dynamic Dialog

Conversations feature:
- **Multiple approaches**: Options for different playstyles (aggressive, diplomatic, curious, deceptive)
- **Contextual responses**: NPCs reference your past actions and previous conversations
- **Consistent personality**: NPCs maintain their character throughout interactions
- **Meaningful consequences**: Dialog choices affect relationships and quest outcomes

### Performance Optimization

The system is optimized for low-spec hardware:
- **Background threading**: All AI generation runs on worker threads (never blocks gameplay)
- **Aggressive caching**: Frequently generated content is cached (100MB cache with LRU eviction)
- **Performance budgets**: Strict time limits for each operation type
- **Adaptive complexity**: Reduces generation complexity if frame rate drops below 30 FPS
- **Pre-generation**: Generates content during idle periods (loading screens, safe zones)
- **Placeholder content**: Provides temporary content if generation is deferred

### AI Service Integration

Supports multiple AI providers:
- **Local LLM**: Uses local model inference (llama.cpp, GGUF models) for offline play
- **Cloud LLM**: Uses cloud APIs (OpenAI, Anthropic) for high-quality generation
- **Rule-Based Fallback**: Template-based generation that always succeeds

Fallback chain: Cloud LLM → Local LLM → Rule-Based (ensures game always works)

### Content Validation

All generated content is validated:
- **Schema validation**: Ensures all required fields are present
- **Text filtering**: Removes inappropriate language using blacklist
- **Range validation**: Clamps numeric values to valid game ranges
- **Consistency checking**: Validates against game lore and existing content
- **Playability validation**: Ensures generated levels are actually playable

## Configuration

Edit `res://addons/ai_gameplay/config.json`:

```json
{
  "ai_provider": "openai",  // "openai", "anthropic", "local", "fallback"
  "api_keys": {
    "openai": "your-api-key-here",
    "anthropic": "your-api-key-here"
  },
  "local_model": {
    "path": "path/to/model.gguf",
    "context_size": 2048
  },
  "performance": {
    "level_generation_budget_ms": 2000,
    "npc_generation_budget_ms": 1000,
    "dialog_generation_budget_ms": 500,
    "cache_size_mb": 100,
    "worker_threads": 2
  },
  "generation": {
    "quality_vs_speed": 0.7,  // 0.0 = speed, 1.0 = quality
    "enable_caching": true,
    "enable_pre_generation": true
  },
  "debug": {
    "enable_logging": false,
    "log_level": "INFO",  // "ERROR", "WARN", "INFO", "DEBUG"
    "enable_mock_responses": false
  }
}
```

## Testing

The system includes comprehensive testing:

### Property-Based Tests (46 properties)

Each correctness property is tested with 100 random iterations:
- Action recording completeness
- Profile computation accuracy
- Level generation variety
- NPC personality variation
- Dialog contextual references
- Performance budget compliance
- Cache behavior
- Fallback chain reliability
- And 38 more...

### Unit Tests

Specific examples and edge cases:
- Specific action types
- Profile computation scenarios
- Error handling
- Integration with Godot systems

### Running Tests

```bash
# Run all tests
godot --headless --script res://addons/ai_gameplay/tests/run_all_tests.gd

# Run specific test suite
godot --headless --script res://addons/ai_gameplay/tests/test_action_tracker.gd
```

## Project Structure

```
res://addons/ai_gameplay/
├── core/
│   ├── player_action_tracker.gd
│   ├── behavior_profiler.gd
│   ├── content_manager.gd
│   └── content_cache.gd
├── generators/
│   ├── level_generator.gd
│   ├── npc_story_engine.gd
│   └── dialog_generator.gd
├── services/
│   ├── ai_service_router.gd
│   ├── local_llm_service.gd
│   ├── cloud_llm_service.gd
│   └── rule_based_fallback.gd
├── validators/
│   └── content_validator.gd
├── data/
│   ├── behavior_profile.gd
│   ├── generation_context.gd
│   ├── level_data.gd
│   ├── npc_data.gd
│   └── dialog_context.gd
├── tests/
│   ├── test_action_tracker.gd
│   ├── test_behavior_profiler.gd
│   ├── test_level_generator.gd
│   └── ... (46 property tests + unit tests)
├── examples/
│   └── demo_scene.tscn
├── config.example.json
└── README.md
```

## Specification Documents

Detailed specifications are available in `.kiro/specs/ai-integrated-gameplay/`:

- **requirements.md**: 11 requirements using EARS patterns (Easy Approach to Requirements Syntax)
- **design.md**: Complete architecture, components, 46 correctness properties, error handling, testing strategy
- **tasks.md**: 20 top-level implementation tasks with 100+ sub-tasks

## Performance Benchmarks

Target performance on low-spec hardware:
- Action recording: < 1ms per action
- Profile computation: < 100ms
- Level generation: < 2000ms
- NPC generation: < 1000ms
- Dialog generation: < 500ms
- Cache lookup: < 1ms
- Frame rate: 30 FPS minimum maintained

## Debugging

Enable debug mode in config.json:

```json
{
  "debug": {
    "enable_logging": true,
    "log_level": "DEBUG",
    "enable_mock_responses": true
  }
}
```

Debug features:
- **Logging**: All generation requests and responses logged
- **Debug UI**: Manual content generation triggers
- **Metrics**: Success rate, latency, cache hit rate tracking
- **Mock responses**: Inject test responses for deterministic testing

## Troubleshooting

### AI generation is slow
- Enable caching in config
- Reduce quality_vs_speed setting
- Use local LLM instead of cloud
- Increase worker_threads count

### Generated content is inappropriate
- Check content_validator blacklist
- Enable stricter validation
- Use rule-based fallback only

### Game stutters during generation
- Reduce performance budgets
- Enable adaptive complexity
- Increase cache size
- Enable pre-generation

### AI service fails
- Check API keys in config
- Verify network connection
- Check service status
- System will automatically fall back to rule-based generation

## Contributing

Contributions are welcome! Please:
1. Read the specification documents in `.kiro/specs/ai-integrated-gameplay/`
2. Follow the existing code style
3. Add tests for new features (both unit and property tests)
4. Update documentation

## License

[Your License Here]

## Credits

Built with:
- Godot Engine
- Property-based testing principles
- EARS requirements methodology
- INCOSE quality standards

## Support

For issues, questions, or feature requests, please open an issue on GitHub.

---

**Note**: This is a comprehensive AI system that requires careful configuration and testing. Start with the example scene and gradually integrate into your game. The system is designed to gracefully degrade, so your game will always work even if AI services fail.
