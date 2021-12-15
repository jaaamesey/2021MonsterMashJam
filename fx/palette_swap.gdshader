// No recolor

shader_type canvas_item;


uniform vec4 original_0: hint_color;
uniform vec4 original_1: hint_color;
uniform vec4 original_2: hint_color;
uniform vec4 original_3: hint_color;
uniform vec4 original_4: hint_color;
uniform vec4 replace_0: hint_color;
uniform vec4 replace_1: hint_color;
uniform vec4 replace_2: hint_color;
uniform vec4 replace_3: hint_color;
uniform vec4 replace_4: hint_color;

uniform float precision = 0.1;

vec4 swap_color(vec4 color){
	if (distance(color, original_0) <= precision){
		return replace_0;
	}
	if (distance(color, original_1) <= precision){
		return replace_1;
	}
	if (distance(color, original_2) <= precision){
		return replace_2;
	}
	if (distance(color, original_3) <= precision){
		return replace_3;
	}
	if (distance(color, original_4) <= precision){
		return replace_4;
	}
	return color;
}


void fragment() {
	COLOR = swap_color(texture(TEXTURE, UV));
}
