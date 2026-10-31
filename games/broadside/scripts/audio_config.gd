class_name BroadsideAudioConfig
extends Resource
@export var sample_rate: int = 22050
@export var music_bpm: float = 124.0
@export var combat_music_db: float = -8.0
@export var menu_music_db: float = -19.0
@export var ambience_db: float = -26.0
@export var transition_seconds: float = 0.8
@export var effect_gains: Dictionary = {"cannon": -5.0, "wood": -8.0, "rock": -11.0, "splash": -13.0, "sink": -7.0, "select": -17.0, "victory": -10.0, "defeat": -10.0}
