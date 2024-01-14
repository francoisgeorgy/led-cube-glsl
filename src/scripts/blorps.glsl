// Adapted from https://github.com/polyfloyd/cube-shaders/tree/master/anim

#pragma use "../lib/libcube-2chains.glsl"
#pragma use "../lib/libcolor.glsl"
#pragma map prev=builtin:Back Buffer
#pragma map noise=builtin:RGBA Noise Small
#pragma map gyros=perip_mat4:/dev/ttyUSB0;230400?

void mainCube(out vec4 fragColor, in vec3 fragCoord) {
	float t = iTime * .8 + 10;
	fragColor.rgb = vec3(0);

	vec3 accum = vec3(0);
	for (int i = 0; i < 32; i++) {
		float rx = t * length(texture2D(noise, vec2(i / 64., 0.0)));
		float ry = t * length(texture2D(noise, vec2(i / 64., 0.1)));
		float rz = t * length(texture2D(noise, vec2(i / 64., 0.2)));
		mat3 mx = mat3(
			1.0, 0.0,      0.0,
			0.0, cos(rx),  sin(rx),
			0.0, -sin(rx), cos(rx)
		);
		mat3 my = mat3(
			cos(ry),  0.0, sin(ry),
			0.0,      1.0, 0.0,
			-sin(ry), 0.0, cos(ry)
		);
		mat3 mz = mat3(
			cos(rz),  sin(rz), 0.0,
			-sin(rz), cos(rz), 0.0,
			0.0,      0.0,     1.0
		);

		mat3 rotation = mx * my * mz * mat3(gyros);
		vec3 p = normalize(fragCoord * rotation);

		vec3 color = hsvToRGB(vec3(i / 32., 1, 1));
		vec3 anchor = vec3(1, 0, 0);
		accum += color * clamp(1 - length(anchor - p) * 4, 0, 1);
		accum += vec3(1) * clamp(1 - length(anchor - p) * 12, 0, 1);
	}

	// Using the back buffer breaks the emulator, but the effect on the cube is
	// pretty cool.
	vec3 p = texture2D(prev, gl_FragCoord.xy / iResolution.xy).rgb;
	fragColor.rgb = max(p - .02, accum);
}

#ifndef _EMULATOR
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
	mainCube(fragColor, cube_map_to_3d(fragCoord));
}
#endif
