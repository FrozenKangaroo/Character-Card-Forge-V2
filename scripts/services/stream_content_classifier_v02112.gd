class_name CCFStreamContentClassifierV02112
extends RefCounted

# Provider-neutral classifier for ordinary streamed content. Dedicated reasoning
# fields are removed by the SSE decoder; this class conservatively handles only a
# leading tagged reasoning frame before the final answer begins.

const STATE_UNKNOWN := 0
const STATE_THINKING := 1
const STATE_FINAL := 2
const OPEN_TAGS := {
	"<think>": "</think>",
	"<reasoning>": "</reasoning>",
	"<analysis>": "</analysis>"
}

var _state := STATE_UNKNOWN
var _pending := ""
var _closing_tag := ""
var _reasoning_detected := false
var _final_started := false


func reset() -> void:
	_state = STATE_UNKNOWN
	_pending = ""
	_closing_tag = ""
	_reasoning_detected = false
	_final_started = false


func feed_content(delta: String) -> Dictionary:
	var result := _empty_result()
	if delta.is_empty():
		return result
	if _state == STATE_FINAL:
		(result["final_deltas"] as Array).append(delta)
		return result
	_pending += delta
	_classify_pending(result)
	return result


func finish() -> Dictionary:
	var result := _empty_result()
	if _state == STATE_UNKNOWN and not _pending.is_empty():
		# If no reasoning frame was ever established, preserve ambiguous literal
		# text exactly. After a reasoning frame, an unfinished second opening tag is
		# discarded rather than risking private reasoning exposure.
		if not _reasoning_detected:
			_state = STATE_FINAL
			_final_started = true
			result["final_started"] = true
			(result["final_deltas"] as Array).append(_pending)
		_pending = ""
	return result


func reasoning_detected() -> bool:
	return _reasoning_detected


func final_started() -> bool:
	return _final_started


func _classify_pending(result: Dictionary) -> void:
	while not _pending.is_empty() and _state != STATE_FINAL:
		if _state == STATE_THINKING:
			var lowered_thinking := _pending.to_lower()
			var closing_index := lowered_thinking.find(_closing_tag)
			if closing_index < 0:
				# Reasoning text is intentionally not retained. Keep only enough tail
				# to recognize a closing tag split across future chunks.
				var tail_size := mini(_pending.length(), maxi(0, _closing_tag.length() - 1))
				_pending = _pending.right(tail_size)
				return
			_pending = _pending.substr(closing_index + _closing_tag.length())
			_closing_tag = ""
			_state = STATE_UNKNOWN
			continue

		var leading_count := _leading_whitespace_count(_pending)
		var candidate := _pending.substr(leading_count)
		if candidate.is_empty():
			return
		var lowered_candidate := candidate.to_lower()
		var matched_open := ""
		var could_be_split_open := false
		for open_tag_value in OPEN_TAGS.keys():
			var open_tag := str(open_tag_value)
			if lowered_candidate.begins_with(open_tag):
				matched_open = open_tag
				break
			if open_tag.begins_with(lowered_candidate):
				could_be_split_open = true
		if not matched_open.is_empty():
			_reasoning_detected = true
			result["reasoning_started"] = true
			result["reasoning_detected"] = true
			result["reasoning_transport"] = "tagged_content"
			_closing_tag = str(OPEN_TAGS.get(matched_open, ""))
			_pending = candidate.substr(matched_open.length())
			_state = STATE_THINKING
			continue
		if could_be_split_open:
			return

		_state = STATE_FINAL
		_final_started = true
		result["final_started"] = true
		(result["final_deltas"] as Array).append(_pending)
		_pending = ""


func _empty_result() -> Dictionary:
	return {
		"final_deltas": [],
		"reasoning_started": false,
		"reasoning_detected": _reasoning_detected,
		"reasoning_transport": "tagged_content" if _reasoning_detected else "",
		"final_started": false
	}


func _leading_whitespace_count(value: String) -> int:
	var count := 0
	while count < value.length() and value.substr(count, 1) in [" ", "\t", "\r", "\n"]:
		count += 1
	return count
