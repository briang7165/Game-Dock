extends RefCounted
## Original score "Sable Channel Jig" and foley synthesized offline at boot.
## No samples, services, downloads, or copyrighted melodies.
static func frequency(midi: int) -> float:
	return 440.0 * pow(2.0, (midi - 69) / 12.0)

static func wave(samples: PackedFloat32Array, rate: int, looping: bool = false) -> AudioStreamWAV:
	var pcm := PackedByteArray()
	pcm.resize(samples.size() * 2)
	for i: int in range(samples.size()):
		pcm.encode_s16(i * 2, int(clampf(samples[i],-0.95,0.95) * 32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = pcm
	if looping:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = samples.size()
	return stream

static func music(config: BroadsideAudioConfig) -> AudioStreamWAV:
	var eighth: float = 30.0 / config.music_bpm
	var melody: Array[int] = [62,65,69,74,72,69, 67,69,65,64,62,57, 65,69,72,77,74,72, 67,64,60,64,67,69, 62,69,74,76,74,69, 67,71,74,79,76,74, 72,67,64,60,64,67, 69,65,64,62,57,62]
	var roots: Array[int] = [38,38,41,36,38,43,36,38]
	var count: int = int(eighth * 96 * config.sample_rate)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 174
	for i: int in range(count):
		var t: float = float(i) / config.sample_rate
		var step: int = int(t / eighth)
		var local: float = fmod(t,eighth)
		var phase: float = TAU * frequency(melody[step % 48]) * local
		var envelope: float = minf(local / 0.012,1.0) * pow(maxf(0.0,1.0-local/eighth),1.5)
		# Reed/concertina-like harmonics over a plucked octave bass.
		var lead: float = (sin(phase) + 0.25*sin(phase*2) + 0.12*sin(phase*3)) * envelope * 0.23
		var bass_time: float = fmod(t,eighth*3)
		var bass: float = sin(TAU*frequency(roots[(step/6) % 8])*bass_time) * minf(bass_time/0.01,1.0) * exp(-bass_time*6.0) * 0.24
		var drum: float = 0.0
		if step % 3 == 0:
			drum = sin(TAU*(65.0*local + 30.0*(1-exp(-local*25))/25.0)) * exp(-local*24) * 0.28
		elif step % 3 == 2:
			drum = rng.randf_range(-1,1) * exp(-local*65) * 0.11
		var seam: float = minf(1.0,minf(t,count/float(config.sample_rate)-t)/0.012)
		samples[i] = (lead+bass+drum) * seam
	return wave(samples,config.sample_rate,true)

static func effect(kind: String, rate: int) -> AudioStreamWAV:
	var durations: Dictionary = {"cannon":0.85,"wood":0.35,"rock":0.4,"splash":0.65,"sink":1.4,"select":0.12,"victory":1.3,"defeat":1.3,"ocean":6.0,"wake":3.0}
	var duration: float = durations.get(kind,0.3)
	var samples := PackedFloat32Array()
	samples.resize(int(duration*rate))
	var rng := RandomNumberGenerator.new()
	rng.seed = 7919 + kind.hash()
	var low_noise: float = 0.0
	for i: int in range(samples.size()):
		var t: float = float(i)/rate
		var noise: float = rng.randf_range(-1,1)
		low_noise = lerpf(low_noise,noise,0.075)
		var value: float = 0.0
		match kind:
			"cannon": value = sin(TAU*(48*t+1.2*(1-exp(-t*30))))*exp(-t*7)*0.65 + low_noise*exp(-t*5)*1.2 + noise*exp(-t*70)*0.25
			"wood": value = (sin(t*TAU*170)*0.35+sin(t*TAU*281)*0.2+noise*0.5)*exp(-t*18)
			"rock": value = (sin(t*TAU*870)*0.24+sin(t*TAU*1327)*0.15+noise*0.3)*exp(-t*16)
			"splash": value = (low_noise*2.2+noise*0.18)*sin(PI*t/duration)*exp(-t*3)
			"sink": value = low_noise*(1-t/duration)*1.5+sin(TAU*(90*t-20*t*t))*exp(-t*3)*0.25
			"select": value = sin(TAU*660*t)*exp(-t*38)*0.35
			"victory", "defeat":
				var notes := PackedInt32Array([62,65,69,74] if kind == "victory" else [62,60,57,50])
				var note: int = mini(3,int(t/0.25))
				var local: float = fmod(t,0.25) if note < 3 else t-0.75
				value = sin(TAU*frequency(notes[note])*local)*minf(local/0.01,1.0)*exp(-local*8)*0.4
			"ocean": value = low_noise*(0.5+0.18*sin(TAU*t/duration))*1.4
			"wake": value = (low_noise*1.5+noise*0.06)*(0.6+0.2*sin(TAU*t/duration*3))
		var fade: float = minf(1.0,minf(t,duration-t)/0.015)
		samples[i] = value * fade
	return wave(samples,rate,kind in ["ocean","wake"])
