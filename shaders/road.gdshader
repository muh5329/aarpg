shader_type spatial;
uniform sampler2D road_color : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D earth_color : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D road_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D earth_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec2 center;
uniform vec2 half_size;
varying vec3 world;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.-2.*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;}
void fragment(){
 vec2 edge=half_size-abs(world.xz-center);
 float distance_to_edge=min(edge.x,edge.y);
 float mask=smoothstep(.03,.75,distance_to_edge-noise(world.xz*4.)*.48);
 ALBEDO=mix(texture(earth_color,world.xz*.22).rgb,texture(road_color,world.xz*.26).rgb,mask);
 NORMAL_MAP=mix(texture(earth_normal,world.xz*.22).rgb,texture(road_normal,world.xz*.26).rgb,mask);
 NORMAL_MAP_DEPTH=.75;
 ROUGHNESS=.92;
}
