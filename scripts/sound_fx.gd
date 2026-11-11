extends Node

const SAMPLE_RATE := 22050


func play(effect: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var settings := _settings_for(effect)
	if settings.is_empty():
		return
	var player := AudioStreamPlayer.new()
	player.stream = _make_tone(float(settings["start"]), float(settings["end"]), float(settings["duration"]), float(settings["volume"]))
	player.bus = "Master"
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func _settings_for(effect: String) -> Dictionary:
	match effect:
		"jump":
			return {"start": 420.0, "end": 690.0, "duration": 0.13, "volume": 0.25}
		"collect":
			return {"start": 740.0, "end": 1080.0, "duration": 0.2, "volume": 0.3}
		"hurt":
			return {"start": 210.0, "end": 95.0, "duration": 0.28, "volume": 0.38}
		"win":
			return {"start": 520.0, "end": 1040.0, "duration": 0.55, "volume": 0.34}
		"fail":
			return {"start": 440.0, "end": 130.0, "duration": 0.52, "volume": 0.34}
	return {}


func _make_tone(start_frequency: float, end_frequency: float, duration: float, volume: float) -> AudioStreamWAV:
	var sample_count := int(SAMPLE_RATE * duration)
	var samples := PackedByteArray()
	samples.resize(sample_count * 2)
	var phase := 0.0
	for i in range(sample_count):
		var progress := float(i) / float(sample_count)
		var frequency := lerpf(start_frequency, end_frequency, progress)
		var envelope := pow(1.0 - progress, 1.6)
		var fundamental := sin(phase)
		var overtone := sin(phase * 2.01) * 0.16
		phase += TAU * frequency / SAMPLE_RATE
		var sample_value := clampf((fundamental + overtone) * envelope * volume, -1.0, 1.0)
		samples.encode_s16(i * 2, roundi(sample_value * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = samples
	return stream
