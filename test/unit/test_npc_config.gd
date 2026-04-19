extends GutTest

const NpcConfig := preload("res://scripts/npc_config.gd")

func test_valid_tres_loads_all_fields():
	var cfg: NpcConfig = load("res://test/fixtures/valid_npc.tres")
	assert_not_null(cfg)
	assert_eq(cfg.display_name, "Test NPC")
	assert_not_null(cfg.sprite_frames)

func test_default_new_instance_is_invalid():
	var cfg := NpcConfig.new()
	assert_false(cfg.is_valid(), "empty config must fail validation")

func test_missing_sprite_frames_fails_validation():
	var cfg := NpcConfig.new()
	cfg.display_name = "T"
	assert_false(cfg.is_valid())

func test_missing_display_name_fails_validation():
	var cfg := NpcConfig.new()
	cfg.sprite_frames = preload("res://test/fixtures/test_sprite_frames.tres")
	assert_false(cfg.is_valid())

func test_npc_status_enum_values():
	assert_eq(NpcStatus.Status.IDLE, 0)
	assert_eq(NpcStatus.Status.BUSY, 1)
	assert_eq(NpcStatus.Status.NOTIFY, 2)
