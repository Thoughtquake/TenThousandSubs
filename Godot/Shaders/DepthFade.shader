shader_type canvas_item;
render_mode blend_mix;
uniform sampler2D gradient_tex;
varying float depth;

void vertex()
{
	depth = INSTANCE_CUSTOM.r;
}

void fragment()
{
	vec4 sub_color = texture(TEXTURE, UV);
	vec3 bg_color = texture(gradient_tex, SCREEN_UV).rgb;
	float fade = depth * 0.9f;
	COLOR = vec4(fade * bg_color + (1.0f - fade) * sub_color.rgb, sub_color.a);
}