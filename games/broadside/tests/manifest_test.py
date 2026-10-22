"""Validate the actual Game Dock JSON Schema (requires jsonschema)."""
import json
from pathlib import Path
from jsonschema import Draft202012Validator

repo = Path(__file__).resolve().parents[3]
schema = json.loads((repo / "specs/game-manifest.schema.json").read_text())
manifest = json.loads((repo / "games/broadside/packaging/game.json").read_text())
Draft202012Validator.check_schema(schema)
Draft202012Validator(schema).validate(manifest)
assert manifest["id"] == "broadside"
assert manifest["executable"] == "Broadside.exe"
print("PASS: manifest validates against Game Dock schema and package identity")
