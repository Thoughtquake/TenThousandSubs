shader_type canvas_item;
render_mode blend_mix;

void fragment()
{
	NORMAL = (texture(NORMAL_TEXTURE, UV + vec2(TIME * 0.15f, 0)).rgb - vec3(0.5, 0.5, 0.5)) * 0.02;
	COLOR = vec4(texture(SCREEN_TEXTURE, UV+ NORMAL.xy).rgb, 1);
}