---
name: obscura
description: Synthetic data generation platform for ML training — photorealistic images/videos with pixel-perfect annotations via declarative scene specification.
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [synthetic-data, computer-vision, ml-training, data-augmentation, simulation, privacy]
    related_skills: [cognee, sandcastle]
---

# Obscura AI — Synthetic Data Generation

Use Obscura to generate high-quality, photorealistic synthetic images and videos with precise scene control and automatic annotation generation. Ideal for augmenting limited datasets, privacy-preserving demonstrations, and scenario simulation before real-world execution.

## When to Use

Trigger when the user:
- Needs synthetic training data for ML/CV models due to data scarcity or privacy constraints
- Wants to simulate specific scenarios (autonomous driving, retail environments, security footage)
- Requires pixel-perfect annotations (bounding boxes, segmentation masks, depth maps, optical flow) alongside generated data
- Needs domain randomization to improve model robustness
- Wants to rapidly prototype visual scenarios from natural language descriptions
- Aims to create privacy-safe demonstrations without exposing real PII

## Prerequisites

- Obtain an Obscura API key from [obscura.ai](https://www.obscura.ai)
- Install the Python SDK: `pip install obscura`
- Set environment variable: `OBSCURA_API_KEY=your_key`
- Optional: `obscura-cli` for command-line usage

## Quick Reference

```python
from obscura import Scene, Client, DatasetDefinition
import random

# Initialize client
client = Client(api_key=os.getenv("OBSCURA_API_KEY"))

# Single scene generation
scene = Scene()
scene.add_object("car", position=(0, 0, 10), rotation=(0, 45, 0))
scene.set_camera(position=(0, 5, -10), target=(0, 0, 10))
scene.set_lighting(sun_angle=30, sky_type="clear")

job = client.generate(scene, resolution=(1920, 1080))
output = job.wait()
output.save("output.png")
output.annotations.save("labels.json")

# Dataset with domain randomization
def random_scene():
    scene = Scene()
    scene.set_weather(random.choice(["rain", "fog", "clear"]))
    scene.set_time_of_day(random.choice(["dawn", "noon", "dusk"]))
    # ... add randomized objects
    return scene

dataset = DatasetDefinition.from_function(random_scene, count=10000)
client.generate_dataset(dataset, output_dir="./synthetic_data")
```

CLI equivalent:
```bash
obscura generate scene.json --output ./data
```

## Data Types & Capabilities

| Feature | Details |
|---------|---------|
| Output formats | PNG, JPEG, MP4, raw frames |
| Resolution | Up to 4K (configurable) |
| Annotations | BBox, segmentation, depth, optical flow, normals |
| Randomization | Lighting, weather, textures, object placement, camera angles |
| Determinism | Seeded generation for reproducibility |
| Scalability | Async job queue, parallel GPU workers |

## Steps — Integrating with Hermes Agent

### 1. Setup & Configuration
- Store `OBSCURA_API_KEY` in Hermes environment (e.g., `~/.hermes/.env`)
- Install `obscura` package in Hermes's Python environment
- Create a thin wrapper module under `~/.hermes/tools/obscura_tool.py`

### 2. Scene Definition Strategy
When users describe a scenario in natural language:
- Translate NL description → scene parameters (objects, positions, lighting, camera)
- Use composition: build scenes from reusable templates (e.g., "city_street", "retail_shelf", "warehouse_aisle")
- Apply appropriate randomization ranges based on use case

### 3. Dataset Generation Workflow
For ML training augmentation:
```python
hermes_obscura.augment_dataset(
    user_images: List[Path],
    user_labels: List[dict],
    multiplier: int = 5,
    variations: ["lighting", "background", "occlusion"]
)
```
- Infer scene parameters from existing user data
- Generate synthetic variants
- Merge with real data, preserving labeling consistency

### 4. Scenario Simulation & Testing
Before executing real-world actions (robotics, CV inspection):
- Generate a suite of test scenarios covering edge cases
- Run Hermes's planning logic in simulation
- Identify potential failure modes before deployment

### 5. Privacy-Preserving Demonstrations
For user demos requiring realistic structure but no real data:
- Clone the composition of a real environment (object counts, layout)
- Replace textures/objects with synthetic equivalents
- Maintain geometric/functional accuracy without PII exposure

### 6. Continuous Learning Pipeline
- Schedule periodic dataset regeneration to reflect emerging patterns
- Cache commonly generated scenes to reduce API costs
- Blend synthetic + real data in retraining loops

## Pitfalls

- **Cost management**: Synthetic generation at scale (10k+ images) can incur significant cloud costs. Monitor usage, implement caching, and batch requests appropriately.
- **Domain gap**: Even high-quality synthetic data may not perfectly match real-world distributions. Always validate with a small real test set; consider using domain adaptation techniques.
- **API rate limits**: Obscura's API may have rate limits; implement exponential backoff and/or job queuing for large dataset requests.
- **Reproducibility**: Always set a seed when you need identical outputs across runs. Without seeding, each generation is non-deterministic (by design, for diversity).
- **Annotation fidelity**: While annotations are pixel-perfect for the synthetic scene, they may not perfectly align if the synthetic distribution diverges from real data. Validate annotation quality before training.
- **Asset licensing**: The asset library includes pre-made 3D models. Ensure compliance with Obscura's terms when using specific branded or third-party assets commercially.
- **Network dependency**: Requires stable internet connection for API communication. Consider local caching of downloaded assets and generated datasets.

## References

- GitHub: https://github.com/obscura-ai/obscura
- Documentation: https://docs.obscura.ai
- Examples: `examples/` directory in the repository (autonomous driving, retail, aerial imagery)
