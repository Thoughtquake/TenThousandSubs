shader_type canvas_item;
render_mode blend_mul;
uniform float speed;
uniform float stretch;

void fragment()
{
	COLOR = texture(TEXTURE, vec2(UV.x * stretch + TIME * speed, UV.y));
}