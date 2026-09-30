shader_type spatial;
render_mode cull_disabled, depth_draw_never, diffuse_burley;

uniform sampler2D flame_texture : source_color, filter_linear_mipmap, repeat_disable;
uniform float opacity = 0.9;
uniform float flow_speed = 3.2;
uniform float emission_strength = 0.45;
uniform bool billboard = false;
uniform float sprite_angle = 0.0;
uniform vec4 flame_colour : source_color = vec4(1.0);
varying float phase;

void vertex() {
    phase = INSTANCE_CUSTOM.x * 6.283185;
    float bend = sin(TIME * flow_speed + VERTEX.y * 3.0 + phase);
    VERTEX.x += bend * 0.025 * abs(VERTEX.y);
    if (billboard) {
        float c = cos(sprite_angle), s = sin(sprite_angle);
        VERTEX.xy = mat2(vec2(c,s),vec2(-s,c)) * VERTEX.xy;
        vec3 scale = vec3(length(MODEL_MATRIX[0].xyz),length(MODEL_MATRIX[1].xyz),length(MODEL_MATRIX[2].xyz));
        MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0]*scale.x,INV_VIEW_MATRIX[1]*scale.y,INV_VIEW_MATRIX[2]*scale.z,MODEL_MATRIX[3]);
    }
}

void fragment() {
    vec4 painted = texture(flame_texture, UV);
    ALBEDO = mix(painted.rgb, painted.rgb * flame_colour.rgb, 0.2);
    EMISSION = painted.rgb * emission_strength;
    ROUGHNESS = 0.75;
    SPECULAR = 0.0;
    ALPHA = painted.a * opacity;
}
