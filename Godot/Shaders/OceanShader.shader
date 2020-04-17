shader_type canvas_item;
render_mode blend_mix;

void fragment()
{
	NORMAL = (texture(NORMAL_TEXTURE, UV + vec2(TIME * 0.03f, 0)).rgb - vec3(0.5, 0.5, 0.5)) * 0.2;
	COLOR = texture(TEXTURE, UV + NORMAL.xy);
}