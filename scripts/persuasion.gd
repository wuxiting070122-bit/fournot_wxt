extends RefCounted
## Deterministic excerpt matching. Narrative guilt and persuasion remain separate.

const Sentences = preload("res://scripts/sentence_selection.gd")
const CAPS = [20, 20, 30]
const CLAIMS = [
	"阿野害死了全家，就该先投他。你替他开脱，是想把大家引到谁身上？",
	"那个律师不是我。我没做过那些事，是你带着林梢一起指认我！",
	"我没安排送钱，更没收买法官。是你在引导大家害死我，你才是罪人！"
]
const TITLES = ["01 / 不确定的死因", "02 / 匿名材料中的人", "03 / 职业之外的行为"]
var evidence: Array = []
var round_index := 0
var resistance := 100
var round_damage := [0, 0, 0]
var accepted: Dictionary = {}
var errors := [0,0,0]
var concept_best: Dictionary = {}

func _init() -> void:
	evidence = JSON.parse_string(FileAccess.get_file_as_string("res://data/evidence.json"))

func matching(source: String, quote: String) -> Array:
	var result: Array = []
	for item in evidence:
		if item.source == source and quote.contains(item.quote):
			result.append(item)
	return result

func submit(source: String, quote: String) -> Dictionary:
	if quote.strip_edges().is_empty() or quote.length() > 180 or Sentences.spans(quote).size() != 1:
		errors[round_index] += 1
		return {"damage":0, "message":"每次请提交一句完整原文（最多 180 字），保留否定词和上下文。"}
	var hits := matching(source, quote)
	var relevant: Array = hits.filter(func(item): return int(item.round) == round_index)
	if relevant.is_empty():
		errors[round_index] += 1
		return {"damage":0, "message":"这段话还不能回应当前质疑。检查它能证明什么，并保留完整句意。"}
	var damage := 0
	var doubled := false
	var new_claim := false
	for item in relevant:
		if accepted.has(item.id):
			continue
		accepted[item.id] = true
		new_claim = true
		var chars := 0
		for keyword in item.keywords:
			chars += str(keyword).length()
		var base := 2 * mini(chars, 8)
		var amount := base * (2 if item.direct else 1)
		var key := "%d:%s" % [round_index, item.concept]
		var previous := int(concept_best.get(key, 0))
		concept_best[key] = maxi(previous, amount)
		var remaining := int(CAPS[round_index]) - int(round_damage[round_index])
		var actual := mini(maxi(0, amount - previous), remaining)
		round_damage[round_index] += actual
		damage += actual
		doubled = doubled or bool(item.direct)
	resistance -= damage
	if not new_claim:
		errors[round_index] += 1
		return {"damage":0, "message":"这一信息已经引用过了；同一论点不能重复说服。"}
	errors[round_index] = 0
	var message := "直接反驳 ×2" if doubled else "有效补证"
	message += " · 抵触 −%d" % damage
	if damage == 0:
		message = "证据关系已补全。本轮抵触值已达到可降低的上限。"
	if not gate_complete():
		message += "\n" + missing_hint()
	return {"damage":damage, "message":message, "direct":doubled}

func gate_complete() -> bool:
	match round_index:
		0: return has_any(["A1", "A2", "A3", "A7"])
		1: return has_any(["B1", "B2", "B3"]) and accepted.has("B5")
		2: return accepted.has("C3") and has_any(["C4", "C5"])
	return false

func has_any(ids: Array) -> bool:
	for id in ids:
		if accepted.has(id): return true
	return false

func missing_hint() -> String:
	match round_index:
		0: return "仍需要说明：死因或纵火者尚不能确定。"
		1: return "将案卷中的律师信息，与林梢的当面指认联系起来。"
		2: return "需要同时说明：谁安排了付款，以及钱与法官的关系。"
	return ""

func advance() -> bool:
	if not gate_complete() or round_index >= 2:
		return false
	round_index += 1
	return true

func won() -> bool:
	return round_index == 2 and gate_complete() and resistance < 40

func painter_hint() -> String:
	var general := [
		"先查火灾报纸里三名受害者的死因和起火调查，不能凭处分记录就说阿野害死了全家。",
		"要把讯问笔录附页里的律师经历，与会议记录中林梢的指认对上。",
		"他说没安排送钱。我得在关联核查页找到付款指令，再看资金去向或法官的供述。"
	]
	var detailed := [
		"火灾报纸第一段写着警方尚未公布具体死因，也未就起火原因作出结论。勾画这一整句，再提交。",
		"先在律师材料附页勾画职业或代理工地案件的句子，再去会议记录勾画林梢说“他是我父亲请的律师”的整句，两处都要提交。",
		"在律师材料的关联核查页，提交“给X顾问公司的咨询费”那条付款指令，再提交款项转入法官账户或法官承认收钱的整句。"
	]
	return "画家（心想）：" + (detailed[round_index] if int(errors[round_index]) >= 3 else general[round_index])

func skip_round_for_evaluation() -> void:
	for item in evidence:
		if int(item.round) == round_index: accepted[item.id] = true
	resistance = maxi(0,resistance-(int(CAPS[round_index])-int(round_damage[round_index])))
	round_damage[round_index] = CAPS[round_index]
	errors[round_index] = 0
	if round_index == 2: resistance = mini(resistance,39)
