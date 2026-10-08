extends RefCounted

# Offsets refer to original text, never wrapped display lines.
static func spans(text: String) -> Array:
	var result: Array = []
	var start := 0
	var i := 0
	while i < text.length():
		if text[i] in ["。", "！", "？", "!", "?", "\n"]:
			var end := i + 1
			while end < text.length() and text[end] in ["”", "’", "」", "』", "！", "？", "!", "?"]:
				end += 1
			append_span(result, text, start, end)
			start = end
			i = end
		else:
			i += 1
	append_span(result, text, start, text.length())
	return result

static func append_span(result: Array, text: String, start: int, end: int) -> void:
	while start < end and text[start].strip_edges().is_empty(): start += 1
	while end > start and text[end - 1].strip_edges().is_empty(): end -= 1
	if end > start: result.append({"start": start, "end": end, "text": text.substr(start, end - start)})

static func resolve(text: String, start: int, end: int) -> Dictionary:
	while start < end and text[start].strip_edges().is_empty(): start += 1
	while end > start and text[end - 1].strip_edges().is_empty(): end -= 1
	if start >= end: return {"error": "先在原文中拖选一句话内的文字。"}
	var found: Array = []
	for sentence in spans(text):
		if start < sentence.end and end > sentence.start: found.append(sentence)
	if found.size() != 1: return {"error": "每次只能勾画一句话，请不要跨句选择。"}
	if found[0].text.length() > 180: return {"error": "这句话超过 180 字，暂不能收录。"}
	return found[0]

static func offset(text: String, line: int, column: int) -> int:
	var lines := text.split("\n")
	var total := column
	for i in range(line): total += lines[i].length() + 1
	return total

static func coordinates(text: String, offset_value: int) -> Vector2i:
	var before := text.left(offset_value)
	return Vector2i(before.count("\n"), before.length() - before.rfind("\n") - 1)
