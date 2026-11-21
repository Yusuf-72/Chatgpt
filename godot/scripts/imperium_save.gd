extends Node
class_name ImperiumSave

const SAVE_PATH := "user://imperium_save.json"
var campaign := {
	"date": "1444-11-10",
	"realm": "Osmanlı İmparatorluğu",
	"ruler": "II. Murad",
	"treasury": 1200,
	"stability": 75,
	"army": 2500,
	"trade_income": 0,
	"trade_agreements": 0,
	"alliances": 0,
	"treaties": {},
	"relations": {"Bizans İmparatorluğu": 0, "Osmanlı İmparatorluğu": 0, "Macar Krallığı": 0, "Memlük Sultanlığı": 0, "Fransa Krallığı": 0, "İngiltere Krallığı": 0, "Timurlu İmparatorluğu": 0, "Ming Hanedanı": 0},
	"dynasty_continuation": true,
	"succession_resolved": false,
	"ended": false,
	"tax_collected": {}
}

func save_campaign() -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Kayıt dosyası açılamadı.")
		return false
	file.store_string(JSON.stringify(campaign, "\t"))
	return true

func load_campaign() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Kayıt dosyası bozuk.")
		return false
	var defaults := {
		"date": "1444-11-10", "realm": "Osmanlı İmparatorluğu", "realm_id": "ottoman", "ruler": "II. Murad", "ruler_id": "murad_ii",
		"treasury": 1200, "stability": 75, "army": 2500, "trade_income": 0, "trade_agreements": 0, "alliances": 0, "treaties": {},
		"relations": {"Bizans İmparatorluğu": 0, "Osmanlı İmparatorluğu": 0, "Macar Krallığı": 0, "Memlük Sultanlığı": 0, "Fransa Krallığı": 0, "İngiltere Krallığı": 0, "Timurlu İmparatorluğu": 0, "Ming Hanedanı": 0},
		"dynasty_continuation": true, "succession_resolved": false, "ended": false, "tax_collected": {}, "buildings": {"market": 0, "farm": 0, "barracks": 0}, "war_target_realm": "", "war_target_name": "", "province_owners": {}
	}
	for key in defaults:
		if not parsed.has(key):
			parsed[key] = defaults[key]
	if not parsed.has("ruler_id"):
		var ruler_ids := {"II. Murad": "murad_ii", "II. Mehmed": "mehmed_ii", "II. Bayezid": "bayezid_ii", "XI. Konstantinos": "constantine_xi", "Hunyadi Yanoş": "john_hunyadi"}
		parsed["ruler_id"] = str(ruler_ids.get(str(parsed.get("ruler", "II. Murad")), ""))
	if not parsed.has("realm_id"):
		parsed["realm_id"] = "ottoman"
	campaign = parsed
	return true
