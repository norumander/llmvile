extends GutTest

const NpcConfig := preload("res://scripts/npc_config.gd")

func test_valid_tres_loads_all_fields():
	var cfg: NpcConfig = load("res://test/fixtures/valid_npc.tres")
	assert_not_null(cfg)
	assert_eq(cfg.display_name, "Test NPC")
	assert_not_null(cfg.sprite)
	assert_eq(cfg.desk_position, Vector2i(2, 3))
	assert_not_null(cfg.panel_scene)
	assert_eq(cfg.kind, &"stub")

func test_invalid_tres_without_panel_is_detected_by_helper():
	var cfg: NpcConfig = load("res://test/fixtures/invalid_npc_no_panel.tres")
	assert_false(cfg.is_valid(), "missing panel_scene must fail validation")

func test_default_kind_is_stub():
	var cfg := NpcConfig.new()
	assert_eq(cfg.kind, &"stub")

func test_npc_status_enum_values():
	# Enum identity — guards accidental reordering
	assert_eq(NpcStatus.Status.IDLE, 0)
	assert_eq(NpcStatus.Status.BUSY, 1)
	assert_eq(NpcStatus.Status.NOTIFY, 2)
