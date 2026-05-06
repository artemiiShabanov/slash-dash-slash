shader_type canvas_item;

// Global CRT post-process.
//
// Layered onto the topmost CanvasLayer (see scripts/crt_overlay.gd). Samples
// the back-buffer through a barrel-curved UV, applies chromatic aberration,
// phosphor tint, scanlines, vignette, and signal noise. All parameters driven
// by resources/crt_tuning.tres.
//
// Outside the curved region the shader writes black, producing a bezel-like
// border at the screen edges.

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform vec4 tint_color : source_color = vec4(0.92, 0.95, 1.0, 1.0);
uniform float curvature : hint_range(0.0, 0.05) = 0.018;
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.18;
uniform float chromatic_aberration : hint_range(0.0, 0.01) = 0.002;
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.15;
uniform float noise_intensity : hint_range(0.0, 0.3) = 0.03;
uniform bool noise_animated = true;

const float INTERNAL_HEIGHT = 360.0;

// Cheap hash-based noise; deterministic per-pixel.
float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

// Barrel distortion around screen center.
vec2 curve_uv(vec2 uv, float k) {
	vec2 cc = uv - 0.5;
	float dist = dot(cc, cc);
	cc *= 1.0 + dist * k * 4.0;
	return cc + 0.5;
}

void fragment() {
	vec2 uv = curve_uv(SCREEN_UV, curvature);

	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		// Bezel: outside the curved region, draw black.
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	} else {
		// Chromatic aberration: R/B sampled at slight horizontal offsets.
		float r = texture(screen_texture, uv + vec2(chromatic_aberration, 0.0)).r;
		float g = texture(screen_texture, uv).g;
		float b = texture(screen_texture, uv - vec2(chromatic_aberration, 0.0)).b;
		vec3 col = vec3(r, g, b);

		// Phosphor tint (multiplicative).
		col *= tint_color.rgb;

		// Scanlines: alternating row darkening, aligned to the internal 360px height.
		float scan = sin(uv.y * INTERNAL_HEIGHT * PI) * 0.5 + 0.5;
		col *= 1.0 - scanline_intensity * scan;

		// Signal noise.
		float t = noise_animated ? TIME : 0.0;
		float n = hash(SCREEN_UV * vec2(640.0, 360.0) + t);
		col += (n - 0.5) * noise_intensity;

		// Vignette: darken with squared radial distance.
		vec2 d = SCREEN_UV - vec2(0.5);
		float v = 1.0 - dot(d, d) * 4.0 * vignette_intensity;
		v = clamp(v, 0.0, 1.0);
		col *= v;

		COLOR = vec4(col, 1.0);
	}
}
